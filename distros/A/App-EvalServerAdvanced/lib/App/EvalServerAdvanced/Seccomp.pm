package App::EvalServerAdvanced::Seccomp;
our $VERSION = '0.017';

use strict;
use warnings;

use Data::Dumper;
use List::Util qw/reduce uniq/;
use Moo;
use Linux::Clone;
use POSIX ();
use Linux::Seccomp;
use Carp qw/croak/;
use Permute::Named::Iter qw/permute_named_iter/;

use constant {
  CLONE_FILES => Linux::Clone::FILES,
  CLONE_FS => Linux::Clone::FS,
  CLONE_NEWNS => Linux::Clone::NEWNS,
  CLONE_VM => Linux::Clone::VM,
  CLONE_THREAD => Linux::Clone::THREAD,
  CLONE_SIGHAND => Linux::Clone::SIGHAND,
  CLONE_SYSVSEM => Linux::Clone::SYSVSEM,
  CLONE_NEWUSER => Linux::Clone::NEWUSER,
  CLONE_NEWPID => Linux::Clone::NEWPID,
  CLONE_NEWUTS => Linux::Clone::NEWUTS,
  CLONE_NEWIPC => Linux::Clone::NEWIPC,
  CLONE_NEWNET => Linux::Clone::NEWNET,
  CLONE_NEWCGROUP => Linux::Clone::NEWCGROUP,
  CLONE_PTRACE => Linux::Clone::PTRACE,
  CLONE_VFORK => Linux::Clone::VFORK,
  CLONE_SETTLS => Linux::Clone::SETTLS,
  CLONE_PARENT_SETTID => Linux::Clone::PARENT_SETTID,
  CLONE_CHILD_SETTID => Linux::Clone::CHILD_SETTID,
  CLONE_CHILD_CLEARTID => Linux::Clone::CHILD_CLEARTID,
  CLONE_DETACHED => Linux::Clone::DETACHED,
  CLONE_UNTRACED => Linux::Clone::UNTRACED,
  CLONE_IO => Linux::Clone::IO,
};

has exec_map => (is => 'ro', default => sub {+{}});
has profiles => (is => 'ro'); # aref

has _rules => (is => 'rw');

has seccomp => (is => 'ro', default => sub {Linux::Seccomp->new(SCMP_ACT_KILL)});
has _permutes => (is => 'ro', default => sub {+{}});
has _used_sets => (is => 'ro', default => sub {+{}});

has _finalized => (is => 'rw', default => 0); # TODO make this set once

# Define some more open modes that POSIX doesn't have for us.
my ($O_DIRECTORY, $O_CLOEXEC, $O_NOCTTY, $O_NOFOLLOW) = (00200000, 02000000, 00000400, 00400000);

# TODO this needs some accessors to make it easier to define rulesets
our %rule_sets = (
  default => {
    include => ['time_calls', 'file_readonly', 'stdio', 'exec_wrapper', 'file_write', 'file_tty', 'file_opendir', 'perlmod_file_temp'],
    rules => [{syscall => 'mmap'},
              {syscall => 'munmap'},
              {syscall => 'mremap'},
              {syscall => 'mprotect'},
              {syscall => 'madvise'},
              {syscall => 'brk'},

              {syscall => 'exit'},
              {syscall => 'exit_group'},
              {syscall => 'rt_sigaction'},
              {syscall => 'rt_sigprocmask'},
              {syscall => 'rt_sigreturn'},

              {syscall => 'getuid'},
              {syscall => 'geteuid'},
              {syscall => 'getcwd'},
              {syscall => 'getpid'},
              {syscall => 'gettid'},
              {syscall => 'getgid'},
              {syscall => 'getegid'},
              {syscall => 'getgroups'},
    
              {syscall => 'access'}, # file_* instead?
              {syscall => 'readlink'},
              
              {syscall => 'arch_prctl'},
              {syscall => 'set_tid_address'},
              {syscall => 'set_robust_list'},
              {syscall => 'futex'},
              {syscall => 'getrlimit'},
      # TODO these should be defaults? locked down more?
      {syscall => 'prctl',},
      {syscall => 'poll',},
      {syscall => 'uname',},
    ],
  },

  perm_test => {
    permute => {foo => [1, 2, 3], bar => [4, 5, 6]},
    rules => [{syscall => 'permme', permute_rules => [[0, '==', \'foo'], [1, '==', \'bar']]}]
  },

  # File related stuff
  stdio => {
    rules => [{syscall => 'read', rules => [[qw|0 == 0|]]},  # STDIN
              {syscall => 'write', rules => [[qw|0 == 1|]]}, # STDOUT
              {syscall => 'write', rules => [[qw|0 == 2|]]},
              ],
  },
  file_open => {
    rules => [{syscall => 'open',   permute_rules => [['1', '==', \'open_modes']]}, 
              {syscall => 'openat', permute_rules => [['2', '==', \'open_modes']]},
              {syscall => 'close'},
              {syscall => 'select'},
              {syscall => 'read'},
              {syscall => 'pread64'},
              {syscall => 'lseek'},
              {syscall => 'fstat'}, # default? not file_open?
              {syscall => 'stat'},
              {syscall => 'lstat'},
              {syscall => 'fcntl'},
              # 4352  ioctl(4, TCGETS, 0x7ffd10963820)  = -1 ENOTTY (Inappropriate ioctl for device)
              # This happens on opened files for some reason? wtf
              {syscall => 'ioctl', rules =>[[1, '==', 0x5401]]},
              ],
  },
  file_opendir => {
    rules => [{syscall => 'getdents'},
              {syscall => 'open', rules => [['1', '==', $O_DIRECTORY|POSIX::O_RDONLY|POSIX::O_NONBLOCK|$O_CLOEXEC]]}, 
             ],
    include => ['file_open'],
  },
  file_tty => {
    permute => {open_modes => [$O_NOCTTY]},
    include => ['file_open'],
  },
  file_readonly => { 
    permute => {open_modes => [POSIX::O_NONBLOCK, POSIX::O_EXCL, POSIX::O_RDONLY, $O_NOFOLLOW, $O_CLOEXEC]},
    include => ['file_open'],
  },
  file_write => {
    permute => {open_modes => [POSIX::O_CREAT,POSIX::O_WRONLY, POSIX::O_TRUNC, POSIX::O_RDWR]},
    rules => [{syscall => 'write'},
              {syscall => 'pwrite64'},
    ],
    include => ['file_open', 'file_readonly'],
  },

  # time related stuff
  time_calls => {
    rules => [
      {syscall => 'nanosleep'},
      {syscall => 'clock_gettime'},
      {syscall => 'clock_getres'},
    ],
  },

  # ruby timer threads
  ruby_timer_thread => {
#    permute => {clone_flags => []},
    rules => [
      {syscall => 'clone', rules => [[0, '==', CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID]]},

      # Only allow a new signal stack context to be created, and only with a size of 8192 bytes.  exactly what ruby does
      # Have to allow it to be blind since i can't inspect inside the struct passed to it :(  I'm not sure how i feel about this one
      {syscall => 'sigaltstack', }, #=> rules [[1, '==', 0], [2, '==', 8192]]},
      {syscall => 'pipe2', },
    ],
  },

  # perl module specific
  perlmod_file_temp => {
    rules => [
      {syscall => 'chmod', rules => [[1, '==', 0600]]},
      {syscall => 'unlink', },
      ],
  },

  # exec wrapper
  exec_wrapper => {
    # we have to generate these at runtime, we can't know ahead of time what they will be
    rules => sub {
        my $seccomp = shift;
        my $strptr = sub {unpack "Q", pack("p", $_[0])};
        my @rules;

        my $exec_map = $seccomp->exec_map;

        for my $version (keys %$exec_map) {
          push @rules, {syscall => 'execve', rules => [[0, '==', $strptr->($exec_map->{$version}{bin})]]};
        }

        return @rules;
      }, # sub returns a valid arrayref.  given our $self as first arg.
  },

  # language master rules
  lang_perl => {
    rules => [],
    include => ['default'],
  },

  lang_javascript => {
    rules => [{syscall => 'pipe2'},
              {syscall => 'epoll_create1'},
              {syscall => 'eventfd2'},
              {syscall => 'epoll_ctl'},
              {syscall => 'epoll_wait'},
              {syscall => 'ioctl', rules => [[1, '==', 0x5451]]}, # ioctl(0, FIOCLEX)
              {syscall => 'clone', rules => [[0, '==', CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID]]},
              {syscall => 'ioctl', rules => [[1, '==', 0x80045430]]},  #19348 ioctl(1, TIOCGPTN <unfinished ...>) = ?
              {syscall => 'ioctl', rules => [[1, '==', 0x5421]]},  #ioctl(0, FIONBIO)
              {syscall => 'ioctl', rules => [[0, '==', 1]]}, # just fucking let node do any ioctl to STDOUT
              {syscall => 'ioctl', rules => [[0, '==', 2]]}, # just fucking let node do any ioctl to STDERR

    ],
    include => ['default'],
  },

  lang_ruby => {
    rules => [
      # Thread IPC writes, these might not be fixed but I don't know how to detect them otherwise 
      {syscall => 'write', rules => [[0, '==', 5]]},
      {syscall => 'write', rules => [[0, '==', 7]]},
    ],
    include => ['default', 'ruby_timer_thread'],
  },
);

sub rule_add {
  my ($self, $name, @rules) = @_;

  $self->seccomp->rule_add(SCMP_ACT_ALLOW, Linux::Seccomp::syscall_resolve_name($name), @rules);
}

sub _rec_get_rules {
  my ($self, $profile) = @_;

  return () if ($self->_used_sets->{$profile});
  $self->_used_sets->{$profile} = 1;

  croak "Rule set $profile not found" unless exists $rule_sets{$profile};

  my @rules;
  #print "getting profile $profile\n";

  if (ref $rule_sets{$profile}{rules} eq 'ARRAY') {
    push @rules, @{$rule_sets{$profile}{rules}};
  } elsif (ref $rule_sets{$profile}{rules} eq 'CODE') {
    my @sub_rules = $rule_sets{$profile}{rules}->($self);
    push @rules, @sub_rules;
  } elsif (!exists $rule_sets{$profile}{rules}) { # ignore it if missing
  } else {
    croak "Rule set $profile defines an invalid set of rules";
  }
  
  for my $perm (keys %{$rule_sets{$profile}{permute} // +{}}) {
    push @{$self->_permutes->{$perm}}, @{$rule_sets{$profile}{permute}{$perm}};
  }

  for my $include (@{$rule_sets{$profile}{include}//[]}) {
    push @rules, $self->_rec_get_rules($include);
  }

  return @rules;
}

sub build_seccomp {
  my ($self) = @_;

  croak "build_seccomp called more than once" if ($self->_finalized);

  my %gathered_rules; # computed rules

  for my $profile (@{$self->profiles}) {
    my @rules = $self->_rec_get_rules($profile);

    for my $rule (@rules) {
      my $syscall = $rule->{syscall};
      push @{$gathered_rules{$syscall}}, $rule;
    }
  }

  # optimize phase
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
          my $r = int(log($q)/log(2)+0.5); # get the thing

          $mode |= $modes[$r];

          #print "$r";
        }
        $q <<= 1;
      } while ($q <= $bit);

      push @{$full_permute{$permute}}, $mode;
    }
  }

  for my $k (keys %full_permute) {
  @{$full_permute{$k}} = sort {$a <=> $b} uniq @{$full_permute{$k}} 
  }


  my %comp_rules;

  for my $syscall (keys %gathered_rules) {
    my @rules = @{$gathered_rules{$syscall}};
    for my $rule (@rules) {
      my $syscall = $rule->{syscall};

      if (exists ($rule->{permute_rules})) {
        my @perm_on = ();
        for my $prule (@{$rule->{permute_rules}}) {
          if (ref $prule->[2]) {
            push @perm_on, ${$prule->[2]};
          }
          if (ref $prule->[0]) {
            croak "Permuation on argument number not supported using $syscall";
          }
        }

        croak "Permutation on syscall rule without actual permutation specified" if (!@perm_on);

        my %perm_hash = map {$_ => $full_permute{$_}} @perm_on;
        my $iter = permute_named_iter(%perm_hash);

        while (my $pvals = $iter->()) {

          push @{$comp_rules{$syscall}}, 
            [map {
              my @r = @$_;
              $r[2] = $pvals->{${$r[2]}};
              \@r;
            } @{$rule->{permute_rules}}];
        }
      } elsif (exists ($rule->{rules})) {
        push @{$comp_rules{$syscall}}, $rule->{rules};
      } else {
        push @{$comp_rules{$syscall}}, [];
      }
    }
  }

  # TODO optimize for permissive rules
  # e.g. write => OR write => [0, '==', 1] OR write => [0, '==', 2] becomes write =>
  for my $syscall (keys %comp_rules) {
    for my $rule (@{$comp_rules{$syscall}}) {
      $self->rule_add($syscall, @$rule);
    }
  }

  $self->_finalized(1);
}

sub apply_seccomp {
  my $self = shift;
  $self->seccomp->load;
}

sub engage {
  my $self = shift;
  $self->build_seccomp();
  $self->apply_seccomp();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EvalServerAdvanced::Seccomp - Use of Seccomp to create a safe execution environment

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is a rule generator for setting up Linux::Seccomp rules.

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

=head1 USE

You'll want to take a look at the 'etc' directory in the dist for an example config.  
Future versions will include a script for generating a configuration and environment for running
the server.

Right now you probably don't actually want to actually install this, but instead just download the dist and run from it locally.
It's a bit difficult to use and requires root.

=head1 TODO

=over 1

=item Make a script to create a usable environment

=item Create some kind of pluggable system for specifiying additional Seccomp rules

=item Create another pluggable system for extending App::EvalServer::Sandbox::Internal with additional subs

=item Finish enabling full configuration of the sandbox without having to edit any code

=back

=head1 SEE ALSO

L<App::EvalServerAdvanced::REPL>, L<App::EvalServerAdvanced::Protocol>

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=cut
