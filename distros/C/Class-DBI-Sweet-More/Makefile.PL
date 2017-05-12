use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Sweet::More',
    AUTHOR              => 'ASAKURA Takuji <asakura.takuji+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/Sweet/More.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Sweet/More.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::DBI::Sweet' => 0.08,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Sweet-More-*' },
);
