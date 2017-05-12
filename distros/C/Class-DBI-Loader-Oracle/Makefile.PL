use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Loader::Oracle',
    AUTHOR              => 'David Naughton <naughton@cpan.org>',
    VERSION_FROM        => 'lib/Class/DBI/Loader/Oracle.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Loader/Oracle.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::DBI' => 0.96, 'Class::DBI::Oracle' => 0.51, 'Class::DBI::Loader' => 0.02, 'Test::More' => 0, 'DBD::Oracle' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Loader-Oracle-*' },
);
