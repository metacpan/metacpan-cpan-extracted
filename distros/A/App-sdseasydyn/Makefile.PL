use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::sdseasydyn',
    AUTHOR           => 'Sergio de Sousa <sergio@serso.com>',
    ABSTRACT         => 'EasyDNS Dynamic DNS updater (CLI-first App distribution)',
    LICENSE          => 'lgpl_2_1',
    VERSION_FROM     => 'lib/App/sdseasydyn.pm',
    EXE_FILES        => ['bin/sdseasydyn'],
    MIN_PERL_VERSION => '5.030',

    PREREQ_PM => {
        'strict'       => 0,
        'warnings'     => 0,

        'FindBin'      => 0,
        'Getopt::Long' => 0,

        'Config::Tiny' => 0,
        'HTTP::Tiny'   => 0,
        'MIME::Base64' => 0,
        'URI::Escape'  => 0,

        'Retry::Policy' => 0.02,
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/sergio-desousa/sdseasydyn',
            repository => {
                type => 'git',
                url  => 'https://github.com/sergio-desousa/sdseasydyn.git',
                web  => 'https://github.com/sergio-desousa/sdseasydyn',
            },
            bugtracker => {
                web => 'https://github.com/sergio-desousa/sdseasydyn/issues',
            },
        },
    },
);

