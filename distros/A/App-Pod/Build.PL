use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'App::Pod',
    license             => 'artistic_2',
    dist_author         => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from   => 'lib/App/Pod.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Module::Functions' => '2.1.3',
        'Pod::Query' => '0.12',
        'Mojolicious' => '9.19',
    },
    add_to_cleanup     => [ 'App-Pod-*' ],
);

$builder->create_build_script();
