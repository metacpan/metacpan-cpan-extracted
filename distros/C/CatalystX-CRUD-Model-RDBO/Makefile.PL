use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CatalystX::CRUD::Model::RDBO',
    AUTHOR       => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM => 'lib/CatalystX/CRUD/Model/RDBO.pm',

    #ABSTRACT_FROM       => 'lib/CatalystX/CRUD/Model/RDBO.pm',
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                     => 0,
        'Data::Dump'                     => 0,      # for testing
        'Rose::DB::Object'               => 0,
        'Rose::DBx::Object::MoreHelpers' => 0,
        'CatalystX::CRUD'                => 0.56,
        'Catalyst::Runtime'              => 5.8,
        'Rose::DBx::TestDB'              => 0,
        'Sort::SQL'                      => 0.05,
        'JSON'                           => 2,      # for serialize

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'CatalystX-CRUD-Model-RDBO-*' },
);
