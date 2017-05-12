use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Plugin::AccessionSearch',
    AUTHOR              => 'Atsushi Kobayashi <nekokak@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/Plugin/AccessionSearch.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Plugin/AccessionSearch.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::DBI' => 0,
        'Class::DBI::Plugin' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Plugin-AccessionSearch-*' },
);
