#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Address::PostCode::UK',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Address/PostCode/UK.pm',
    ABSTRACT_FROM      => 'lib/Address/PostCode/UK.pm',
    LICENSE            => 'artistic_2',
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
    clean => { FILES => 'Address-PostCode-UK-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Address::PostCode::UK'                      => { file => 'lib/Address/PostCode/UK.pm'                   , version => '0.13' },
            'Address::PostCode::UK::Location'            => { file => 'lib/Address/PostCode/UK/Location.pm'          , version => '0.13' },
            'Address::PostCode::UK::Place'               => { file => 'lib/Address/PostCode/UK/Place.pm'             , version => '0.13' },
            'Address::PostCode::UK::Place::Constituency' => { file => 'lib/Address/PostCode/UK/Place/Constituency.pm', version => '0.13' },
            'Address::PostCode::UK::Place::Council'      => { file => 'lib/Address/PostCode/UK/Place/Council.pm'     , version => '0.13' },
            'Address::PostCode::UK::Place::Geo'          => { file => 'lib/Address/PostCode/UK/Place/Geo.pm'         , version => '0.13' },
            'Address::PostCode::UK::Place::Ward'         => { file => 'lib/Address/PostCode/UK/Place/Ward.pm'        , version => '0.13' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Address-PostCode-UK.git',
                web  => 'https://github.com/manwar/Address-PostCode-UK',
            },
        }})
     : ()
    ),
);
