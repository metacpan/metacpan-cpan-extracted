use v5.16.2;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Machi',
    license             => 'artistic_2',
    dist_author         => q{Machi Amayadori <Eosin@Syaro.Cafe>},
    dist_version_from   => 'lib/Acme/Machi.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0.62,
    },
    requires => {
        'IO::Dir' => 1.10,
        'File::Spec' => 3.39_02,
        'File::Basename' => 2.84,
        'Data::Dumper' => 2.135_06,
        'Cwd' => 3.39_02,
        'Carp' => 1.26,
        'namespace::autoclean' => 0.28,
    },
    add_to_cleanup     => [ 'Acme-Machi-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
