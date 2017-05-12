use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Calendar::Japanese::Holiday',
    VERSION_FROM      => 'lib/Calendar/Japanese/Holiday.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Calendar/Japanese/Holiday.pm', # retrieve abstract from module
       AUTHOR         => 'Kazuyoshi Tomita <kztomita@bit-hive.com>') : ()),
);
