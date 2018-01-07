use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::LNPath',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Data/LNPath.pm',
    ABSTRACT_FROM    => 'lib/Data/LNPath.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    	'Scalar::Util' => '0',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-LNPath-*' },
	META_MERGE => {
        'meta-spec' => { version => 2 },
        x_contributors => [
        	'Stavros Vachtsevanos (svacht)' 
		],
    }
);
