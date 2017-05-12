use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DMTF::CIM::WSMan',
    license             => 'perl',
    dist_author         => 'Stephen James Hurd <shurd@broadcom.com>',
    dist_version_from   => 'lib/DMTF/CIM/WSMan.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'URI'        => 0,
        'URI::Escape'=> 0,
        'DMTF::WSMan'=> 0,
        'DMTF::CIM'  => 0,
        'DMTF::CIM::Instance'=> 0,
        'XML::Twig'  => 0,
        'DateTime::Duration'=> 0,
        'MIME::Base64'=> 0,
    },
    add_to_cleanup      => [ 'DMTF-CIM-WSMan-*' ],
);

$builder->create_build_script();
