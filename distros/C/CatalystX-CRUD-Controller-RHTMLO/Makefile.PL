use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CatalystX::CRUD::Controller::RHTMLO',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/CatalystX/CRUD/Controller/RHTMLO.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/CRUD/Controller/RHTMLO.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CatalystX::CRUD' => 0.28,
        'Rose::HTML::Objects' => 0,
        'MRO::Compat'         => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-CRUD-Controller-RHTMLO-*' },
);
