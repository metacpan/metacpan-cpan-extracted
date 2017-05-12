use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::Piwik',
    AUTHOR           => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM     => 'lib/Dancer/Plugin/Piwik.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/Piwik.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
                  Dancer => 1.3124,
                  JSON => 0,
                 },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Piwik-*' },
);
