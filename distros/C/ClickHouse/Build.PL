use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ClickHouse',
    license             => 'artistic_1',
    dist_author         => q{Ilya Rassadin <elcamlost@gmail.com>},
    dist_version_from   => 'lib/ClickHouse.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Net::HTTP'  => 6.09,
        'URI'        => 1.71,
        'Try::Tiny'  => 0.24,
    },
    add_to_cleanup     => [ 'ClickHouse-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
