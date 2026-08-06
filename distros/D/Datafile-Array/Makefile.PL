use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Datafile::Array',
    AUTHOR           => 'Hans Harder',
    VERSION_FROM     => 'lib/Datafile/Array.pm',
    ABSTRACT_FROM    => 'lib/Datafile/Array.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',

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

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://codeberg.org/HansH111/Datafile-Array.pm.git',
                web  => 'https://codeberg.org/HansH111/Datafile-Array.pm',
            },
            bugtracker => {
                web => 'https://codeberg.org/HansH111/Datafile-Array.pm/issues',
            },
        },
        provides => {
            'Datafile::Array' => {
                file    => 'lib/Datafile/Array.pm',
                version => '1.08',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Datafile-Array-*' },
    test  => { TESTS => 't/*.t' },
);

