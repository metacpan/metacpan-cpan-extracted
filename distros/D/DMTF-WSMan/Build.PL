use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DMTF::WSMan',
    license             => 'perl',
    dist_author         => 'Stephen James Hurd <shurd@broadcom.com>',
    dist_version_from   => 'lib/DMTF/WSMan.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'LWP'        => 0,
        'LWP::Authen::Digest' => 0,
        'Data::UUID' => 0,
    },
    add_to_cleanup      => [ 'DMTF-WSMan-*' ],
);

$builder->create_build_script();
