use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AI::Calibrate',
    VERSION_FROM      => 'lib/AI/Calibrate.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AI/Calibrate.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Fawcett <tfawcett@acm.org>') : ()),
);
