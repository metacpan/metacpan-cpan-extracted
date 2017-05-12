use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::NamedBinding',
    AUTHOR              => 'Andrew Sweger <yDNA@cpan.org>',
    VERSION_FROM        => 'lib/DBIx/NamedBinding.pm',
    ABSTRACT_FROM       => 'lib/DBIx/NamedBinding.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI'        => 0,
        'DBD::SQLite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-NamedBinding-*' },
);
