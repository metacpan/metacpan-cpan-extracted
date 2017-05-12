use ExtUtils::MakeMaker;
use strict;
use warnings;
use v5.10;

WriteMakefile(
    NAME              => 'DBIx::Mint',
    VERSION_FROM      => 'lib/DBIx/Mint.pm', # finds $VERSION
    PREREQ_PM         => {
        'DBI'                 => 0,
        'Moo'                 => 1.0,
        'SQL::Abstract::More' => 1.26,
        'List::MoreUtils'     => 0,
        'DBIx::Connector'     => 0.53,
        'Clone'               => 0.38,
	'MooX::Singleton'     => 1.20,
    },
    BUILD_REQUIRES   => {
        'DBD::SQLite'         => 1.39,
        'Test::Warn'          => 0,
    },
    META_MERGE     => {
        resources  => {
            repository => 'https://github.com/jfraire/DBIx-Mint',
        },
    },
    ABSTRACT_FROM  => 'lib/DBIx/Mint.pm',
    AUTHOR         => 'Julio Fraire <julio.fraire@gmail.com>',
    LICENSE        => 'perl',
);
