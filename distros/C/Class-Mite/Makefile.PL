#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Class::Mite',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Class/Mite.pm',
    ABSTRACT_FROM      => 'lib/Class/Mite.pm',
    LICENSE            => 'artistic_2',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'version' => '0.77',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'Class-Mite-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            package => [ 'Class', 'Role', 'Class::More', 'Class::Clone' ],
            file    => [ 'lib/Class.pm', 'lib/Role.pm', 'lib/Class/More.pm', 'lib/Class/Clone.pm' ],
        },
        provides => {
            'Class::Mite' => {
                file    => 'lib/Class/Mite.pm',
                version => MM->parse_version('lib/Class/Mite.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Class-Mite.git',
                web  => 'https://github.com/manwar/Class-Mite',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Class-Mite/issues'
            },
        }})
     : ()
    ),
);
