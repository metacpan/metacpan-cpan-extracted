use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CLI::Cmdline',
    AUTHOR           => 'Hans Harder',
    VERSION_FROM     => 'lib/CLI/Cmdline.pm',
    ABSTRACT_FROM    => 'lib/CLI/Cmdline.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',

    PREREQ_PM => {
    },
    BUILD_REQUIRES => {  # for building
        'ExtUtils::MakeMaker' => '6.52',
    },
    TEST_REQUIRES => {   # for testing
        'Test::More' => '0.88',
        'Test::Warnings' => '0.028',
        'Test::Pod::Coverage' => '1.04',
    },

    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://codeberg.org/HansH111/CLI-Cmdline.pm.git',
                web  => 'https://codeberg.org/HansH111/CLI-Cmdline.pm',
            },
            bugtracker => { web => 'https://codeberg.org/HansH111/CLI-Cmdline.pm/issues' },
        },
        provides => {
            'CLI::Cmdline' => {
                file    => 'lib/CLI/Cmdline.pm',
                version => '1.30',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'CLI-Cmdline-*' },
    test  => { TESTS => 't/*.t' },
);
