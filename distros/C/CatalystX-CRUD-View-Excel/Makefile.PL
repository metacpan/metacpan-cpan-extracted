use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CatalystX::CRUD::View::Excel',
    AUTHOR              => 'Peter Karman <karman at cpan dot org>',
    VERSION_FROM        => 'lib/CatalystX/CRUD/View/Excel.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/CRUD/View/Excel.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CatalystX::CRUD' => 0.27,
        'Catalyst::View::Excel::Template::Plus' => 0,
        'Path::Class'     => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-CRUD-View-Excel-*' },
);
