use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::DBH',
    VERSION_FROM      => 'lib/DBIx/DBH.pm', # finds $VERSION
    PREREQ_PM         => {
			  Moose => 1.0,
			  Params::Validate => 0.7,
			  DBI              => 1.3
			 }, # e.g., Module::Name => 1.1
);
