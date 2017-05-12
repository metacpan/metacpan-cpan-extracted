use 5.006001;
use ExtUtils::MakeMaker;

use File::Basename;


WriteMakefile(
    NAME              => 'DBIx::Compare::ContentChecksum::mysql',
    VERSION_FROM      => 'lib/DBIx/Compare/ContentChecksum/mysql.pm',
    PREREQ_PM         => {  DBIx::Compare => 1.1,
    						DBI => 1.605,
    						DBD::mysql => 4.007,
    						Test::Differences => 0.47,
    						Test::More => 0.80,
    						Test::Group => 0.07
    					},
    ($] >= 5.005 ? 
      (AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
