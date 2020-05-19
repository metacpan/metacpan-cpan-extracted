use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Blessed::Merge',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Blessed/Merge.pm',
    ABSTRACT_FROM    => 'lib/Blessed/Merge.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'JSONP' => '1.74',
    },
    PREREQ_PM => {
    	'Scalar::Util' => '0',
	'Carp' => '0',
	'Combine::Keys' => '0.09',	
	'Import::Export' => '0.06',
        'Tie::IxHash' => '1.23',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Blessed-Merge-*' },
);
