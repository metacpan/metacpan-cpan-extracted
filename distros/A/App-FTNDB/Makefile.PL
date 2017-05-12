use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App-FTNDB',
    AUTHOR              => 'Robert James Clay <jame@rocasa.us>',
    VERSION_FROM        => 'lib/App/FTNDB.pm',

    ABSTRACT            => 'Application for Fidonet/FTN related processing in an SQL database supported by a Perl DBD module.',
    LICENSE             => 'perl',
    EXE_FILES           => [ qw( bin/ftndbadm bin/ftndb-admin bin/ftndb-nodelist ) ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Test::Pod'             => 1.22,
        'Test::Pod::Coverage'   => 1.08,
        'App::Cmd'              => 0,
        'Config::Tiny'          => 0,
        'DBI'                   => 0,
        'DBD::SQLite'           => 0,
        'Getopt::Std'           => 0,
        'File::Spec'            => 0,
        'FTN::Database'         => 0.34,
        'FTN::Log'              => 0.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', ZIPFLAGS => '-or9', },
    clean               => { FILES => 'ftndb-*' },
);
