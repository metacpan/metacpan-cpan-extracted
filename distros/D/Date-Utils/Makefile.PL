#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Date::Utils',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Date/Utils.pm',
    ABSTRACT_FROM      => 'lib/Date/Utils.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo::Role'               => '2.000000',
        'namespace::autoclean'    => '0.28',
        'Term::ANSIColor::Markup' => '0.06',
        'Date::Exception'         => '0.08',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Date-Utils-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Date::Utils' => { file => 'lib/Date/Utils.pm', version => '0.28' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Date-Utils.git',
                web  => 'https://github.com/manwar/Date-Utils',
            },
        }})
     : ()
    ),
);
