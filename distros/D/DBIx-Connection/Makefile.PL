
use ExtUtils::MakeMaker;
use 5.006;

WriteMakefile(
    NAME         => 'DBIx::Connection',
    VERSION_FROM => 'lib/DBIx/Connection.pm',
    DISTNAME     => 'DBIx-Connection',
    PREREQ_PM    => { 
        'Abstract::Meta::Class' => 0,
	'DBI'      	        => 0,
	'Time::HiRes'  	        => 0,
	'Test::Pod'		=> 0,
	'Test::Pod::Coverage'	=> 0,
        'Carp'                  => 0,
    },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
);
