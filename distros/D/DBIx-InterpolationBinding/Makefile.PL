use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::InterpolationBinding',
    VERSION_FROM      => 'lib/DBIx/InterpolationBinding.pm', # finds $VERSION
    PREREQ_PM         => { DBI => 0 },
    ABSTRACT_FROM     => 'lib/DBIx/InterpolationBinding.pm', # retrieve abstract from module
    AUTHOR            => 'Luke Ross <luke@lukeross.name>'
);
