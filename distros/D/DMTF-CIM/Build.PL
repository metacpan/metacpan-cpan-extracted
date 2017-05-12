use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DMTF::CIM',
    license             => 'perl',
    dist_author         => 'Stephen James Hurd <shurd@broadcom.com>',
    dist_version_from   => 'lib/DMTF/CIM.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'DMTF-CIM-*' ],
);

$builder->create_build_script();
