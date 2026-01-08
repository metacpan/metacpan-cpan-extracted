#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'DBIx::Class::Async',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/DBIx/Class/Async.pm',
    ABSTRACT_FROM      => 'lib/DBIx/Class/Async.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'CHI'                 => 0,
        'Carp'                => 0,
        'Try::Tiny'           => 0,
        'Metrics::Any'        => 0,
        'IO::Async::Loop'     => 0,
        'IO::Async::Function' => 0,
        'Time::HiRes'         => 0,
        'Digest::MD5'         => 0,
        'Type::Params'        => 0,
        'Types::Standard'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Class-Async-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'DBIx::Class::Async' => {
                file    => 'lib/DBIx/Class/Async.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::Cursor' => {
                file    => 'lib/DBIx/Class/Async/Cursor.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::ResultSet' => {
                file    => 'lib/DBIx/Class/Async/ResultSet.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::Row' => {
                file    => 'lib/DBIx/Class/Async/Row.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::Schema' => {
                file    => 'lib/DBIx/Class/Async/Schema.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::Storage' => {
                file    => 'lib/DBIx/Class/Async/Storage.pm',
                version => '0.14'
            },
            'DBIx::Class::Async::TxnGuard' => {
                file    => 'lib/DBIx/Class/Async/TxnGuard.pm',
                version => '0.14'
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/DBIx-Class-Async.git',
                web  => 'https://github.com/manwar/DBIx-Class-Async',
            },
        }})
     : ()
    ),
);
