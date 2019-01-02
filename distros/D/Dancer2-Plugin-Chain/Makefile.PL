#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Chain',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Chain.pm',
    ABSTRACT_FROM      => 'lib/Dancer2/Plugin/Chain.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.94',   # subtest
        'Plack'      => '1.0029', # OO-style Plack::Test
        'HTTP::Request::Common' => 0,
    },
    PREREQ_PM => {
        'Dancer2'              => '0.159002',
        'Dancer2::Plugin'      => '0.159002',
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Chain-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Dancer2::Plugin::Chain'         => { file => 'lib/Dancer2/Plugin/Chain.pm',        version => '0.09' },
            'Dancer2::Plugin::Chain::Router' => { file => 'lib/Dancer2/Plugin/Chain/Router.pm', version => '0.09' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dancer2-Plugin-Chain.git',
                web  => 'https://github.com/manwar/Dancer2-Plugin-Chain',
            },
        }})
     : ()
    ),
);
