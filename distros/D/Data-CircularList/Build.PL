use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::CircularList',
    license             => 'Artistic_2_0',
    dist_author         => q{shinchit <shinchi.xx@gmail.com>},
    dist_version_from   => 'lib/Data/CircularList.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp' => 1.26,
        'Class::Accessor' => 0.34,
        'Scalar::Util' => 1.23,
    },
    add_to_cleanup     => [ 'Data-CircularList-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
