use 5.008000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Acme::State',
    VERSION_FROM      => 'lib/Acme/State.pm', # finds $VERSION
    # PREREQ_PM         => { Coro => 1.0, },
    PREREQ_PM         => {  Devel::Caller => 0.1, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/State.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Walters <scott@slowass.net>') : ()),
);
