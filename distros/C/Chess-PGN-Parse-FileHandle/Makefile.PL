use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Chess::PGN::Parse::FileHandle',
    AUTHOR              => 'Steve Peters <steve@fisharerojo.org>',
    VERSION_FROM        => 'lib/Chess/PGN/Parse/FileHandle.pm',
    ABSTRACT_FROM       => 'lib/Chess/PGN/Parse/FileHandle.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Chess::PGN::Parse' => 0.18,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Chess-PGN-Parse-FileHandle-*' },
);
