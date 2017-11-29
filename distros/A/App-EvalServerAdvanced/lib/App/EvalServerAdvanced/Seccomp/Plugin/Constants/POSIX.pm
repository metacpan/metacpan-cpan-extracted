package App::EvalServerAdvanced::Seccomp::Plugin::Constants::POSIX;
use strict;
use warnings;

use POSIX ();

use Function::Parameters;

method init_plugin($class: $seccomp) {
 POSIX::load_imports; # make the posix module calculate it's imports
 my @consts = grep {/^[A-Z0-9_]+$/} map {;$POSIX::EXPORT_TAGS{$_}->@*} keys %POSIX::EXPORT_TAGS;

 for my $name (@consts) {
   eval { # hide anything that isn't an actual constant that we got accidentally
     no warnings;
     my $value = POSIX->can($name)->();

     if (defined($value)) {
#        print "$name => $value\n";
        $seccomp->constants->add_constant($name, $value);
     }
   }
  }

  # in evals, in case they error because of duplication
  eval {$seccomp->constants->add_constant(O_DIRECTORY => 00200000)};
  eval {$seccomp->constants->add_constant(O_CLOEXEC   => 02000000)};
  eval {$seccomp->constants->add_constant(O_NOCTTY    => 00000400)};
  eval {$seccomp->constants->add_constant(O_NOFOLLOW  => 00400000)};
}

1;
__END__
