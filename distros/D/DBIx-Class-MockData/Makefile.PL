use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Class::MockData',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/DBIx/Class/MockData.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Class/MockData.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => ['script/dbic-mockdata'],

    PREREQ_PM => {
        'DBIx::Class'  => '0.082841',
        'Carp'         => 0,
        'File::Spec'   => 0,
        'Scalar::Util' => 0,
    },

    TEST_REQUIRES => {
        'Test::More'      => '0.98',
        'Test::Exception' => 0,
        'DBD::SQLite'     => 0,
        'DBI'             => 0,
        'File::Temp'      => 0,
        'IPC::Open3'      => 0,
        'Symbol'          => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'DBIx::Class::MockData' => {
                file    => 'lib/DBIx/Class/MockData.pm',
                version => MM->parse_version('lib/DBIx/Class/MockData.pm')
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/DBIx-Class-MockData.git',
                web  => 'https://github.com/manwar/DBIx-Class-MockData',
            },
            bugtracker => {
                web => 'https://github.com/manwar/DBIx-Class-MockData/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'DBIx-Class-MockData-*' },
);
