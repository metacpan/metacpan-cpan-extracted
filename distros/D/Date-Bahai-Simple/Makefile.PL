#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Date::Bahai::Simple',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Date/Bahai/Simple.pm',
    ABSTRACT_FROM      => 'lib/Date/Bahai/Simple.pm',
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
        'Date::Utils'      => '0.22',
        'Time::localtime'  => '1.02',
        'Astro::Utils'     => '0.01',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Date-Bahai-Simple*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Date::Bahai::Simple' => { file => 'lib/Date/Bahai/Simple.pm', version => '0.20' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Date-Bahai-Simple.git',
                web  => 'https://github.com/manwar/Date-Bahai-Simple',
            },
        }})
     : ()
    ),
);
