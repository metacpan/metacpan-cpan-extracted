use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::SubstituteSubs',
    VERSION_FROM      => 'lib/Acme/SubstituteSubs.pm', # finds $VERSION
    PREREQ_PM         => { PPI => 0, 'Devel::Caller' => 0, 'Acme::Test' => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/SubstituteSubs.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Walters <knoppix@lightandslowass.net>') : ()),
);
