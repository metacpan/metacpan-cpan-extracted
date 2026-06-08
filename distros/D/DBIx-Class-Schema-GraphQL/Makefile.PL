#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Class::Schema::GraphQL',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/DBIx/Class/Schema/GraphQL.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Class/Schema/GraphQL.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'DBIx::Class'           => '0.082843',
        'GraphQL::Schema'       => '0',
        'GraphQL::Type::Object' => '0',
        'GraphQL::Type::List'   => '0',
        'GraphQL::Type::NonNull'=> '0',
        'GraphQL::Type::Scalar' => '0',
    },

    TEST_REQUIRES => {
        'Test::More'         => '1.302',
        'DBD::SQLite'        => '1.70',
        'GraphQL::Execution' => '0',
    },

    test  => { TESTS    => 't/*.t'                       },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'    },
    clean => { FILES    => 'DBIx-Class-Schema-GraphQL-*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'DBIx::Class::Schema::GraphQL' => {
                file    => 'lib/DBIx/Class/Schema/GraphQL.pm',
                version => MM->parse_version('lib/DBIx/Class/Schema/GraphQL.pm')
            },
        },
        resources => {
            repository => {
                type   => 'git',
                url    => 'https://github.com/yourname/DBIx-Class-Schema-GraphQL.git',
                web    => 'https://github.com/yourname/DBIx-Class-Schema-GraphQL',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/DBIx-Class-Schema-GraphQL/issues'
            },
        },
    },
);
