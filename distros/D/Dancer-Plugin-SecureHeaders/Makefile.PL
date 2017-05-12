use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::SecureHeaders',
    AUTHOR           => q{Ewen, Colin (CASAO) <colin@draecas.com>},
    VERSION_FROM     => 'lib/Dancer/Plugin/SecureHeaders.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/SecureHeaders.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Dancer' => 0
    },
    TEST_REQUIRES => {
        'YAML' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-SecureHeaders-*' },
);
