use 5.010;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Storage',
    license             => 'Artistic_2_0',
    dist_author         => q{Peter Valdemar Mørch <peter@morch.com>},
    dist_version_from   => 'lib/Class/Storage.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
    },
    test_requires => {
        'Clone' => 0,
        # Need 0.96 for Test::More's subtest()
        'Test::More' => '0.96',
    },
    requires => {
        'perl' => '5.010'
    },
    add_to_cleanup     => [ 'Class-Unbless-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
