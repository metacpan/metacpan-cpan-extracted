use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CLI::Cmdline',
    AUTHOR           => 'Hans Harder <hans@atbas.org>',
    VERSION_FROM     => 'lib/CLI/Cmdline.pm',
    ABSTRACT         => 'A minimal command-line parser with short and long options in pure Perl',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    PREREQ_PM => {
        # No external dependencies — pure core Perl
    },
    BUILD_REQUIRES => {  # for building
        'ExtUtils::MakeMaker' => '6.52',
    },
    TEST_REQUIRES => {   # for testing
        'Test::More' => '0.88',
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
                version => '1.22',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'CLI-Cmdline-*' },

    test => { TESTS => 't/*.t' },
);
