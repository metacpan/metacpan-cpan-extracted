package CLI::Simple;
# a Simple, Fast & Easy way to create scripts

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars :log-levels);
use CLI::Simple::Utils qw(normalize_options slurp dmp choose);
use CLI::Simple::DumpSpec qw(_cmd_dump_spec);
use CLI::Simple::Migrate qw(_cmd_migrate);
use CLI::Simple::Scaffold qw(_cmd_scaffold);
use CLI::Simple::Helpers qw(_is_class_name);
use CLI::Simple::Shell;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use FindBin qw($RealBin $RealScript);
use File::Basename qw(basename);
use File::Which qw(which);
use Getopt::Long qw(:config no_ignore_case);
use List::Util qw(zip none pairs any);
use Log::Log4perl qw();
use Pod::Usage;
use Scalar::Util qw(reftype);

our $VERSION = '2.0.10';

our $GETOPT_EXIT_ON_ERROR = $TRUE;
our $GETOPT_STATUS;
our $GETOPT_ERROR_MESSAGE;

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    _command
    _command_args
    _commands
    _program
    _abbreviations
  )
);

our $USE_LOGGER   = $FALSE;
our $AUTO_DEFAULT = $FALSE;
our $AUTO_HELP    = $FALSE;
our $PAGER        = $TRUE;

our %INTERNAL_COMMANDS = (
  '-generate-completion' => \&_cmd_generate_completion,
  '-migrate'             => \&_cmd_migrate,
  '-dump-spec'           => \&_cmd_dump_spec,
  '-scaffold'            => \&_cmd_scaffold,
);

our @EXPORT_OK = qw($AUTO_HELP $AUTO_DEFAULT $PAGER);

use parent qw(Exporter Class::Accessor::Fast);

# CLI::Simple 2.0.0 additions

our $MANIFEST;  # package-level, per-consumer class

caller or __PACKAGE__->main();

########################################################################
sub import {
########################################################################
  my ( $class, @args ) = @_;

  if ( any { $_ eq ':roles' } @args ) {
    my $caller = caller;

    if ( !${^COMPILING} ) {
      ( my $dist = $caller ) =~ s/::/-/gxsm;
      my $yaml_file = lc($dist) . '.yml';

      require File::ShareDir;
      my $path = eval { File::ShareDir::dist_file( $dist, $yaml_file ) };
      undef $path if $path && !-e $path;

      $class->_load_manifest( $caller, $path ) if $path;
    }
  }

  # preserve existing Exporter behaviour
  $class->export_to_level( 1, $class, grep { $_ ne ':roles' && !/[.]ya?ml\z/xsm } @args );

  return;
}

########################################################################
sub _load_manifest {
########################################################################
  my ( $class, $target, $yaml_file ) = @_;

  require YAML::Tiny;

  my $manifest = YAML::Tiny::LoadFile($yaml_file)
    or die "ERROR: could not load manifest: $yaml_file\n";

  if ( my $commands = $manifest->{commands} ) {

    # derive unique roles from command values
    my %seen;
    my @roles = grep { !$seen{$_}++ && _is_class_name($_) } values %{$commands};

    require Role::Tiny;
    Role::Tiny->apply_roles_to_package( $target, @roles );

    # build dispatch table: 'code-review' => \&cmd_code_review
    my %dispatch;
    for my $cmd ( keys %{$commands} ) {
      my $value = $commands->{$cmd};

      my $method = choose {
        return $value
          if !_is_class_name($value);

        # derive method from command key, not role class name
        # create-config -> cmd_create_config
        # install       -> cmd_install
        ( my $m = "cmd_$cmd" ) =~ s/-/_/gxsm;
        return $m;
      };

      die sprintf "ERROR: %s does not implement %s\n", $value, $method
        if !$target->can($method);

      $dispatch{$cmd} = $target->can($method);
    }

    $manifest->{_dispatch} = \%dispatch;
  }

  # store on the target class
  no strict 'refs'; ## no critic
  ${"${target}::_CLI_MANIFEST"} = $manifest;

  return;
}

########################################################################
sub _manifest {
########################################################################
  my ($class) = @_;

  no strict 'refs'; ## no critic
  return ${"${class}::_CLI_MANIFEST"};
}

########################################################################
sub main {
########################################################################
  my ($class) = @_;

  my $manifest = $class->_manifest;

  my $cli = $class->new(
    option_specs    => $manifest ? ( $manifest->{options} // [] )           : [],
    default_options => $manifest ? ( $manifest->{default_options} // {} )   : {},
    extra_options   => $manifest ? ( $manifest->{extra_options} // [] )     : [],
    commands        => $manifest ? $manifest->{_dispatch}                   : { default => \&usage },
    abbreviations   => $manifest ? ( $manifest->{abbreviations} // $FALSE ) : $FALSE,
  );

  return $cli->run;
}

########################################################################
sub _use_logger {
########################################################################
  return $USE_LOGGER;
}

########################################################################
sub use_log4perl {
########################################################################
  my ( $self, %args ) = @_;

  my $class = ref $self || $self;

  my ( $log_level, $level, $log4perl_conf ) = @args{qw(log_level level config)};
  $level //= $log_level;

  {
    no strict 'refs'; ## no critic (ProhibitNoStrict)

    $USE_LOGGER = $TRUE;

    *{"${class}::get_log4perl_conf"}  = sub { return $log4perl_conf };
    *{"${class}::set_log4perl_conf"}  = sub { $log4perl_conf = $_[1] };
    *{"${class}::get_log4perl_level"} = sub { return $level };
  }

  if ( !$self->can('set_logger') ) {
    $self->mk_accessors('logger');
  }

  if ( !$self->can('set_log_level') ) {
    $self->mk_accessors('log_level');
  }

  return $self;
}

########################################################################
sub new {
########################################################################
  my ( $class, @params ) = @_;

  my %args = ref $params[0] ? %{ $params[0] } : @params;

  my ( $default_options, $option_specs, $commands, $extra_options, $abbreviations, $error_handler, $alias )
    = @args{qw(default_options option_specs commands extra_options abbreviations error_handler alias)};

  no strict 'refs'; ## no critic

  my $stash = \%{ $class . $DOUBLE_COLON };

  local *alias = *alias; ## no critic ProhibitLocalVars

  use vars qw($DEFAULT_OPTIONS $EXTRA_OPTIONS $OPTION_SPECS $COMMANDS $LOGGING);

  *DEFAULT_OPTIONS = $stash->{DEFAULT_OPTIONS} // $EMPTY;
  *EXTRA_OPTIONS   = $stash->{EXTRA_OPTIONS}   // $EMPTY;
  *OPTION_SPECS    = $stash->{OPTION_SPECS}    // $EMPTY;
  *COMMANDS        = $stash->{COMMANDS}        // $EMPTY;

  $default_options //= $DEFAULT_OPTIONS;
  $extra_options   //= $EXTRA_OPTIONS;
  $option_specs    //= $OPTION_SPECS;
  $commands        //= $COMMANDS;

  $option_specs //= [];

  croak sprintf "ERROR: 'commands' is required\nusage: %s->new( option_specs => specs, commands => commands);\n", __PACKAGE__
    if !$option_specs || !$commands;

  $default_options //= {};

  my $options = { %{$default_options} };

  if ( $class->_use_logger && none { $_ eq 'log-level' } @{$option_specs} ) {
    push @{$option_specs}, 'log-level=s';
  }

  # if we have an option alias, make sure the option alias spec is set too
  if ( $alias && ref $alias && $alias->{options} ) {
    foreach my $p ( pairs %{ $alias->{options} } ) {
      my ( $aka, $name ) = @{$p};

      # Does an option named $aka already exist (with or without a spec)?
      my $aka_exists = any {/^\Q$aka\E(?:[^\w-].*)?$/xsm} @{$option_specs};

      if ( !$aka_exists ) {

        # Find the canonical spec for $name
        my ($spec) = grep {/^\Q$name\E(?:[^\w-].*)?$/xsm} @{$option_specs};
        croak sprintf 'ERROR: no such option defined: %s', $name if !$spec;

        # Pull just the specifier part (e.g., '=s', ':i', '!', '+', etc.)
        my ($spec_part) = $spec =~ /^\Q$name\E(?:[|].)?([^\w-].*)?$/xsm;

        $spec_part ||= q{};

        push @{$option_specs}, $aka . $spec_part;
      }
    }
  }

  if ( @ARGV && $ARGV[0] =~ /^-[[:alpha:]]/xsm ) {
    if ( my $handler = $INTERNAL_COMMANDS{ $ARGV[0] } ) {
      exit $handler->( $class, $commands, $option_specs );
    }
  }

  $GETOPT_STATUS = sub {
    local $SIG{__WARN__} = sub { $GETOPT_ERROR_MESSAGE = shift; return; };

    return GetOptions( $options, @{$option_specs} );
    }
    ->();

  normalize_options($options);

  my %cli_options;

  my @accessors
    = ( @{ $extra_options || [] }, map { ( split /[^\w\-]/xsm )[0] } @{$option_specs} );

  foreach (@accessors) {
    s/\-/_/xsmg;

    if ( !$class->can( 'get_' . $_ ) ) {
      $class->mk_accessors($_);
    }

    $cli_options{$_} = $options->{$_};
  }

  if ( !$error_handler && !$GETOPT_STATUS ) {
    print {*STDERR} $GETOPT_ERROR_MESSAGE;
    if ($GETOPT_EXIT_ON_ERROR) {
      _leave($FAILURE);
    }
  }
  elsif ( !$GETOPT_STATUS ) {
    if ( !$error_handler->($GETOPT_ERROR_MESSAGE) ) {
      _leave($FAILURE);
    }
  }

  croak "ERROR: alias must be a hash ref with keys 'options' or 'commands'\n"
    if $alias && !ref $alias;

  if ($alias) {
    if ( $alias->{options} ) {
      foreach my $p ( pairs %{ $alias->{options} } ) {
        my ( $aka, $name ) = @{$p};
        $aka  =~ s/[-]/_/gxsm;
        $name =~ s/[-]/_/gxsm;

        if ( defined $cli_options{$name} ) {
          $cli_options{$aka} = $cli_options{$name};
        }
        elsif ( defined $cli_options{$aka} ) {
          $cli_options{$name} = $cli_options{$aka};
        }
      }
    }

    # command aliases are a convenience so someone doesn't have to add
    # to $commands manually
    if ( $alias->{commands} ) {
      foreach my $p ( pairs %{ $alias->{commands} } ) {
        croak sprintf "ERROR: no command: %s\n"
          if !$commands->{ $p->[1] };

        $commands->{ $p->[0] } = $commands->{ $p->[1] };
      }
    }
  }

  my $self = $class->SUPER::new( \%cli_options );

  if ( !$self->can('get_help_sections') ) {
    $self->mk_accessors('help_sections');
    $self->set_help_sections( [qw( SYNOPSIS DESCRIPTION/Commands DESCRIPTION/Options OPTIONS USAGE )] );
  }

  # AUTO_DEFAULT uses the only command as the default
  if ( $AUTO_DEFAULT && scalar keys %{$commands} == 1 ) {
    my ($command) = keys %{$commands};

    if ( @ARGV && $ARGV[0] ne $command ) {
      unshift @ARGV, $command;
    }
    elsif ( !@ARGV ) {
      unshift @ARGV, $command;
    }
  }

  my $command = shift @ARGV // $EMPTY;

  if ( !$command ) {
    if ( $commands->{default} ) {
      $command = 'default';
    }
    elsif ($AUTO_HELP) {
      $command = 'help';
    }
  }

  $self->set__command($command);

  $self->set__command_args( [@ARGV] );

  $self->set__commands($commands);

  if ( $command eq 'help' || ( $self->can('get_help') && $self->get_help ) ) {
    # custom help function?

    my $help = $commands->{help};

    if ( !$help ) {
      $self->usage;
    }

    if ( ref $help && reftype($help) eq 'ARRAY' ) {
      $help->[0]->($self);
    }
    else {
      $help->($self);
    }
  }

  $self->set__abbreviations( $abbreviations // $FALSE );

  $self->set__program("$RealBin/$RealScript");

  $self->validate_command;

  $self->init_logger;

  $self->can('init') && $self->init();

  return $self;
}

########################################################################
sub _leave {
########################################################################
  my (@args) = @_;

  my ($exit_code) = ref $args[0] ? $args[1] : $args[0];

  exit $exit_code;
}

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  if ( $self->_use_logger ) {

    if ( my $config = $self->get_log4perl_conf ) {
      Log::Log4perl->init( ref $config ? $config : \$config );
    }
    else {
      Log::Log4perl->import(':easy');
      Log::Log4perl->easy_init( $LOG_LEVELS{error} );
    }

    my $logger = Log::Log4perl->get_logger(q{});

    $self->set_logger($logger);

    my $level = $self->get_log_level // $self->get_log4perl_level;

    $self->set_log_level($level);

    if ($level) {
      $logger->level( $LOG_LEVELS{$level} );
    }
  }

  my $commands = $self->commands;
  my $command  = $self->command;

  return $self
    if !$commands->{$command} || reftype( $commands->{$command} ) ne 'ARRAY';

  my ( $sub, $log_level ) = @{ $commands->{$command} };

  return $self
    if !$self->get_logger;

  $log_level = $self->get_log_level // $log_level;

  $self->get_logger->level( $LOG_LEVELS{$log_level} // $LOG_LEVELS{info} );

  return $self;
}

########################################################################
sub get_kv_args {
########################################################################
  my ($self) = @_;

  my @arg_list = @{ $self->get__command_args };

  my %args;

  foreach (@arg_list) {
    my ( $k, $v ) = split /=/xsm;
    $args{$k} = $v;
  }

  return %args;
}

########################################################################
sub get_args {
########################################################################
  my ( $self, @vars ) = @_;

  my $command_args = $self->get__command_args;

  return wantarray ? @{$command_args} : @{$command_args}
    if !@vars;

  @vars = map { $_ ? $_ : '<undef>' } @vars;

  my %args = map { @{$_} } zip \@vars, [ @{$command_args}[ 0 .. $#vars ] ];

  delete $args{'<undef>'};

  return wantarray ? %args : \%args;
}

########################################################################
sub default_command {
########################################################################
  goto &usage;
}

########################################################################
sub usage {
########################################################################
  my ($self) = @_;

  my $wrapper = $ENV{MODULINO_WRAPPER} // q{};

  my $input = $wrapper eq 'cli-simple' ? $INC{'CLI/Simple/Shell.pm'} : $self->get__program;

  if ($PAGER) {
    eval {
      require IO::Pager;
      IO::Pager->new(*STDOUT);
    };
  }

  pod2usage(
    -noperldoc => 1,
    -exitval   => 'NOEXIT',
    -input     => $input,
    -verbose   => 99,
    -sections  => $self->get_help_sections,
  );

  return _leave($FAILURE);
}

########################################################################
sub example {
########################################################################
  require File::ShareDir;

  print {*STDOUT} slurp File::ShareDir::dist_file( 'CLI-Simple', 'MyScript.pm' );

  return 0;
}

########################################################################
sub command {
########################################################################
  my ( $self, $command ) = @_;

  if ($command) {
    $self->set__command($command);
  }

  return $self->get__command;
}

########################################################################
sub commands {
########################################################################
  my ( $self, $command, $handler ) = @_;

  my $commands = $self->get__commands;

  if ( $command && $handler ) {

    croak "ERROR: usage: commands([command, subref])\n"
      if reftype($handler) ne 'CODE';

    $commands->{$command} = $handler;
  }

  return $commands;
}

########################################################################
sub program {
########################################################################
  my ($self) = @_;

  return $self->get__program;
}

########################################################################
sub validate_command {
########################################################################
  my ($self) = @_;

  my $command = $self->command;

  return
    if !$command;

  my $commands = $self->commands;

  return $command
    if defined $commands->{$command};

  croak sprintf "Unknown command: %s\n", $command
    if !$self->get__abbreviations;

  my $abbreviation = $command;

  my @matches = grep {/^$abbreviation/xsm} keys %{$commands};

  croak sprintf "Unknown command: %s\n", $command
    if !@matches;

  if ( @matches == 1 ) {
    $command = $matches[0];  # Unique match - accept
    $self->set__command($command);
    return $command;
  }

  croak sprintf "Ambiguous command '$abbreviation'; could match: %s\n", join q{,}, @matches;
}

########################################################################
sub _cmd_generate_completion {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  no strict 'refs'; ## no critic
  my $stash = \%{ $class . '::' };

  my $cmd_list = join q{ }, sort grep { !/^-/xsm } keys %{$commands};

  my $program = $ENV{MODULINO_WRAPPER} // do {
    ( my $name = $class ) =~ s/::/-/gxsm;
    lc $name;
  };

  my @flags;
  my @value_opts;

  for my $spec ( @{$option_specs} ) {
    my ($name) = $spec =~ /\A([\w-]+)/xsm;
    $name =~ s/_/-/gxsm;

    if ( $spec =~ /[=:]/xsm ) {
      push @value_opts, "--$name";
    }
    else {
      push @flags, "--$name";
    }
  }

  my $flags      = join q{ }, sort @flags;
  my $value_opts = join q{ }, sort @value_opts;

  printf {*STDOUT} <<'END_COMPLETION', $program, $cmd_list, $value_opts, $flags, $program, $program;
_%s() {
  local cur prev words cword
  _init_completion || return

  local commands="%s"
  local value_opts="%s"
  local flags="%s"

  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == --* ]]; then
      COMPREPLY=( $(compgen -W "$flags $value_opts" -- "$cur") )
    else
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    fi
    return
  fi

  case $prev in
    $value_opts)
      COMPREPLY=( $(compgen -f -- "$cur") )
      return ;;
  esac

  COMPREPLY=( $(compgen -W "$flags $value_opts" -- "$cur") )
}

complete -F _%s %s
END_COMPLETION

  return $SUCCESS;
}

########################################################################
sub run {
########################################################################
  my ($self) = @_;

  my $command = $self->command;

  ######################################################################
  # a blank command means that we did not have a default && AUTO_HELP
  # is off scripter has deliberately decided to allow running of
  # init() phase w/o a run phase
  ######################################################################

  return $SUCCESS
    if !$command;

  my $commands = $self->commands;

  my $program = $self->program;

  my $handler = $commands->{$command};

  return $handler->($self)
    if ref $handler ne 'ARRAY';

  my ( $sub, $log_level ) = @{$handler};

  croak "ERROR: invalid specification for $command\n"
    if !ref $sub || reftype($sub) ne 'CODE';

  return $sub->($self);
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple - a minimalist object oriented base class for CLI applications

=head1 SYNOPSIS

 #!/usr/bin/env perl

 package MyScript;

 use strict;
 use warnings;

 use CLI::Simple::Constants qw(:booleans :chars);
 use CLI::Simple qw($AUTO_HELP $AUTO_DEFAULT);

 use parent qw(CLI::Simple);

 caller or __PACKAGE__->main();

 sub execute {
   my ($self) = @_;

   # retrieve a CLI option   
   my $file = $self->get_file;
   ...
 }

 sub list { 
   my ($self) = @_

   # retrieve a command argument
   my ($file) = $self->get_args();
   ...
 }

 sub main {

   # Disable auto-default for single commands, enable auto-help
   $AUTO_DEFAULT = 0;
   $AUTO_HELP = 1;

   my $cli = MyScript->new(
    option_specs    => [ qw( help format=s file=s) ],
    default_options => { format => 'json' }, # set some defaults
    extra_options   => [ qw( content ) ], # non-option, setter/getter
    commands        => { execute => \&execute, list => \&list,  }
    alias           => { options => { fmt => 'format' }, commands => { ls => 'list' } },
   );

   return $cli->run();
 }

 1;

# role-based CLI Application (2.0.0)

# create a YAML manifest C<my-script.yml> in your project root:

  ---
  commands:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

# create a main module

  package My::Script;

  use CLI::Simple qw(:roles);
  use parent qw(CLI::Simple);

  our $VERSION = '1.0.0';

  caller or exit __PACKAGE__->main;

  1;

# create implementation roles

  package My::Script::Role::Frobnicate;

  use Role::Tiny;
  use CLI::Simple::Constants qw(:booleans);

  sub cmd_frobnicate {
    my ($self) = @_;
    ...
    return $SUCCESS;
  }

  1;

=head1 DESCRIPTION

=begin markdown

[![CLI-Simple](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml/badge.svg)](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml)

=end markdown

Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script that
takes options and commands?  C<CLI::Simple> makes it easy to create
scripts that take I<options>, I<commands> and I<arguments>.

C<CLI::Simple> is designed around the I<modulino> pattern - Perl
modules that can be executed directly as scripts. See L</MODULINOS>.

For common constant values (like C<$TRUE>, C<$DASH>, or C<$SUCCESS>), see
L<CLI::Simple::Constants>, which pairs naturally with this module.

Version 2.0.0 introduces optional role-based architecture for applications
that have outgrown a single module. Declare your commands and options in a
YAML manifest, implement each command in a dedicated L<Role::Tiny> role, and
C<CLI::Simple> handles composition, dispatch, and lifecycle automatically.
Your main module shrinks to a single line:

  caller or exit __PACKAGE__->main;

Not ready for a full refactor? Start smaller. The built-in C<-dump-spec>
command introspects your existing module and writes a YAML manifest that
makes your configuration data-driven without moving a single line of
implementation code. Adopt roles incrementally, one command at a time.

When you are ready to scaffold a full role-based project, C<-scaffold>
generates role stubs, a slimmed main module, and inter-module dependencies
from your manifest. Feed the resulting tarball to
L<CPAN::Maker::Bootstrapper> and you have a complete, buildable CPAN
distribution in one step.

=head1 VERSION

This documentation refers to version 2.0.9.

=head1 FEATURES

=over 5

=item * accept command line arguments ala L<Getopt::Long>

=item * supports commands and command arguments

=item * automatically add a logger

=item * global or custom log levels per command

=item * easily add usage notes

=item * automatically create setter/getters for your script

=item * low dependency profile

=item * optional role-based architecture via YAML manifest

=item * built-in scaffolding tools for migrating legacy scripts to roles

=item * bash completion script generation for modulino wrappers

=item * optional pager support for help output via L<IO::Pager>

=item * customizable help sections via C<help_sections>

=back

=head1 MODULINOS

A I<modulino> is a Perl module that can also be run directly as a
script. The term was coined by Brian D. Foy and the pattern is simple:

  caller or __PACKAGE__->main();

When the file is C<require>d or C<use>d by another module, C<caller>
returns the calling package and the expression short-circuits -
C<main()> is never called. When the file is executed directly by Perl,
C<caller> returns false and C<main()> runs. The same file serves as
both a reusable module and an executable script.

C<CLI::Simple> is designed around this pattern. Every C<CLI::Simple>
application is expected to be a modulino. The framework's lifecycle,
internal commands, bash completion, and scaffolding tools all assume
this dual-use design.

=head2 Why Modulinos?

The modulino pattern offers several advantages over a traditional
script:

=over 4

=item * B<Testable> - your script logic lives in a proper Perl module
that can be C<use>d in test files without executing C<main()>

=item * B<Reusable> - other scripts and modules can C<use> your
modulino and call its methods directly

=item * B<Introspectable> - tools like C<-dump-spec> and
C<-generate-completion> can load your modulino and inspect its live
state without running it as a script

=item * B<Installable> - modulinos distribute cleanly as CPAN modules
with full man page support via L<CPAN::Maker::Bootstrapper>

=back

=head2 The Bash Wrapper

Perl modulinos are invoked via a thin bash wrapper script that locates
the installed module file and passes all arguments through to Perl:

  #!/usr/bin/env bash
  #-*- mode: sh; -*-

  MODULINO_WRAPPER=my-script
  MODULE_NAME=My::Script
  MODULE_PATH=$(MODULE_PATH="${MODULE_NAME//:://}.pm" \
    perl -M$MODULE_NAME -e 'print $INC{$ENV{MODULE_PATH}};')

  MODULINO_WRAPPER=$MODULINO_WRAPPER perl $MODULE_PATH "$@"

The wrapper locates the installed C<.pm> file via C<%INC> and sets
C<MODULINO_WRAPPER> in the environment so C<CLI::Simple> knows the
name of the script the user actually typed. This is used by
C<-generate-completion> to name the bash completion function correctly
and by L<CPAN::Maker::Bootstrapper> to create man page symlinks.

=head2 create-modulino

C<CLI::Simple> ships with a C<create-modulino> tool that generates the
bash wrapper for any C<CLI::Simple> modulino:

  # create wrapper using module name convention (My::Script -> my-script)
  create-modulino -m My::Script

  # install to a specific directory
  create-modulino -m My::Script -i /usr/local/bin

  # use a custom wrapper name
  create-modulino -m My::Script -a my-alias -i /usr/local/bin

C<create-modulino> is itself a modulino - an example of the pattern it
creates. The bash wrapper template lives in its C<__DATA__> section,
keeping the tool entirely self-contained.

If you are building a CPAN distribution, L<CPAN::Maker::Bootstrapper>
integrates C<create-modulino> into the C<make modulino> target,
generating and installing the wrapper as part of the build process.

=head2 MODULINO_WRAPPER

The C<MODULINO_WRAPPER> environment variable tells C<CLI::Simple> the
name of the wrapper script that invoked the modulino. It is set by the
wrapper and used by:

=over 4

=item * C<-generate-completion> - to name the bash completion function
and C<complete> target correctly

=item * Man page symlinks via L<CPAN::Maker::Bootstrapper> - so
C<man my-script> resolves to the module's man page

=back

If C<MODULINO_WRAPPER> is not set, C<CLI::Simple> infers the script
name from the module name by convention - C<My::Script> becomes
C<my-script>. Set it explicitly when the wrapper name does not follow
this convention.


=head1 QUICK START

=head2 Single-Module Application

The simplest way to use C<CLI::Simple> is to subclass it and define
your commands as methods in the same module:

  package My::Script;

  use strict;
  use warnings;

  use CLI::Simple::Constants qw(:booleans);

  use parent qw(CLI::Simple);

  caller or __PACKAGE__->main;

  sub cmd_frobnicate {
    my ($self) = @_;
    my $output = $self->get_output;
    ...
    return $SUCCESS;
  }

  sub main {
    __PACKAGE__->new(
      option_specs => [ qw( help|h verbose|v output|o=s ) ],
      commands     => { frobnicate => \&cmd_frobnicate },
    )->run;
  }

  1;

=head2 Role-Based Application

For larger applications, declare your commands and options in a YAML
manifest and implement each command in a dedicated L<Role::Tiny> role.
Your main module becomes a single declaration:

  package My::Script;

  use strict;
  use warnings;

  use CLI::Simple qw(:roles);
  use parent qw(CLI::Simple);

  our $VERSION = '1.0.0';

  caller or exit __PACKAGE__->main;

  1;

B<Naming convention:> The YAML manifest filename is derived from your
module name - C<My::Script> looks for C<my-script.yml> in the
distribution share directory. You must package the spec file with your
distribution.

The manifest maps commands to roles:

  ---
  commands:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

Each role implements one or more commands:

  package My::Script::Role::Frobnicate;

  use Role::Tiny;
  use CLI::Simple::Constants qw(:booleans);

  sub cmd_frobnicate {
    my ($self) = @_;
    ...
    return $SUCCESS;
  }

  1;

To scaffold role stubs from an existing modulino, run the built-in
C<-scaffold> command:

  my-script -scaffold

To scaffold from an existing manifest - including a new one written by hand
or generated by C<-dump-spec> - pass the spec file path:

  cli-simple -scaffold my-script.yml

Or let C<CLI::Simple> generate the manifest and scaffold from an
existing modulino in one step:

  my-script -migrate

See L</ROLE-BASED ARCHITECTURE> for the complete workflow including
the baby-step migration path.

=head1 ROLE-BASED ARCHITECTURE

C<CLI::Simple> 2.0.0 introduces an optional role-based architecture
for applications that have grown beyond a single module. Commands are
implemented in dedicated L<Role::Tiny> roles and declared in a YAML
manifest. C<CLI::Simple> composes the roles, builds the dispatch
table, and provides an inherited C<main()> - potentially reducing your
main module to a single declaration.

=head2 The YAML Manifest

The manifest is a YAML file that declares your commands, options, and
defaults. By convention the filename is derived from your module name:

  My::Script        ->  my-script.yml
  CPAN::Maker::Bootstrapper  ->  cpan-maker-bootstrapper.yml

C<CLI::Simple> locates the manifest via L<File::ShareDir> using the
distribution name derived from the module name. The manifest must be
installed as part of the distribution - it cannot be loaded from an
arbitrary location.

I<Security note: The manifest is loaded exclusively from the
distribution share directory via L<File::ShareDir>. A manifest that
was not installed as part of the distribution cannot be loaded. This
provides the same security model as Perl module loading itself.>

A minimal manifest:

  ---
  commands:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
  options:
    - help|h
    - verbose|v
    - output|o=s

A complete manifest with all supported keys:

  ---
  commands:
    frobnicate: My::Script::Role::Frobnicate
    list:       My::Script::Role::List
    default:    cmd_frobnicate
  options:
    - help|h
    - verbose|v
    - output|o=s
  default_options:
    verbose: 0
  extra_options:
    - dbh
    - config_data

=head2 Command Values

Each command in the manifest maps to either a role class name or a
sub name:

=over 4

=item * B<Role class name> (contains C<::>) - the role is composed
into your main module and the method C<cmd_I<command>> is resolved
from the role. C<code-review> resolves to C<cmd_code_review>.

=item * B<Sub name> - resolved directly via C<can()> on your class.
Use this for alias commands that point to an existing method:

  default: cmd_frobnicate

=back

=head2 Roles With No Commands

Some roles provide framework behavior rather than commands - for
example an C<init()> method for startup validation. Since these roles
have no command entry in the manifest they must be composed manually
in your main module:

  package My::Script;

  use CLI::Simple qw(:roles);
  use Role::Tiny::With;
  use parent qw(CLI::Simple);

  with 'My::Script::Role::Init';

  caller or exit __PACKAGE__->main;

  1;

I<Note: A future version of C<CLI::Simple> will support an
C<extra_roles> key in the manifest to handle this automatically.>

=head2 Activating Role-Based Architecture

Add C<:roles> to your C<use CLI::Simple> statement:

  use CLI::Simple qw(:roles);

This triggers manifest loading at compile time. The manifest is
located using the fallback chain described above. Roles are composed
into your class and the dispatch table is built before C<new()> is
called.

=head2 The Inherited main()

When using C<:roles>, your class inherits C<main()> from
C<CLI::Simple>. It reads the manifest, constructs the object with the
manifest's options and dispatch table, and calls C<run()>:

  caller or exit __PACKAGE__->main;

Override C<main()> in your subclass only if you need to add behaviour
that cannot be expressed in the manifest or C<init()>.

=head2 Distributing the Manifest

Add the manifest to your distribution's share
directory. C<CPAN::Maker> users can add it C<extra-files> in
C<buildspec.yml> so it is installed into the share directory:

  extra-files:
    - share:
      - my-script.yml

During development the manifest is found via C<%INC>. After
installation it is found via L<File::ShareDir>. No code changes
required between the two environments.
=head1 PHILOSOPHY AND DESIGN PRINCIPLES

C<CLI::Simple> is intentionally minimalist. It provides just enough
structure to build command-line tools with subcommands, option
parsing, and help handling -- but without enforcing any particular
framework or lifecycle.

=head2 Not a Framework

This module is not L<App::Cmd>, L<MooseX::Getopt>, or a full
application toolkit.  Instead, it offers:

=over 4

=item *

An object-oriented base class with a clean C<run()> dispatcher

=item *

Command-line parsing via C<Getopt::Long>

=item *

Built-in logging via C<Log::Log4perl>

=item *

Subclass hooks like C<init()> for setup and validation

=item *

Optional role-based architecture via YAML manifest for larger applications

=back

The philosophy is: provide just enough infrastructure, then get out of your way.

=head2 Validation, Defaults, and Configuration

C<CLI::Simple> does not impose a validation model. You may:

=over 4

=item *

Use C<Getopt::Long> features (e.g., type constraints, default values)

=item *

Write your own validation logic in C<init()>

=item *

Throw exceptions, emit usage, or exit early at any point

=back

The lifecycle is explicit and under your control. You decide how much structure
you want to add on top of it.

=head2 When to Use

C<CLI::Simple> is ideal for:

=over 4

=item *

Internal tools and admin scripts

=item *

Bootstrapped CLIs where you don't want a framework

=item *

Users who want to subclass a clean, minimal interface

=item *

Applications that have grown beyond a single module and benefit from
role-based command composition

=back

For interactive CLI handling or complex command trees, consider
L<App::Cmd> or L<CLI::Framework>.

=head2 The init-run Lifecycle

=over 4

=item * B<Phase 0: Internal Commands>

Before anything else, C<CLI::Simple> checks C<@ARGV> for internal
commands prefixed with C<->. If one is found it executes immediately
and exits. See L</INTERNAL COMMANDS>.

=item * B<Phase 1: Manifest Loading>

For role-based applications using C<use CLI::Simple qw(:roles)>, the
YAML manifest is loaded at compile time during C<import>. Roles are
composed into the calling class and the dispatch table is built before
C<new()> is ever called. Single-module applications skip this phase
entirely.

=item * B<Phase 2: Initialization (C<new> => C<init>)>

The constructor parses command-line arguments via C<Getopt::Long>,
creates accessors for all options, and calls your C<init()> method.
Inside C<init()>, your application has full access to the parsed options 
and arguments. This phase is the ideal hook for all final setup tasks, 
such as:

=over 4

=item * Validating command-line arguments.

=item * Loading configuration files based on a C<--config> option.

=item * Dynamically overriding the command (e..g, C<$self-E<gt>command('new_default')>).

=item * Performing any setup required B<before> a command is run.

=back


=item * B<Phase 3: Execution (C<run>)>

Dispatches to the command method determined during initialization.

=back

=head2  "opt-in" Default Command

By design, C<CLI::Simple> B<does not impose a default command>.
This provides total flexibility for the application author:

=over 4

=item * B<You Can Set a Default:> If your application needs a default
command (e.g., to run C<help> when no command is given), you can set
C<$AUTO_HELP>, explicitly set the C<default> command in the C<command>
hash you pass to the constructor or use C<command()> to set one
inside the C<init()> method.

=item * B<You Can Have No Default:> If you do B<not> set a default,
C<run()> will simply do nothing and return cleanly if no command
is provided on the command line.

=back

This "no default by default" behavior is what enables a powerful 
"setup-only" execution mode. A user can run your script I<without>
specifying a command. This will:

=over 4

=item 1. Run the entire C<new()> / C<init()> phase, performing all setup.

=item 2. Call C<run()>, which will find no command and exit cleanly.

=back

This provides an ideal hook for applications that need to perform
"on-demand initialization" (e.g., seeding a database, authenticating)
by checking for a specific flag inside C<init()>, without also
triggering an unwanted command.

In role-based applications using a YAML manifest, a C<default> command
that aliases another command should map to the sub name directly rather
than a role class:

  commands:
    default: cmd_install
    install: My::Module::Role::Installer

=head2 C<$AUTO_HELP> and C<$AUTO_DEFAULT>

Two package variables can be used to further control the lifecycle. By
default, the framework provides no default command as explained in the
sections above. Some scripters may want default behaviors that assume
a command or provide usage if no command is provided.

=over 4

=item C<$AUTO_HELP>

Set the package variable C<$AUTO_HELP> to a true value if you want
C<CLI::Simple> to provide help when no command is provided.

default: false

=item C<$AUTO_DEFAULT>

Set the package variable C<$AUTO_DEFAULT> to a true value if you want
C<CLI::Simple> to automatically select a command if you have only 1
command defined and no command is provided on the command line. When
true, it will prepend the single command name to the argument list,
allowing any subsequent arguments to be correctly parsed as args for
that command.

default: false

=item C<$PAGER>

Set the package variable C<$PAGER> to a true value to route help
output through L<IO::Pager> when C<--help> is invoked. When enabled,
C<IO::Pager> selects an appropriate pager (C<less>, C<more>, etc.)
based on the C<PAGER> environment variable, falling back to a sensible
default. Set to false to suppress pager use and write help directly to
STDOUT.

  use CLI::Simple qw($PAGER);
  $PAGER = 0;  # disable pager

default: true

Note: L<IO::Pager> must be installed for pager support. If it is not
available, help output is written directly to STDOUT regardless of the
value of C<$PAGER>.

=back

=head1 CONSTANTS

C<CLI::Simple> does not define its own constants directly, but it is often used
in conjunction with L<CLI::Simple::Constants>, which provides a collection of
exportable values commonly needed in command-line scripts.

These include:

=over 4

=item *

Boolean flags like C<$TRUE>, C<$FALSE>, C<$SUCCESS>, and C<$FAILURE>

=item *

Common character tokens such as C<$COLON>, C<$DASH>, C<$EQUALS_SIGN>, etc.

=item *

Log level names compatible with L<Log::Log4perl>

=back

To use them in your script:

  use CLI::Simple::Constants qw(:all);

=head1 ADDITIONAL NOTES

=over 4

=item * All options are case insensitive

=item * See L<CLI::Simple::Utils> to learn about additional utilities
useful when writing scripts, including C<choose>, C<slurp>, and C<dmp>.

=item * C<%INTERNAL_COMMANDS> is a package variable - subclasses can
add their own internal commands by pushing entries into the hash before
calling C<new()>.

=back

=head1 CUSTOMIZING HELP OUTPUT

=head2 C<help_sections>

By default C<CLI::Simple> passes a standard set of POD section names to
L<Pod::Usage> when rendering help output:

  SYNOPSIS DESCRIPTION/Commands DESCRIPTION/Options OPTIONS USAGE

You can override this by setting C<help_sections> on the object before
or after construction:

  my $cli = MyApp->new( ... );
  $cli->set_help_sections( [qw( SYNOPSIS OPTIONS )] );

Or by overriding in C<init>:

  sub init {
    my ($self) = @_;
    $self->set_help_sections( [qw( SYNOPSIS OPTIONS EXAMPLES )] );
    return $self->SUPER::init;
  }

Section names follow L<Pod::Usage> conventions. Subsections are
specified with a C</> separator, e.g. C<DESCRIPTION/Commands> renders
only the C<Commands> subsection under C<=head1 DESCRIPTION>.

=head1 INTERNAL COMMANDS

C<CLI::Simple> reserves command names beginning with C<-> for its own
use. These commands are intercepted before option parsing begins and
execute immediately, bypassing the normal lifecycle entirely. See
L</The init-run Lifecycle>.

Internal commands are dispatched via the C<%INTERNAL_COMMANDS> package
variable:

  our %INTERNAL_COMMANDS = (
    '-generate-completion' => \&_cmd_generate_completion,
    '-dump-spec'           => \&_cmd_dump_spec,
    '-scaffold'            => \&_cmd_scaffold,
    '-migrate'             => \&_cmd_migrate,
  );

Subclasses can add their own internal commands by extending the hash
before C<new()> is called:

  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' => \&_cmd_my_command,
  );

=head2 -generate-completion

Generates a bash completion script for the script's commands and
options, derived from the live object state. Bash completions are a
feature that allows the shell to automatically finish commands, file
paths, and options when you press the Tab key.

  my-script -generate-completion > \
    ~/.local/share/bash-completion/completions/my-script

After generating the bash completion script, source it in your current
shell to test:

  source ~/.local/share/bash-completion/completions/my-script

Test by typing your script name followed by a space and pressing Tab.
You should see the available commands. To verify option completion,
type C<--> and press Tab.

To make completions permanent, most systems automatically source files
placed in C<~/.local/share/bash-completion/completions/> when
C<bash-completion> 2.x is installed. If your system does not pick
them up automatically, add the following to your C<~/.bashrc>:

  source ~/.local/share/bash-completion/completions/my-script

Alternatively, place the generated file in the system-wide completion
directory (requires root):

  my-script -generate-completion > \
    /etc/bash_completion.d/my-script

The script name is taken from the first argument if provided, then
C<MODULINO_WRAPPER> if set, then inferred from the module name. If the
inferred name cannot be found in C<PATH>, a warning is issued but the
completion script is still generated.

I<Note: If you created the modulino with the supplied
C<create-modulino> tool C<MODULINO_WRAPPER> is already set inside the
bash script that invokes the modulino.>

=over 4

=item Case 1: Your modulino wrapper and module name are aligned 

The modulino script C<my-modulino> refers to My::Modulino

  my-modulino -generate-completion

=item Case 2: Your modulino wrapper was created using C<create-modulino>

The modulino script C<my-alias> refers to My::Modulino. They are not
aligned however C<MODULINO_WRAPPER> is set by the bash wrapper.

 my-alias -generate-completion

=item Case 3: Your modulino is an alias not created by C<create-modulino>

The script name C<my-alias> is not aligned with your module name
C<My::Module> and your modulino wrapper does not set
C<MODULINO_WRAPPER>. The C<-generate-completion> script called by 
your custom wrapper most likely only resolves the program name as the path to
your Perl module:

 path-to-modules/My/Module.pm

...in this case you need to supply the alias name or set
C<MODULINO_WRAPPER> in the environment.

 my-alias -generate-completion my-alias

=back

=head2 -dump-spec

Introspects the running modulino and writes a YAML manifest to the
current directory. The filename is derived from the module name by
convention.

  my-script -dump-spec           # sub names - baby step toward roles
  my-script -dump-spec roles     # role class names - full commitment

Without the C<roles> argument, commands map to their existing sub
names so the manifest can be used immediately without moving any
code. With C<roles>, commands map to derived role class names suitable
for use with C<-scaffold>.

Alias commands - those whose coderef resolves to a sub name that does
not match the command key - are always written as sub names regardless
of mode.

=head2 -scaffold

Generates a role-based project tarball from the running modulino or
from an explicit spec file. The tarball contains role stubs, a slimmed
main module with extracted POD, a C<project.mk> with inter-module
dependencies, and the YAML manifest.

  my-script -scaffold                        # introspect live module
  cli-simple -scaffold my-script.yml         # scaffold from spec file

The tarball is named C<my-script-roles.tar.gz> by convention (the
lower case snake cased version of the class name). The name is used to
infer the class name. If your filename is different than the
classes you want to scaffold, you will need to edit the files. 

Feed the tarball to L<CPAN::Maker::Bootstrapper> via the
C<import-scaffold> command to produce a complete buildable CPAN
distribution.

=head2 -migrate

Combines C<-dump-spec roles> and C<-scaffold> in a single step.

  my-script -migrate

Writes the YAML manifest then generates the role-based tarball. Use
this when you are ready for a full migration and do not need to inspect
or edit the manifest first. If you want to review or adjust the
manifest before scaffolding, run C<-dump-spec> and C<-scaffold>
separately.

=head1 METHODS AND SUBROUTINES

=head2 new

  new( args )

Instantiates a new C<CLI::Simple> instance, parses options, optionally
initializes logging, and makes options available via dynamically
generated accessors.

I<Note: The C<new()> constructor uses L<Getopt::Long>'s C<GetOptions>,
which directly modifies C<@ARGV> by removing any recognized
options. The remaining elements of C<@ARGV> are treated as the command
name and its arguments.>

C<args> is a hash or hash reference containing the following keys:

=over 4

=item * abbreviations

A boolean that determines whether abbreviated command names are allowed.

When true, the C<run()> method will treat the provided command as a prefix
and compare it to the keys in the command hash. If exactly one match is
found, it will be used. If more than one match is found, or if no match is
found, C<run()> will throw an exception.

This allows for convenient shorthand like:

  mytool disable-sched    # expands to 'disable-scheduled-task'

default: false

=item * commands (required)

A hash mapping command names to either a subroutine reference or an
array reference.

If an array reference is used, the first element must be a subroutine
reference and the second should be a valid log level. (See
L</Per Command Log Levels>.)

Example:

  {
    send          => \&send_message,
    receive       => \&receive_message,
    list_messages => [ \&list_messages, 'error' ],
  }

If your script does not use command names, you may set a C<default> key
to the subroutine or method to run:

  { default => \&main }

If no default is provided, the behavior is controlled by the
C<$AUTO_DEFAULT> and C<$AUTO_HELP> package variables.

Setting C<$AUTO_DEFAULT> to true when your C<commands> hash
contains only a single command, will cause that command to be run
automatically when no command name is given on the command line. This
allows you to treat the program like a single-command tool, where
arguments can be passed directly without explicitly naming the
command.

=item * default_options (optional)

A hash reference providing default values for options. These values
apply if the corresponding option is not given on the command line.

=item * extra_options (optional)

An array reference of names for additional accessors you want to create,
even if they are not part of C<option_specs>.

Example:

  extra_options => [ qw(foo bar baz) ]

=item * option_specs (optional)

An array reference of option specifications, as accepted by
L<Getopt::Long>. These define the command-line options your program
recognizes.

=back

=head2 command

 command
 command(command)

Get or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the C<run()> method.

=head2 commands (required)

 commands
 commands(command, handler)

Returns the hash you passed in the constructor as C<commands> or can
be used to insert a new command into the C<commands> hash. C<handler>
should be a code reference.

 commands(foo => sub { return 'foo' });

=head2 main

  __PACKAGE__->main;

For role-based applications, C<main> is inherited from C<CLI::Simple>
and reads the YAML manifest loaded during C<import>. It constructs the
object with the manifest's options, default options, extra options, and
dispatch table, then calls C<run()>.

In a role-based modulino the entire C<main> sub reduces to:

  caller or exit __PACKAGE__->main;

For single-module applications, override C<main> in your subclass as
usual.

=head2 run

Execute the script with the given options, commands and arguments. The
C<run> method interprets the command line and passes control to your
command subroutines. Your subroutines should return a 0 for success
and a non-zero value for failure.  This error code is passed to the
shell as the script return code.

=head2 get_args

Return the arguments that follow the command.

  get_args(NAME, ... )     # with names
  get_args()               # raw positional args

=head3 With names

=over 4

=item In scalar context, returns a hash reference mapping each NAME to
the corresponding positional argument.

=item In list context, returns a flat list of C<(name => value)> pairs.

=back

Example:

  sub send_message {
    my ($self) = @_;

    my %args = $self->get_args(qw(message email));

    _send_message($args{message}, $args{email});
  }

When you call C<get_args> with a list of names, values are assigned in
order: the first name gets the first argument, the second name gets the
second argument, and so on. If you only want specific positions, you may
use C<undef> as a placeholder:

  my %args = $self->get_args('message', undef, 'cc');  # args 1 and 3

If there are fewer positional arguments than names, the remaining names
are set to C<undef>. Extra positional arguments (beyond the provided
names) are ignored.

=head3 With no names

=over 4

=item In scalar context returns an array reference containing the
command's positional arguments.

=item In list context returns a list containing the command's
positional arguments.

=back

=head2 init

If you define your own C<init()> method, it will be called by the
constructor. Use this method to perform any actions you require before
you execute the C<run()> method.

=head1 USING PACKAGE VARIABLES

You can pass the necessary parameter required to implement your
command line scripts in the constructor or some people prefer to see
them clearly defined in the code. Accordingly, you can use package
variables with the same name as the constructor arguments (in upper
case).

 our $OPTION_SPECS = [
   qw(
     help|h
     log-level=s|L
     debug|d
   )
 ];

 our $COMMANDS = {
   foo => \&foo,
   bar => \&bar,
 };

Subclasses can also extend the built-in internal commands by adding
entries to C<%INTERNAL_COMMANDS>:

  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' => \&_cmd_my_command,
  );

=head1 COMMAND LINE OPTIONS

Command-line options are defined using L<Getopt::Long>-style
specifications. You pass these into the constructor via the
C<option_specs> parameter:

  my $cli = CLI::Simple->new(
    option_specs => [ qw( help|h foo-bar=s log-level=s ) ]
  );

In your command subroutines, you can access these values using
automatically generated getter methods:

  $cli->get_foo();
  $cli->get_log_level();

Option names that contain dashes (C<->) are automatically converted to
snake_case for the accessor methods. For example:

  option_specs => [ 'foo-bar=s' ]

...results in:

  $cli->get_foo_bar();

=head2 set_args

Resets the positional arguments.

 $self->set_args(qw(foo 1));

This method overrides the positional arguments originally passed to
the script. You can achieve the same behavior by calling the
C<get_args> in scalar context and modifying the reference.

 my $args = $self->get_args;
 $args->[1] = '2';

Use this technique when you want don't want to alter the entire set of
arguments.

=head1 COMMAND ARGUMENTS

If your commands accept positional arguments, you can retrieve them
using the C<get_args> method.

You may optionally provide a list of argument names, in which case the
arguments will be returned as a hash (or hashref in scalar context)
with named values.

Example:

  sub send_message {
    my ($self) = @_;

    my %args = $self->get_args(qw(phone_number message));

    send_sms_message($args{phone_number}, $args{message});
  }

If you call C<get_args()> without any argument names, it simply
returns all remaining arguments as a list:

  my ($phone_number, $message) = $self->get_args;

I<Note: When called with names, C<get_args> returns a hash in list
context and a hash reference in scalar context.>

=head1 CUSTOM ERROR HANDLER

By default, C<CLI::Simple> will exit if C<GetOptions> returns a false
value, indicating an error while parsing options. You can override this
behavior in one of two ways:

=over 4

=item * Set C<$CLI::Simple::GETOPT_EXIT_ON_ERROR> to a false value.

This disables automatic exiting and lets your program decide what to do
after an option-parsing failure.

=item * Provide an C<error_handler> callback in the constructor.

  my $cli = CLI::Simple->new(
    commands        => \%commands,
    default_options => \%default_options,
    extra_options   => \@extra_options,
    option_specs    => \@option_specs,
    abbreviations   => $TRUE,
    error_handler   => sub {
      my ($msg) = @_;
      print {*STDERR} $msg;
      return $TRUE;   # continue processing
    },
  );

The error handler is called with the error message from C<GetOptions>.
It must return a boolean: a true value allows processing to continue,
while a false value causes C<CLI::Simple> to exit immediately.

=back

=head1 SETTING DEFAULT VALUES FOR OPTIONS

To assign default values to your options, pass a hash reference as the
C<default_options> argument to the constructor. These values will be
used unless explicitly overridden by the user on the command line.

Example:

  my $cli = CLI::Simple->new(
    default_options => { foo => 'bar' },
    option_specs    => [ qw(foo=s bar=s) ],
    commands        => {
      foo => \&foo,
      bar => \&bar,
    },
  );

Defaulted options are accessible through their corresponding getter
methods, just like options set via the command line.

=head1 ADDING USAGE TO YOUR SCRIPTS

To provide built-in usage/help output, include a C<=head1 USAGE>
section in your script's POD:

  =head1 USAGE

    usage: myscript [options] command args

    Options
    -------
    --help, -h      Display help
    ...

If the user supplies the command C<help>, or the C<--help> option,
C<CLI::Simple> will display this section automatically:

  perl myscript.pm --help
  perl myscript.pm help

=head2 Custom help() Method

If you need full control over the help output, you can define a custom
C<help> method and assign it as a command:

  commands => {
    help => \&help,
    ...
  }

This is useful if your module follows the modulino pattern and you
want to present usage information that differs from the embedded
POD. Without a custom handler, C<CLI::Simple> defaults to displaying the
C<USAGE> POD section.

=head1 ADDING ADDITIONAL SETTERS

All command-line options are automatically available through getter
methods named C<get_*>.

If you need to create additional accessors (getters and setters) for
values that are not derived from the command line, use the
C<extra_options> parameter.

This is useful for passing runtime configuration or computed values
throughout your application.

Example:

  my $cli = CLI::Simple->new(
    default_options => { foo => 'bar' },
    option_specs    => [ qw(foo=s bar=s) ],
    extra_options   => [ qw(biz buz baz) ],
    commands        => {
      foo => \&foo,
      bar => \&bar,
    },
  );

This will generate C<get_biz>, C<set_biz>, C<get_buz>, etc., for
internal use.

=head1 LOGGING

C<CLI::Simple> integrates with L<Log::Log4perl> to provide structured
logging for your scripts.

To enable logging, call the class method C<use_log4perl()> in your
module or script:

  __PACKAGE__->use_log4perl(
    level  => 'info',
    config => $log4perl_config_string
  );

If you do not explicitly include a C<log-level> option in your
C<option_specs>, CLI::Simple will automatically add one for you.

Once enabled, you can access the logger instance via:

  my $logger = $self->get_logger;

This logger supports the standard Log4perl methods like C<info>,
C<debug>, C<warn>, etc.

=head2 Per Command Log Levels

Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.

To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.

The array reference should contain at least two elements:

=over 4

=item A code reference to the command subroutine

=item A log level string: one of 'trace', 'debug', 'info', 'warn',
'error', or 'fatal'

=back

Example:

  CLI::Simple->new(
    option_specs    => [qw( help format=s )],
    default_options => { format => 'json' },  # set some defaults
    extra_options   => [qw( content )],       # non-option, setter/getter
    commands        => {
      execute => \&execute,
      list    => [ \&list, 'error' ],
    }
  )->run;

I<TIP: add other elements to the array for your command to process.>

I<Note: Per-command log levels are not currently supported in the YAML
manifest. Define them programmatically by overriding C<main()> if needed.>

=head1 FAQ

=over 4

=item * How do I execute startup code before my command runs?

Implement an C<init()> method in your class. The C<new()> constructor
will invoke this method before returning and before C<run()> is
executed.

Your C<init()> method will have access to all options and
arguments. Logging will also be initialized, so you can use
C<get_logger()> to emit messages.

=item * Do I need to implement commands?

No. If your script doesn't support multiple commands, you can specify
a C<default> key instead:

  commands => { default => \&main }

=item * Must I subclass C<CLI::Simple>?

No. You can use it procedurally or functionally.

=item * How do I turn my class into a script?

Use the modulino pattern: create a class that checks whether it is
being invoked directly:

  package MyScript;

  caller or __PACKAGE__->main();

  sub main {
    ...
  }

This lets the file be used as both a module and an executable script.

=item * How do I migrate an existing script to role-based architecture?

Run the built-in C<-dump-spec> command to generate a YAML manifest from
your existing script, then C<-scaffold> to generate role stubs:

  my-script -dump-spec        # generates my-script.yml
  my-script -scaffold         # generates my-script-roles.tar.gz

See L</ROLE-BASED ARCHITECTURE> for the full migration workflow.

=item * How do I start a new role-based project from scratch?

Write a YAML manifest and use the C<cli-simple> wrapper to scaffold it:

  cli-simple -scaffold my-script.yml

See L</ROLE-BASED ARCHITECTURE> for the manifest format.

=item * How do I enable bash completion for my script?

Your script must be invoked via a bash modulino wrapper with
C<MODULINO_WRAPPER> set. Then run:

  my-script -generate-completion > \
    ~/.local/share/bash-completion/completions/my-script

Wrappers generated by L<CPAN::Maker::Bootstrapper> set
C<MODULINO_WRAPPER> automatically.

=item * How do I add my own internal commands?

Add entries to C<%INTERNAL_COMMANDS> before calling C<new()>:

  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' => \&_cmd_my_command,
  );

=back

=head1 ALIASING OPTIONS AND COMMANDS

C<CLI::Simple> lets you define short, human-friendly aliases for both
option names and command names. Use the C<alias> parameter to C<new():>

  my $app = CLI::Simple->new(
    option_specs    => [ qw(config=s verbose!) ],
    commands        => { list => \&list, execute => \&execute },
    alias => {
      options  => { cfg => 'config', v => 'verbose' },
      commands => { ls  => 'list'   }
    },
  );

=head2 How option aliases work

=over 4

=item * Spec tail is copied automatically

You only name the canonical option in C<option_specs>. For each alias,
C<CLI::Simple> finds the canonical option's spec tail (for example
C<=s>, C<:i>, C<!>, C<+>) and appends it to the alias. In the example
above, C<cfg> behaves as if you had written C<cfg=s>, and C<v> behaves
as if you had written C<v!>.

I<Note: If your option includes a one-letter short-cut and the alias
does not start with the same letter it will not be automatically
enabled as a short-cut.>

=item * Accessors are created for both names

Accessors are generated from all option names (canonical and aliases),
with '-' normalized to '_'. In the example, both C<get_config()> and
C<get_cfg()> are available.

=item * Values are mirrored after parsing

After option parsing and normalization, values are mirrored so either
name can be used consistently. If both the canonical name and its alias
are provided on the command line, the alias wins and becomes the final
value for both names.

=item * No duplicate injection

If the alias already exists in C<option_specs>, it will not be injected
again; value mirroring still occurs.

=item * Errors are explicit

If an alias points at a canonical option that does not exist,
C<CLI::Simple> croaks with a clear error.

=item * Case sensitivity

C<Getopt::Long> is used with C<:config no_ignore_case>, so option names
(and therefore aliases) are case sensitive by default.

=back

=head2 How command aliases work

=over 4

=item * Simple mapping

Provide C<alias => { commands => { alias => canonical } }> to map an alias
to an existing command. In the example, C<ls> dispatches to the C<list>
command.

=item * Applied before abbreviations

Aliases are installed before command abbreviation resolution. If you
enable abbreviations, they apply to the full set of command names,
including any aliases.

=item * Errors are explicit

If an alias points at a command that does not exist, C<CLI::Simple> croaks
with a clear error.

=back

=head2 Usage examples

  # Using an option alias
  script.pl --cfg app.json execute

  # Using a command alias
  script.pl ls

After parsing, both C<get_config()> and C<get_cfg()> will return the
same value. If the user passes both C<--config> and C<--cfg>, the value
from C<--cfg> (the alias) is used.

I<Note: In role-based applications using a YAML manifest, command
aliases are expressed by mapping the alias command directly to the
target sub name rather than a role class. See L</ROLE-BASED ARCHITECTURE>.>

=head2 Recommendations

=over 4

=item * Keep the canonical spec single-named

Define a single canonical name in C<option_specs> and add other spellings
via C<alias>. Avoid multi-name specs like C<config|cfg=s>; use C<alias>
instead.

=item * Document your precedence

If you prefer the alias name to win when both are supplied, enforce
that in your application or adjust the mirroring order. By default, the
canonical name wins.

=back

=head1 ERRORS/EXIT CODES

When you execute the C<run()> method it passes control to the method
that implements the command specified on the command line. Your method
is expected to return 0 for success or an error code that you can pass
to the shell on exit.

  exit CLI::Simple->new(commands => { foo => \&cmd_foo })->run();

=head2 Exit Codes

C<CLI::Simple> uses conventional exit codes so that calling scripts
can distinguish between normal completion and error conditions.

=over 4

=item * '0'

Successful completion of a command (C<SUCCESS>).

=item * '1'

General usage error, such as C<--help> display via C<pod2usage>, or an
invalid command line (C<FAILURE>).

=item * '2'

Option parsing failure, such as an unrecognized option or invalid
argument (also reported as C<FAILURE>).

=item * Any other code

If a user-supplied command callback explicitly calls C<exit()> or
returns a numeric value other than 0 - 2, that code is passed through
unchanged to the shell. This allows application-specific exit codes.

=back

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
L<https://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Getopt::Long>, L<CLI::Simple::Constants>, L<CLI::Simple::Utils>,
L<Pod::Usage>, L<App::Cmd>, L<CLI::Framework>, L<Role::Tiny>,
L<CPAN::Maker::Bootstrapper>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
