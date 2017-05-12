use 5.006001;
use ExtUtils::MakeMaker;

use File::Basename;


WriteMakefile(
    NAME              => 'DBIx::Compare',
    VERSION_FROM      => 'lib/DBIx/Compare.pm',
    PREREQ_PM         => {	DBI => 1.605,
							Test::Differences => 0.47,
    						Test::More => 0.80,
    						Test::Group => 0.07,
    						Module::List => 0.001
    					},
    ($] >= 5.005 ? 
      (AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
