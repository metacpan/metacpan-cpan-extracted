use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Color::Mix',
    VERSION_FROM      => 'lib/Color/Mix.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::Warn'  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Color/Mix.pm', # retrieve abstract from module
       AUTHOR         => 'Lee Dalton <leedalton@gmail.com>') : ()),
);
