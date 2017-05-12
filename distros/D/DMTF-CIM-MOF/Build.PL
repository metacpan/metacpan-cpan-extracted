use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DMTF::CIM::MOF',
    license             => 'perl',
    dist_author         => 'Stephen James Hurd <shurd@broadcom.com>',
    dist_version_from   => 'lib/DMTF/CIM/MOF.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'DMTF::CIM'  => 0,
        'Storable'   => 0,
        'Exporter'   => '5.57',
    },
    add_to_cleanup      => [ 'DMTF-CIM-MOF-*' ],
);

$builder->create_build_script();
