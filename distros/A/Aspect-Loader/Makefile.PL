use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Aspect::Loader',
    VERSION_FROM      => 'lib/Aspect/Loader.pm', # finds $VERSION
    PREREQ_PM         => {
      UNIVERSAL::require => 0.13,
      Aspect             => 0.90,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'root <root@localdomain>') : ()),
);
