use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Buffalo::Buffalo',
    license             => 'perl',
    dist_author         => q{Elizabeth Cholet <zrusilla@mac.com>},
    dist_version_from   => 'lib/Acme/Buffalo/Buffalo.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'Acme-Buffalo-Buffalo-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
