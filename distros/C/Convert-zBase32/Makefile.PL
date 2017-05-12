use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Convert::zBase32',
    AUTHOR            => 'Philip Gwyn',
    VERSION_FROM      => 'lib/Convert/zBase32.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Convert/zBase32.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <fil@localdomain>') : ()),
);
