#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::calendr',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/App/calendr.pm',
    ABSTRACT_FROM      => 'lib/App/calendr.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/calendr' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM                  => {
        'Types::Standard'      => '1.000005',
        'MooX::Options'        => '4.023',
        'Module::Pluggable'    => '5.1',
        'Moo'                  => '2.000000',
        'Moo::Role'            => '2.000000',
        'namespace::autoclean' => '0.28',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-calendr-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'App::calendr'         => { file => 'lib/App/calendr.pm'        , version => '0.26' },
            'App::calendr::Option' => { file => 'lib/App/calendr/Option.pm' , version => '0.26' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/App-calendr.git',
                web  => 'https://github.com/manwar/App-calendr',
            },
        }})
     : ()
    ),
);
