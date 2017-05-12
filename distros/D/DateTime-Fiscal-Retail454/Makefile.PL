use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DateTime::Fiscal::Retail454',
    VERSION_FROM      => 'lib/DateTime/Fiscal/Retail454.pm', # finds $VERSION
    PREREQ_PM         => {
        DateTime => 0,
        Carp => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DateTime/Fiscal/Retail454.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Bacon <jim@nortx.com>') : ()),
);
