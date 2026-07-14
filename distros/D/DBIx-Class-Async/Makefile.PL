#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'DBIx::Class::Async',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/DBIx/Class/Async.pm',
    ABSTRACT_FROM      => 'lib/DBIx/Class/Async.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'version'             => '0.77',
        'CHI'                 => 0,
        'JSON'                => 0,
        'JSON::MaybeXS'       => 0,
        'Carp'                => 0,
        'Try::Tiny'           => 0,
        'Data::Page'          => 0,
        'Metrics::Any'        => 0,
        'Future'              => 0,
        'IO::Async::Loop'     => 0,
        'IO::Async::Function' => 0,
        'Time::HiRes'         => 0,
        'Digest::MD5'         => 0,
        'Type::Params'        => 0,
        'Types::Standard'     => 0,
        'Scalar::Util'        => 0,
        'DBIx::Class'         => 0,
        'DBIx::Class'         => '0.082841',
        'DBIx::Class::InflateColumn::Serializer' => '0',
    },
    TEST_REQUIRES => {
        'DBI'                 => 0,
        'File::Spec'          => 0,
        'File::Temp'          => 0,
        'File::Copy'          => 0,
        'Test::More'          => 0,
        'Test::Exception'     => 0,
        'DBIx::Class'         => 0,
        'Future::AsyncAwait'  => 0,
        'SQL::Translator'     => 0.11018,
        'Math::Base36'        => 0.07
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Class-Async-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'DBIx::Class::Async' => {
                file    => 'lib/DBIx/Class/Async.pm',
                version => MM->parse_version('lib/DBIx/Class/Async.pm')
            },
            'DBIx::Class::Async::Exception' => {
                file    => 'lib/DBIx/Class/Async/Exception.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception.pm')
            },
            'DBIx::Class::Async::Exception::AmbiguousColumn' => {
                file    => 'lib/DBIx/Class/Async/Exception/AmbiguousColumn.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/AmbiguousColumn.pm')
            },
            'DBIx::Class::Async::Exception::Factory' => {
                file    => 'lib/DBIx/Class/Async/Exception/Factory.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/Factory.pm')
            },
            'DBIx::Class::Async::Exception::MissingColumn' => {
                file    => 'lib/DBIx/Class/Async/Exception/MissingColumn.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/MissingColumn.pm')
            },
            'DBIx::Class::Async::Exception::NoSuchRelationship' => {
                file    => 'lib/DBIx/Class/Async/Exception/NoSuchRelationship.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/NoSuchRelationship.pm')
            },
            'DBIx::Class::Async::Exception::NotInStorage' => {
                file    => 'lib/DBIx/Class/Async/Exception/NotInStorage.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/NotInStorage.pm')
            },
            'DBIx::Class::Async::Exception::RelationshipAsColumn' => {
                file    => 'lib/DBIx/Class/Async/Exception/RelationshipAsColumn.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Exception/RelationshipAsColumn.pm')
            },
            'DBIx::Class::Async::SelectNormaliser' => {
                file    => 'lib/DBIx/Class/Async/SelectNormaliser.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/SelectNormaliser.pm')
            },
            'DBIx::Class::Async::ResultSet' => {
                file    => 'lib/DBIx/Class/Async/ResultSet.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/ResultSet.pm')
            },
            'DBIx::Class::Async::ResultSetColumn' => {
                file    => 'lib/DBIx/Class/Async/ResultSetColumn.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/ResultSetColumn.pm')
            },
            'DBIx::Class::Async::ResultSet::Pager' => {
                file    => 'lib/DBIx/Class/Async/ResultSet/Pager.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/ResultSet/Pager.pm')
            },
            'DBIx::Class::Async::Row' => {
                file    => 'lib/DBIx/Class/Async/Row.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Row.pm')
            },
            'DBIx::Class::Async::Schema' => {
                file    => 'lib/DBIx/Class/Async/Schema.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Schema.pm')
            },
            'DBIx::Class::Async::Storage' => {
                file    => 'lib/DBIx/Class/Async/Storage.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Storage.pm')
            },
            'DBIx::Class::Async::Storage::DBI' => {
                file    => 'lib/DBIx/Class/Async/Storage/DBI.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Storage/DBI.pm')
            },
            'DBIx::Class::Async::Storage::DBI::Cursor' => {
                file    => 'lib/DBIx/Class/Async/Storage/DBI/Cursor.pm',
                version => MM->parse_version('lib/DBIx/Class/Async/Storage/DBI/Cursor.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/DBIx-Class-Async.git',
                web  => 'https://github.com/manwar/DBIx-Class-Async',
            },
            bugtracker => {
                web  => 'https://github.com/manwar/DBIx-Class-Async/issues'
            },
        },
    },
);
