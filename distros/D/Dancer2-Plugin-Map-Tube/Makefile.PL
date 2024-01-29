#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Map::Tube',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Map/Tube.pm',
    ABSTRACT_FROM      => 'lib/Dancer2/Plugin/Map/Tube.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.94',
    },
    PREREQ_PM => {
        'Dancer2'                => '0.159002',
        'Dancer2::Plugin'        => '0.159002',
        'JSON'                   => '2.90',
        'Moo'                    => '2.000000',
        'namespace::autoclean'   => '0.28',
        'Cache::Memcached::Fast' => '0.25',
        'Class::Load'            => '0.22',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Map-Tube-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Dancer2::Plugin::Map::Tube'        => { file => 'lib/Dancer2/Plugin/Map/Tube.pm'      , version => '0.03' },
            'Dancer2::Plugin::Map::Tube::API'   => { file => 'lib/Dancer2/Plugin/Map/Tube/API.pm'  , version => '0.03' },
            'Dancer2::Plugin::Map::Tube::Error' => { file => 'lib/Dancer2/Plugin/Map/Tube/Error.pm', version => '0.03' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dancer2-Plugin-Map-Tube.git',
                web  => 'https://github.com/manwar/Dancer2-Plugin-Map-Tube',
            },
        }})
     : ()
    ),
);
