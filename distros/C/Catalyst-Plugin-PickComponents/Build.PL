use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::PickComponents',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Catalyst/Plugin/PickComponents.pm',
    create_makefile_pl  => 'traditional',
    build_requires => {
        'Test::More' => 0,
        'Catalyst'   => 0,
        'MRO::Compat' => 0,
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-PickComponents-*' ],
);

$builder->create_build_script();
