#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Calendar::Hijri',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Calendar/Hijri.pm',
    ABSTRACT_FROM      => 'lib/Calendar/Hijri.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
        'File::Temp'        => 0,
        'XML::SemanticDiff' => 0,
    },
    PREREQ_PM => {
        'Moo'                        => '2.000000',
        'namespace::autoclean'       => '0.28',
        'Date::Hijri::Simple'        => '0.22',
        'Calendar::Plugin::Renderer' => '0.15',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Calendar-Hijri-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Calendar::Hijri' => { file => 'lib/Calendar/Hijri.pm', version => '0.39' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Calendar-Hijri.git',
                web  => 'https://github.com/manwar/Calendar-Hijri',
            },
        }})
     : ()
    ),
);
