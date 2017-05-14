use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::Oxbench::Util',
    license             => 'gpl',
    dist_author         => q{Tom Walsh <walshtp@gmail.com>},
    dist_version        => '0.01',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Bio-Oxbench-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
