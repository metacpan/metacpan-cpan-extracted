#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Data::Money::Converter',
    AUTHOR             => q{Corey Watson <gphat@cpan.org>},
    VERSION_FROM       => 'lib/Data/Money/Converter.pm',
    ABSTRACT_FROM      => 'lib/Data/Money/Converter.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
    },
    PREREQ_PM => {
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
        'Data::Money'      => '0.17',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Money-Converter*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Data::Money::Converter' => { file => 'lib/Data/Money/Converter.pm', version => '0.07' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Data-Money-Converter.git',
                web  => 'https://github.com/manwar/Data-Money-Converter',
            },
        }})
     : ()
    ),
);
