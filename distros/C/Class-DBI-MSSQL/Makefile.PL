use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::MSSQL',
    AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Class/DBI/MSSQL.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/MSSQL.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::DBI' => 0.95
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-MSSQL-*' },
);
