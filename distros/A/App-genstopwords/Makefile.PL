#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::genstopwords',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/App/genstopwords.pm',
    ABSTRACT_FROM      => 'lib/App/genstopwords.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/gen-stopwords' ],
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM        => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-genstopwords-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'App::genstopwords' => {
                file    => 'lib/App/genstopwords.pm',
                version => MM->parse_version('lib/App/genstopwords.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/App-genstopwords.git',
                web  => 'https://github.com/manwar/App-genstopwords',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/App-genstopwords/issues'
            },
        },
    },
);
