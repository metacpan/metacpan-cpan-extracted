use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Class::Storage::DBI::OpenEdge',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kesteb@wsipc.org>},
    dist_version_from   => 'lib/DBIx/Class/Storage/DBI/OpenEdge.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'DBIx::Class'       => '0.08210',
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'DBIx-Class-Storage-DBI-OpenEdge-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
