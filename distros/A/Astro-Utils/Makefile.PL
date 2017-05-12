#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Astro::Utils',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Astro/Utils.pm',
    ABSTRACT_FROM      => 'lib/Astro/Utils.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DateTime' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Astro-Utils-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Astro::Utils' => { file => 'lib/Astro/Utils.pm', version => '0.02' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Astro-Utils.git',
                web  => 'https://github.com/manwar/Astro-Utils',
            },
        }})
     : ()
    ),
);
