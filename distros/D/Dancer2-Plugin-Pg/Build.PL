use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dancer2::Plugin::Pg',
    license             => 'artistic_2',
    dist_author         => q{Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>},
    dist_version_from   => 'lib/Dancer2/Plugin/Pg.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Dancer2' => 0,
        'Moo' => 0,
        'DBI' => 0
    },
    add_to_cleanup     => [ 'Dancer2-Plugin-Pg-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
