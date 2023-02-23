#!perl
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Acme::EdError',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Acme/EdError.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    sign               => 1,
    add_to_cleanup     => ['Acme-EdError-*'],
    test_requires      => {
        'Test2::Tools::Command' => '0.20',
        'Test2::V0'             => '0.000060',
    },
    auto_features => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://thrig.me/src/Acme-EdError.git' } },
);

$builder->create_build_script();
