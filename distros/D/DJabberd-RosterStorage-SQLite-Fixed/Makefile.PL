use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::RosterStorage::SQLite::Fixed',
    AUTHOR              => 'Edward Rudd <urkle@outoforder.cc>',
    VERSION_FROM        => 'lib/DJabberd/RosterStorage/SQLite/Fixed.pm',
    EXE_FILES           => ['scripts/rosteredit.pl'],
    ABSTRACT_FROM       => 'lib/DJabberd/RosterStorage/SQLite/Fixed.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0.83,
        'DJabberd::RosterStorage::SQLite' => 1.00
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-RosterStorage-SQLite-Fixed-*' },
);
