use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Structure::Compare',
    license             => 'perl',
    dist_author         => q{Micheal Song <perlvim@gmail.com>},
    dist_version_from   => 'lib/Data/Structure/Compare.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Data-Structure-Compare-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
