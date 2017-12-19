#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Res',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Res.pm',
    ABSTRACT_FROM      => 'lib/Dancer2/Plugin/Res.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.94',
        'HTTP::Request::Common' => 0,
        'Plack'                 => '1.0029', # Plack::Test OO interface
    },
    PREREQ_PM => {
        'Dancer2'         => '0.159002',
        'Dancer2::Plugin' => '0.159002',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Res-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Dancer2::Plugin::Res' => { file => 'lib/Dancer2/Plugin/Res.pm', version => '0.08' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dancer2-Plugin-Res.git',
                web  => 'https://github.com/manwar/Dancer2-Plugin-Res',
            },
        }})
     : ()
    ),
);
