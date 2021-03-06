#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Crypt::Hill',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Crypt/Hill.pm',
    ABSTRACT_FROM      => 'lib/Crypt/Hill.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Crypt-Hill-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Crypt::Hill'        => { file => 'lib/Crypt/Hill.pm',       version => '0.12' },
            'Crypt::Hill::Utils' => { file => 'lib/Crypt/Hill/Utils.pm', version => '0.12' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Crypt-Hill.git',
                web  => 'https://github.com/manwar/Crypt-Hill',
            },
        }})
     : ()
    ),
);
