use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Audit',
    AUTHOR              => 'Brian Duggan <bduggan@matatu.org>',
    VERSION_FROM        => 'lib/Class/DBI/Audit.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Audit.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::DBI' => 0,
        'mixin'      => 0,
        'SQL::Abstract' => 0,
        'DBD::SQLite' => '== 1.12',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Audit-*' },
);
