use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Datafile::Hash',
    AUTHOR           => 'Hans Harder',
    VERSION_FROM     => 'lib/Datafile/Hash.pm',
    ABSTRACT         => 'Pure-Perl utilities for reading and writing key-value and INI-style config files',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',

    PREREQ_PM => {
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/HansH111/Datafile-Hash.pm.git',
                web  => 'https://github.com/HansH111/Datafile-Hash.pm',
            },
            bugtracker => {
                web => 'https://github.com/HansH111/Datafile-Hash.pm/issues',
            },
        },
        provides => {
            'Datafile::Hash' => {
                file    => 'lib/Datafile/Hash.pm',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Datafile-Hash-*' },

    test => { TESTS => 't/*.t' },
);
