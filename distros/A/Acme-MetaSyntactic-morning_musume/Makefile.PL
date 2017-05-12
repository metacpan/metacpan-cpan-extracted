use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Acme::MetaSyntactic::morning_musume',
    AUTHOR         => 'Laurent Boivin (elbeho) <elbeho@cpan.org>',
    VERSION_FROM   => 'lib/Acme/MetaSyntactic/morning_musume.pm',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'          => 0.94,
        'Test::MetaSyntactic' => 1.001,
    },
    PREREQ_PM  => {
        'Acme::MetaSyntactic' => 1.007,
        'Acme::MorningMusume' => 0.13,
    },
    MIN_PERL_VERSION => 5.006002,
    META_MERGE => {
        resources => {
            repository => 'http://github.com/elbeho/Acme-MetaSyntactic-morning_musume/',
        },
    },
    LICENSE   => 'perl',
    EXE_FILES => [ ],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-MetaSyntactic-morning_musume-*' },
);
