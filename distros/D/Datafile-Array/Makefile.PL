use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Datafile::Array',
    AUTHOR           => 'Hans Harder',
    VERSION_FROM     => 'lib/Datafile/Array.pm',
    ABSTRACT         => 'Lightweight pure-Perl data file handlers for array/tabular/csv data',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',

    PREREQ_PM => {
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/HansH111/Datafile-Array.pm.git',
                web  => 'https://github.com/HansH111/Datafile-Array.pm',
            },
            bugtracker => {
                web => 'https://github.com/HansH111/Datafile-Array.pm/issues',
            },
        },
        provides => {
            'Datafile::Array' => {
                file    => 'lib/Datafile/Array.pm',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Datafile-Array-*' },

    test => { TESTS => 't/*.t' },
);
