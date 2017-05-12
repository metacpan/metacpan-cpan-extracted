use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Sweet::Pie',
    AUTHOR              => 'ASAKURA Takuji <asakura.takuji+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/Sweet/Pie.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Sweet/Pie.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::DBI::Sweet' => 0.08,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Sweet-Pie-*' },
);
