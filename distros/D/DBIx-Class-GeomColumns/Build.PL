use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Class::GeomColumns',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/DBIx/Class/GeomColumns.pm',
    requires => {
        'Test::More'              => 0,
        'version'                 => 0,
        'DBIx::Class'             => 0,
        'Geo::Converter::WKT2KML' => 0,
    },
    add_to_cleanup      => [ 'DBIx-Class-GeomColumns-*' ],
);

$builder->create_build_script();
