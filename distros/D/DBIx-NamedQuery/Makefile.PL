use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'DBIx::NamedQuery',
    VERSION_FROM      => 'lib/DBIx/NamedQuery.pm',
    NEEDS_LINKING     => 0,
    dist              => {
        COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
    },
    PREREQ_PM         => {
    	DBI	 => 1.30,
    },
    ($] >= 5.005 ?
      (
      ABSTRACT_FROM  => 'lib/DBIx/NamedQuery.pm',
      AUTHOR         => 'Boleslav Bobcik <bbobcik@gmail.com>') : ()
      ),
);
