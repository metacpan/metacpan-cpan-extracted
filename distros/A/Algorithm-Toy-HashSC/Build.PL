#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Algorithm::Toy::HashSC',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Algorithm/Toy/HashSC.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test2::V0'     => '0.000060', },
    requires           => {
        'Carp'             => 0,
        'Moo'              => 0,
        'Scalar::Util'     => 0,
        'namespace::clean' => 0,
        'perl'             => '5.14.0',
    },
    sign           => 1,
    add_to_cleanup => ['Algorithm-Toy-HashSC-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/Algorithm-Toy-HashSC.git' }
    },
);

$builder->create_build_script();
