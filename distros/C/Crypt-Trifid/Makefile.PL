#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Crypt::Trifid',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Crypt/Trifid.pm',
    ABSTRACT_FROM      => 'lib/Crypt/Trifid.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Crypt-Trifid-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Crypt::Trifid'        => { file => 'lib/Crypt/Trifid.pm'      , version => '0.07' },
            'Crypt::Trifid::Utils' => { file => 'lib/Crypt/Trifid/Utils.pm', version => '0.07' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Crypt-Trifid.git',
                web  => 'https://github.com/manwar/Crypt-Trifid',
            },
        }})
     : ()
    ),
);
