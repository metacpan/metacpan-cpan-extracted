use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Coerce::Types::Standard',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Coerce/Types/Standard.pm',
    ABSTRACT_FROM    => 'lib/Coerce/Types/Standard.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
		'Moo' => '2.003002',
		'MooX::LazierAttributes' => '1.03',
    },
    PREREQ_PM => {
    	'Type::Tiny' => '1.002001',
		'Scalar::Util' => '0',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Coerce-Types-Standard-*' },
);
