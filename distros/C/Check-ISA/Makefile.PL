#!/usr/bin/perl

use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Check::ISA',
    AUTHOR             => q{Yuval Kogman <NUFFIN@cpan.org>},
    VERSION_FROM       => 'lib/Check/ISA.pm',
    ABSTRACT_FROM      => 'lib/Check/ISA.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
    },
    PREREQ_PM => {
        'Test::use::ok' => 0,
        'Sub::Exporter' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Check-ISA-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Check::ISA' => { file => 'lib/Check/ISA.pm', version => '0.09' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Check-ISA.git',
                web  => 'https://github.com/manwar/Check-ISA',
            },
        }})
     : ()
    ),
);
