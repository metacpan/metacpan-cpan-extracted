use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::ALEXEY::Utils',
    license             => 'artistic_2',
    dist_author         => q{Alexey Morar  <alexeymorar0@gmail.com >},
    dist_version_from   => 'lib/Acme/ALEXEY/Utils.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Exporter'              => 0,
    },
    add_to_cleanup     => [ 'Acme-ALEXEY-Utils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
