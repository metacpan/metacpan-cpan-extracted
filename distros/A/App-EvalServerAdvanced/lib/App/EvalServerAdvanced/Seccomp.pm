package App::EvalServerAdvanced::Seccomp;
our $VERSION = '0.023';

use strict;
use warnings;

use v5.20;

use Data::Dumper;
use List::Util qw/reduce uniq/;
use Moo;
#use Linux::Clone;
#use POSIX ();
use Linux::Seccomp;
use Carp qw/croak/;
use Module::Runtime qw/check_module_name require_module module_notional_filename/;
use App::EvalServerAdvanced::Config;
use App::EvalServerAdvanced::ConstantCalc;
use App::EvalServerAdvanced::Seccomp::Profile;
use App::EvalServerAdvanced::Seccomp::Syscall;
use Function::Parameters;
use YAML::XS (); # no imports
use Path::Tiny;

has exec_map => (is => 'ro', default => sub {+{}});
has profiles => (is => 'ro', default => sub {+{}});
has constants => (is => 'ro', default => sub {App::EvalServerAdvanced::ConstantCalc->new()});

has _rules => (is => 'rw');

has _permutes => (is => 'ro', default => sub {+{}});
has _plugins => (is => 'ro', default => sub {+{}});
has _fullpermutes => (is => 'ro', lazy => 1, builder => 'calculate_permutations');
has _used_sets => (is => 'rw', default => sub {+{}});

has _rendered_profiles => (is => 'ro', default => sub {+{}});

has _finalized => (is => 'rw', default => 0); # TODO make this set once

# Define some more open modes that POSIX doesn't have for us.
my ($O_DIRECTORY, $O_CLOEXEC, $O_NOCTTY, $O_NOFOLLOW) = (00200000, 02000000, 00000400, 00400000);

method load_yaml($yaml_file) {

  # TODO sanitize file name via Path::Tiny, ensure it's either in the module location, or next to the sandbox config

  my $input = do {no warnings 'io'; local $/; open(my $fh, "<", $yaml_file) or die "Couldn't load seccomp YAML $yaml_file: $!"; <$fh>};
  my $data = do {
    local $YAML::XS::LoadBlessed = 0;
    local $YAML::XS::UseCode = 0;
    local $YAML::XS::LoadCode = 0;
    YAML::XS::Load($input);
  };

  if (my $consts = $data->{constants}) {
    for my $const_plugin (($consts->{plugins}//[])->@*) {
      $self->load_plugin("Constants::$const_plugin");
    }

    for my $const_key (keys (($consts->{values}//{})->%*)) {
      $self->constants->add_constant($const_key, $consts->{values}{$const_key})
    }
  }


  for my $profile_key (keys $data->{profiles}->%* ) {
    my $profile_data = $data->{profiles}->{$profile_key};

    my $profile_obj = App::EvalServerAdvanced::Seccomp::Profile->new(%$profile_data);

    $profile_obj->load_permutes($self);
    $self->profiles->{$profile_key} = $profile_obj;
  }

  #print Dumper($data);
}

sub get_profile_rules {
  my ($self, $next_profile, $current_profile) = @_;

  if ($self->_used_sets->{$next_profile}) {
    #warn "Circular reference between $current_profile => $next_profile";
    return (); # short circuit the loop
  }

  $self->_used_sets->{$next_profile} = 1;
  die "No profile found [$next_profile]" unless $self->profiles->{$next_profile};
  return $self->profiles->{$next_profile}->get_rules($self);
}

method build_seccomp() {
  croak "build_seccomp called more than once" if ($self->_finalized);
  $self->_finalized(1);

  for my $profile_key (keys $self->profiles->%*) {
    my $profile_obj = $self->profiles->{$profile_key};

    $self->_used_sets({});
    my @rules = $profile_obj->to_seccomp($self);
    $self->_rendered_profiles->{$profile_key} = \@rules;
  }
}

sub calculate_permutations {
  my ($self) = @_;
  # TODO this is possible to implement with bitwise checks in seccomp, producing fewer rules.  it should be faster, but is more annoying to implement currently

  my %full_permute;

  for my $permute (keys %{$self->_permutes}) {
    my @modes = @{$self->_permutes->{$permute}} = sort {$a <=> $b} uniq @{$self->_permutes->{$permute}};

    # Produce every bitpattern for this permutation
    for my $bit (1..(2**@modes) - 1) {
      my $q = 1;
      my $mode = 0;
      #printf "%04b: ", $b;
      do {
        if ($q & $bit) {
          my $r = int(log($q)/log(2)+0.5); # get the position

          $mode |= $modes[$r];

          #print "$r";
        }
        $q <<= 1;
      } while ($q <= $bit);

      push $full_permute{$permute}->@*, $mode;
    }
  }

  # This originally sorted the values, why? it shouldn't matter.  must have been for easier sanity checking?
  for my $k (keys %full_permute) {
    $full_permute{$k}->@* = uniq $full_permute{$k}->@*
  }

  return \%full_permute;
}

method apply_seccomp($profile_name) {
  # TODO LOAD the rules

  my $seccomp = Linux::Seccomp->new(SCMP_ACT_KILL);

  for my $rule ($self->_rendered_profiles->{$profile_name}->@* ) {
      # TODO make this support raw syscall numbers?
      my $syscall = $rule->{syscall};
      # If it looks like it's not a raw number, try to resolve.
      $syscall = Linux::Seccomp::syscall_resolve_name($syscall) if ($syscall =~ /\D/);
      my @rules = ($rule->{rules}//[])->@*;

      my %actions = (
        ALLOW => SCMP_ACT_ALLOW,
        KILL  => SCMP_ACT_KILL,
        TRAP  => SCMP_ACT_TRAP,
      );

      my $action = $actions{$rule->{action}//""} // SCMP_ACT_ALLOW;

       if ($rule->{action} && $rule->{action} =~ /^\s*ERRNO\((-?\d+)\)\s*$/ ) { # send errno() to the process
         # TODO, support constants? keys from %! maybe? Errno module?
         $action = SCMP_ACT_ERRNO($1 // -1);
       } elsif ($rule->{action} && $rule->{action} =~ /^\s*TRACE\((-?\d+)?\)\s*$/) { # hit ptrace with msgnum
         $action = SCMP_ACT_TRACE($1 // 0);
       }

  #    printf "%s => [%s]\n", $rule->{syscall}, join("", map {sprintf "\n    $_->[0] $_->[1] $_->[2]"} @rules);
      $seccomp->rule_add($action, $syscall, @rules);
  }

  $seccomp->load;
}

method engage($profile_name) {
  $self->build_seccomp();
  $self->apply_seccomp($profile_name);
}

sub load_plugin {
  my ($self, $plugin_name) = @_;

  return $self->_plugins->{$plugin_name} if (exists $self->_plugins->{$plugin_name});

  check_module_name($plugin_name);

  if ($plugin_name !~ /^App::EvalServerAdvanced::Seccomp::Plugin::/) {
    my $plugin;
    if (config->sandbox->plugin_base) { # if we have a plugin base configured, use it first.
      my $plugin_filename = module_notional_filename($plugin_name);
      my $path = path(config->sandbox->plugin_base); # get the only path we'll load short stuff from by it's short name, otherwise deleting a file or a typo could load something we don't want

      my $full_path = $path->child($plugin_filename);

      $plugin = $plugin_name if (eval {require $full_path}); # TODO check if it was a failure to find, or a failure to compile.  failure to compile should still be fatal.
  }

    unless ($plugin) {
      # we couldnt' load it from the plugin base, try from @INC with a fully qualified name
      my $fullname = "App::EvalServerAdvanced::Seccomp::Plugin::$plugin_name";
      $plugin = $fullname if (eval {require_module($fullname)});
      # TODO log errors from module loading
    }

    die "Failed to find plugin $plugin_name" unless $plugin;

    $self->_plugins->{$plugin_name} = $plugin;
    $plugin->init_plugin($self);
    return $plugin;
  } else {
    if (eval {require_module($plugin_name)}) {
      $self->_plugins->{$plugin_name} = $plugin_name;
      $plugin_name->init_plugin($self);
      return $plugin_name;
    }

    die "Failed to find plugin $plugin_name";
  }
}

sub BUILD {
  my ($self) = @_;

#  if (config->sandbox->seccomp->plugins) {
#    for my $plugin_name (config->sandbox->seccomp->plugins->@*) {
#      $self->load_plugin($plugin_name);
#    }
#  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EvalServerAdvanced::Seccomp - Use of Seccomp to create a safe execution environment


=head1 DESCRIPTION

This is a rule generator for setting up Linux::Seccomp rules.  It's used internally only, and it's API is not given any consideration for backwards compatibility.  It is however useful to look at the source directly.

=head1 YAML

The yaml config file for seccomp contains two main sections, C<profiles> and C<constants>

=head2 CONSTANTS

    constants:
      plugins:
        - 'POSIX'
        - 'LinuxClone'
      values:
        TCGETS: 0x5401
        FIOCLEX: 0x5451
        FIONBIO: 0x5421
        TIOCGPTN: 0x80045430

This section is fairly simple with two sections of it's own C<plugins> and C<values>

=over

=item values

Just a key value list of various names for constant values to be used later.  This lets you define anything not already coming from a plugin, and avoid undocumented magic numbers in your rules.  Ideally you should make sure that these come from the proper header files or documentation so that any architecture change doesn't cause the values to change.

Valid ways to represent the values are as follows:

=over

=item hex

Standard perl syntax 0x0123456789_ABCDEF.  Case insensitive, underscores allowed for readability.

=item binary

Standard perl syntax for binary values 0b1111_0000, case insensitive, underscores allowed for readability.

=item octal

Standard perl syntax, and YAML allowed syntax for octal values. 0777 and 0o777 are both valid.  underscores allowed for readability.

=item decimal integers

Normal base ten integers.  1234567890, cannot begin with a 0.  underscores allowed for readability.

=back

=item plugins

Right now there's only two plugins provided with the distrobution, L<App::EvalServerAdvanced::Seccomp::Plugin::Constants::POSIX> and L<App::EvalServerAdvanced::Seccomp::Plugin::Constants::LinuxClone>.  These two plugins pull constants from the L<POSIX> and L<Linux::Clone> modules respectively.  This way things like O_EXCL and CLONE_NEWNS should always be correct for the platform you run on regardless of the kernel version.  That said, they're unlikely to ever change anyway.

Plugins can be loaded by a short name as demonstrated above.  It will first attempt to load them from the configured plugin base in the App::EvalServerAdvanced configuration file.  If it finds it by the short name there (e.g. - 'MyPlugin' will become MyPlugin.pm) then all is fine.  If it's not found then it will try to load it from @INC under the fully qualified namespace C<App::EvalServerAdvanced::Seccomp::Plugin::Constants::$SHORTNAME>.  You can also specify the full name of the module under the namespace and it will only load it from @INC.

=back

=head2 profiles

    profiles:
      default:
        include:
          - time_calls
          - file_readonly
          - stdio
          - exec_wrapper
          - file_write
          - file_tty
          - file_opendir
          - file_temp
        rules:
    # Memory related calls
          - syscall: mmap
          - syscall: munmap
          - syscall: mremap
          - syscall: mprotect
          - syscall: madvise
          - syscall: brk

Profiles are the most important part of setting up seccomp.  They are a whitelist of what programs in the sandbox are allowed to do.  Anything not specified results in the termination of the process.  A profile consists of a name, child profiles, and a set of rules to follow.

=over

=item Profile name

Name for the profile.  Any valid string can be used for the name.  C<default> is expected to exist, but if all languages in the config specify a profile then you can avoid having one named C<default>.  They are case sensitive, no other restrictions apply.

=item includes

A list of profiles that should be included into this one at runtime.  This is useful for organizing rules into basic actions and letting you compose them into a logical groups to handle programs.

=item rules

This is a list of the syscalls to be allowed.  See the L</Rule definitions> section for details.

=item rule_generator

Use a plugin to generate the rules at runtime.  Use a string such as C<"ExecWrapper::gen_exec_wrapper">.  It will then load the plugin C<ExecWrapper> and call the method C<gen_exec_wrapper> on it.  It will be passed the C<App::EvalServerAdvanced::Seccomp> object and be expected to return a set of rules to be used.  Best to see the source code of L<App::EvalServerAdvanced::Seccomp::Plugin::ExecWrapper> to see just how this works currently.

This is useful for handling some edge cases with Seccomp.  Since Seccomp can't dereference pointers you can't actually handle system calls that contain them fully effectively.  But what you can do is limit the specific pointers that are allowed to be passed to the system calls instead.  In the C<ExecWrapper> plugin this gets used to setup rules for the C<execve> syscall to be allowed to be called with strings from the C<config> singleton object inside the server.  This lets you C<exec(...)> only to specific interpreters/binaries with very little security impact after the C<execve> call happens.  It does mean that you can put a new string at those addresses and run C<execve> again but with ASLR doing so is almost impossible as long as the C<seccomp> syscall is not allowed to be used to get the existing eBPF program for examination.

=item permute

    file_write:
      include:
       - 'file_open'
      permute:
        open_modes:
          - 'O_CREAT'
          - 'O_WRONLY'
          - 'O_TRUNC'
          - 'O_RDWR'
    file_open:
      rules:
        - syscall: open
          tests:
            - [1, '==', '{{open_modes}}']

This gets used to specify flags for a syscall to use.  In the example above for the C<file_write> profile, it says that the flags O_CREAT, O_WRONLY, O_TRUNC and O_RDWR should be allowed for the permutation named C<open_modes>.  In the C<file_open> profile, we define a syscall that C<open> that can take any combination of the flags from C<open_modes> by specifying the value with C<'{{open_modes}}'>.  See L</Rule definitions> for more information.


=back

=head1 Rule definitions

    file_open:
      rules:
        - syscall: open
          tests:
            - [1, '==', '{{open_modes}}']
        - syscall: openat
          tests:
            - [2, '==', '{{open_modes}}']
        - syscall: close

Rules consist of a few attributes that specify what you're allowed to do.

=over

=item syscall

The most important part of a rule, without it you will end up with a fatal error.  Best practice is to specify the syscall by name, i.e. C<open> or C<openat>.  It will be resolved at runtime using the syscall map of the system automatically, so that you don't have to know the number of the syscalls.  If however there's a syscall that doesn't want to resolve for you, you can specify it by number, but this is not recommended as it will be architecture dependant and cause problems if you change architectures (i.e. from x86_64 to i386).

=item action

=item tests

This is probably the least elegant part of the config file, but I couldn't come up with a better setup/syntax for it.  This is a list of tests, all of which must pass, for the given syscall.

Each test is an array of three things, [argument, operator, value].

=over

=item argument

Which argument to the syscall you want to test.  Starting from 0 being the first argument.

=item operator

What operator to use for the test: == != >= <= < > or =~

The =~ operator takes the C<argument> to the syscall and uses the C<value> as a bit mask.  It passes if all the bits from the mask are set in the argument, ignoring any not present in the mask.

=item value

This is the value you want to test for.  It can be either a literal integer value or it can be a string containing a set of constants and bitwise operations.  It uses L<App::EvalServerAdvanced::ConstantCalc> to do the math and you should look at that for the exact operations supported.

Some examples

    'O_CLOEXEC|O_EXCL|O_RDWR'

Also supported are using automatically permutated values by using a string like '{{ open_modes }}'.  In this case all possible values will be pre-generated and substituted into the rule to allow any valid set of flags in a syscall

=back

=back

=head1 SECURITY

This is an excercise in defense in depths.  The default rulesets
provide a bit of protection against accidentally running knowingly dangerous syscalls.

This does not provide absolute security.  It relies on the fact that the syscalls allowed
are likely to be safe, or commonly required for normal programs to function properly.

In particular there are two syscalls that are allowed that are involved in the Dirty COW
kernel exploit.  C<madvise> and C<mmap>, with these two you can actually trigger the Dirty COW
exploit.  But because the default rules restrict you from creating threads, you can't create the race
condition needed to actually accomplish it.  So you should still take some
other measures to protect yourself.

=head1 KNOWN ISSUES

=over

=item Compilation errors when loading plugins from the plugin base directory will result in it attempting to load the fully qualified module name.  This will be fixed in future versions to be a fatal error

=back

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=cut
