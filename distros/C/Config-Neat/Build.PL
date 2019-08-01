use 5.010_001;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name              => 'Config::Neat',
    license                  => 'perl',
    dist_author              => 'Igor Afanasyev <igor.afanasyev@gmail.com>',
    dist_version_from        => 'lib/Config/Neat.pm',
    release_status           => 'stable',
    configure_requires       => {
        'Module::Build'      => 0,
    },
    build_requires           => {
        'Test::More'         => '0.94',
    },
    requires => {
        'Tie::IxHash'        => '1.22',
        'JSON'               => 0,
    },
    add_to_cleanup           => ['Config-Neat-*', 'Makefile.PL', 'MYMETA.*', 'META.*', 'MANIFEST.bak', 'MANIFEST'],
    create_makefile_pl       => 'traditional',
    meta_merge               => {
        resources            => {
            repository       => 'https://github.com/iafan/Config-Neat',
        },
    },
);

$builder->create_build_script();
