use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Test::TempDB',
    AUTHOR              => 'Dan Friedman <lamech@cpan.org>',
    VERSION_FROM        => 'lib/Class/DBI/Test/TempDB.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Test/TempDB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                          => 0,
        'Class::DBI'                          => '0.96',
        'Class::Data::Inheritable'            => '0.02',
        'DBD::SQLite'                         => '0.29',
        'SQL::Translator'                     => '0.05',
        'Class::Accessor'                     => '0.18'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Test-TempDB-*' },
);
