#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Data::Types',
    AUTHOR             => q{David E. Wheeler <dwheeler@cpan.org>},
    VERSION_FROM       => 'lib/Data/Types.pm',
    ABSTRACT_FROM      => 'lib/Data/Types.pm',
    LICENSE            => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.17',
    },
    PREREQ_PM        => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Types-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Data-Types.git',
                web  => 'https://github.com/manwar/Data-Types',
            },
        }})
     : ()
    ),
);
