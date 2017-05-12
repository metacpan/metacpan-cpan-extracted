use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::Migration::Classes',
    VERSION_FROM      => 'lib/DBIx/Migration/Classes.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
    	'Module::Collect' => 0,
    	'Data::Dumper' => 0,
    	'DBI' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/Migration/Classes.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tk@local>') : ()),
);
