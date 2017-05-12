use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CatalystX::CRUD',
    AUTHOR              => 'Peter Karman <perl@peknet.com>',
    VERSION_FROM        => 'lib/CatalystX/CRUD.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/CRUD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Pageset'    => 0,
        'Catalyst::Runtime'     => 5.80024,
        'Catalyst::Component::ACCEPT_CONTEXT' => 0.06,
        'Catalyst::Exception'   => 0,
        'Path::Class::File'     => 0,
        'MRO::Compat'           => 0.10,
        'Moose'                 => 0,  
        'MooseX::Emulate::Class::Accessor::Fast' => 0,
        'Data::Dump'            => 0,  # for testing
        'Sort::SQL'             => 0.07,
        'Search::QueryParser::SQL' => 0.010,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-CRUD-*' },
    META_MERGE => {
        resources => {
            repository =>
                'https://github.com/karpet/catalystx-crud',
        },
    },
);
