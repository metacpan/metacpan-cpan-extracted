use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::TAINT',
    AUTHOR           => q{Judy Garland <dorthy@wizard.oz>},
    VERSION_FROM     => 'lib/Acme/TAINT.pm',
    ABSTRACT_FROM    => 'lib/Acme/TAINT.pm',
    LICENSE          => 'artistic',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-TAINT-*' },
);
