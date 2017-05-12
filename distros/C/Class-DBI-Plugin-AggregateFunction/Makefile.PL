use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Plugin::AggregateFunction',
    AUTHOR              => 'ASAKURA Takuji <asakura.takuji+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/Plugin/AggregateFunction.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Plugin/AggregateFunction.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::DBI' => 0,
        'SQL::Abstract' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Plugin-AggregateFunction-*' },
);
