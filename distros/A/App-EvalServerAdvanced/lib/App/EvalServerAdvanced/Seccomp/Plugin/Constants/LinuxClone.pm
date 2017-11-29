package App::EvalServerAdvanced::Seccomp::Plugin::Constants::LinuxClone;
use strict;
use warnings;

use Linux::Clone;

use Function::Parameters;

method init_plugin($class: $seccomp) {
  my @names = qw/FILES FS NEWNS VM THREAD SIGHAND SYSVSEM NEWUSER NEWPID NEWUTS NEWIPC NEWNET NEWCGROUP PTRACE VFORK SETTLS PARENT_SETTID CHILD_SETTID CHILD_CLEARTID DETACHED UNTRACED IO/;

  for my $name (@names) {
    my $cname = "CLONE_$name";
    $seccomp->constants->add_constant($cname, Linux::Clone->$name);
  }
}

1;
__END__
