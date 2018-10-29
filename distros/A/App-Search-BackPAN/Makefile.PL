#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::Search::BackPAN',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/App/Search/BackPAN.pm',
    ABSTRACT_FROM      => 'lib/App/Search/BackPAN.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/search-backpan' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES     => {
        'Test::More'   => 0,
    },
    PREREQ_PM          => {
        'HTTP::Tiny'   => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Search-BackPAN-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/App-Search-BackPAN.git',
                web  => 'https://github.com/manwar/App-Search-BackPAN',
            },
        }})
     : ()
    ),
);
