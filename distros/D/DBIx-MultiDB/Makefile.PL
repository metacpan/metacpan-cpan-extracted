use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::MultiDB',
    AUTHOR        => 'Nelson Ferraz <nferraz@gmail.com>',
    VERSION_FROM  => 'lib/DBIx/MultiDB.pm',
    ABSTRACT_FROM => 'lib/DBIx/MultiDB.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'DBI'         => 0,
        'Test::Deep'  => 0,
        'DBD::SQLite' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-MultiDB-*' },
);
