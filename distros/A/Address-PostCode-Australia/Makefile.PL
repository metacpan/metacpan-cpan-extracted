#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Address::PostCode::Australia',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Address/PostCode/Australia.pm',
    ABSTRACT_FROM      => 'lib/Address/PostCode/Australia.pm',
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
        'JSON'             => 0,
        'Moo'              => 0,
        'namespace::clean' => 0,
        'Address::PostCode::UserAgent' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Address-PostCode-Australia-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Address::PostCode::Australia'         => { file => 'lib/Address/PostCode/Australia.pm',        version => '0.08' },
            'Address::PostCode::Australia::Place'  => { file => 'lib/Address/PostCode/Australia/Place.pm',  version => '0.08' },
            'Address::PostCode::Australia::Params' => { file => 'lib/Address/PostCode/Australia/Params.pm', version => '0.08' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Address-PostCode-Australia.git',
                web  => 'https://github.com/manwar/Address-PostCode-Australia',
            },
        }})
     : ()
    ),
);
