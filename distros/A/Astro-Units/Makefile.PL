use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Astro::Units',
    AUTHOR           => q{Sushrut Pajai},
    VERSION_FROM     => 'lib/Astro/Units.pm',
    ABSTRACT_FROM    => 'lib/Astro/Units.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Carp' => 0,
        'bignum' => 0,
        'Math::BigFloat' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Astro-Units-*' },
    test => {TESTS => 't/*.t'},
);
