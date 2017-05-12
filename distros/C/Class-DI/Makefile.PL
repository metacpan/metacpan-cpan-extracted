use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DI',
    VERSION_FROM      => 'lib/Class/DI.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DI.pm', # retrieve abstract from module
       AUTHOR         => 'masafumi.yoshida <masafumi.yoshida820@gmail.com>') : ()),
);
