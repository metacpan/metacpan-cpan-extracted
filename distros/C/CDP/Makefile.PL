use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CDP',
    VERSION_FROM      => 'lib/CDP.pm', # finds $VERSION
    PREREQ_PM         => {
        Frontier::Client    => 0,
        
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CDP.pm', # retrieve abstract from module
       AUTHOR         => 'jon <jon@>') : ()),
);
