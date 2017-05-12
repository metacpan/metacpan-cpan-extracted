
use strict;
use 5.006;

use ExtUtils::MakeMaker;
#auto_manifest;
WriteMakefile(
    NAME         => 'Abstract::Meta::Class',
    VERSION_FROM => 'lib/Abstract/Meta/Class.pm',
    DISTNAME     => 'Abstract-Meta-Class',
    PREREQ_PM    => { 
	'Test::More' 	      => 0,
        'Carp'       	      => 0,
	'Test::Pod'           => 0,
	'Test::Pod::Coverage' => 0,
    },
    test	 => { TESTS => 't/*.t t/meta/*.t'},
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
);
