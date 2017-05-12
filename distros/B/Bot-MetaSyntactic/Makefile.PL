use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Bot::MetaSyntactic',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Bot/MetaSyntactic.pm',
    ABSTRACT_FROM       => 'lib/Bot/MetaSyntactic.pm',
    EXE_FILES           => [ 'script/metabot' ], 
    PL_FILES            => {},
    PREREQ_PM => {
        'Acme::MetaSyntactic' => '0.70',
        'Bot::BasicBot' => '0.12',
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-MetaSyntactic-*' },
);
