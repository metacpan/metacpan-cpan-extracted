use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Plugin::Param',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Class/DBI/Plugin/Param.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Plugin/Param.pm',
    PREREQ_PM => {
        'Test::More' => 0.32,
        'Class::DBI' => '3.0.11',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Plugin-Param-*' },
);
