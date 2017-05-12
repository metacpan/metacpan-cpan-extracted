use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::PlayCode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Acme/PlayCode.pm',
    requires => {
        'List::MoreUtils' => 0,
        'Path::Class' => '0.16',
        'Moose'       => '0.57',
        'MooseX::Object::Pluggable' => '0.0008',
        'PPI'         => '1.201',
    },
    build_requires => {
        'Test::More'  => 0,
    },
    add_to_cleanup      => [ 'Acme-PlayCode-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
