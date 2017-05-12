use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Auth::Extensible::Rights',
    AUTHOR           => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Auth/Extensible/Rights.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Auth/Extensible/Rights.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'YAML' => 0,    # for config files and tests
    },
    TEST_REQUIRES => {
        'Test::Pod::Coverage' => 1.08,
        'Pod::Coverage'       => 0.18,
    },
    PREREQ_PM => {
        'Dancer2'                           => 0,
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Rights-*' },
);
