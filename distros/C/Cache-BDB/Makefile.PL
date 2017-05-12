use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cache::BDB',
    AUTHOR              => 'Josh Rotenberg <joshrotenberg@gmail.com>',
    VERSION_FROM        => 'lib/Cache/BDB.pm',
    ABSTRACT_FROM       => 'lib/Cache/BDB.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'BerkeleyDB' => '0.27',	  
	'Storable' => 0,
        'File::Path' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cache-BDB-*' },
);
