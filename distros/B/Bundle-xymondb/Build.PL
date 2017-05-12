use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bundle::xymondb',
    license             => 'perl',
    dist_author         => q{David Peters <davidp@electronf.com>},
    dist_abstract      => q{Bundle of requires for xymondb},
    dist_version_from   => 'lib/Bundle/xymondb.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Bundle-xymondb-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
