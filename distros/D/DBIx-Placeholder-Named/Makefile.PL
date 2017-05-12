use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'DBIx::Placeholder::Named',
    AUTHOR       => 'Igor Sutton <igor.sutton@gmail.com>',
    VERSION_FROM => 'lib/DBIx/Placeholder/Named.pm',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Test::More'     => 0,
        'DBI'            => 0,
        'SQL::Tokenizer' => 0,
        'DBD::SQLite'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-Placeholder-Named-*' },
);
