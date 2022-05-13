use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'App::Cheats',
    license             => 'artistic_2',
    dist_author         => q{Tim Potapov <Tim.Potapov[AT]gmail.com>},
    dist_version_from   => 'lib/App/Cheats.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
         'TimTools' => '0.04',
    },
    add_to_cleanup     => [ 'App-Cheats-*' ],
);

$builder->create_build_script();
