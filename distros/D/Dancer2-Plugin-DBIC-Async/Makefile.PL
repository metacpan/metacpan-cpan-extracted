#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::DBIC::Async',
    VERSION_FROM     => 'lib/Dancer2/Plugin/DBIC/Async.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/DBIC/Async.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.014,
    PREREQ_PM => {
        'Dancer2'            => 0,
        'Dancer2::Plugin'    => 0,
        'DBIx::Class'        => 0,
        'DBIx::Class::Async' => 0,
        'AnyEvent'           => 0,
        'Promises'           => 0,
        'Module::Runtime'    => 0,
    },
    TEST_REQUIRES => {
        'Test::More'   => 0,
        'DBD::SQLite'  => 0,
        'DBI'          => 0,
        'File::Temp'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-DBIC-Async-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Dancer2::Plugin::DBIC::Async' => {
                file    => 'lib/Dancer2/Plugin/DBIC/Async.pm',
                version => MM->parse_version('lib/Dancer2/Plugin/DBIC/Async.pm')
            }
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dancer2-Plugin-DBIC-Async.git',
                web  => 'https://github.com/manwar/Dancer2-Plugin-DBIC-Async',
            },
            bugtracker => {
                web  => 'https://github.com/manwar/Dancer2-Plugin-DBIC-Async/issues'
            },
        }})
     : ()
    ),
);
