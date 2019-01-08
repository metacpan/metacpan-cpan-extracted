#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Address::PostCode::UserAgent',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Address/PostCode/UserAgent.pm',
    ABSTRACT_FROM      => 'lib/Address/PostCode/UserAgent.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTTP::Tiny'           => 0,
        'Throwable'            => 0,
        'Moo'                  => 0,
        'namespace::autoclean' => 0.28,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Address-PostCode-UserAgent-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Address::PostCode::UserAgent'            => { file => 'lib/Address/PostCode/UserAgent.pm'          , version => '0.08' },
            'Address::PostCode::UserAgent::Exception' => { file => 'lib/Address/PostCode/UserAgent/Exception.pm', version => '0.08' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/Address-PostCode-UserAgent.git',
                web  => 'https://github.com/Manwar/Address-PostCode-UserAgent',
            },
        }})
     : ()
    ),
);
