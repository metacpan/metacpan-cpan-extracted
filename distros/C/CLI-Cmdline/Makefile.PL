use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CLI::Cmdline',
    AUTHOR           => 'Hans Harder <hans at atbas.org>',
    VERSION_FROM     => 'lib/CLI/Cmdline.pm',
    ABSTRACT         => 'A minimal command-line parser with short and long options in pure Perl',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',

    PREREQ_PM => {
    },
    BUILD_REQUIRES => {  # for building
        'ExtUtils::MakeMaker' => '6.52',
    },
    TEST_REQUIRES => {   # for testing
        'Test::More' => '0.88',
        'Test::NoWarnings' => '1.04',
        'Test::Pod::Coverage' => '1.04',
    },

    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/HansH111/CLI-Cmdline.pm.git',
                web  => 'https://github.com/HansH111/CLI-Cmdline.pm',
            },
            bugtracker => { web => 'https://github.com/HansH111/CLI-Cmdline.pm/issues' },
        },
        provides => {
            'CLI::Cmdline' => {
                file    => 'lib/CLI/Cmdline.pm',
                version => '1.25',
            },
        },
        x_contributors => [
            'Hans Harder <hans@atbas.org>',
        ],
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'CLI-Cmdline-*' },

    test => { TESTS => 't/*.t' },
);
