use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Data::FR::Town',
    license            => 'perl',
    dist_author        => q{Arnaud (Arhuman) ASSAD <arhuman@gmail.com>},
    dist_version_from  => 'lib/Data/FR/Town.pm',
    build_requires     => { 'Test::More' => 0, },
    requires           => { 'perl' => 5.006, },
    add_to_cleanup     => ['Data-FR-Town-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => { 
            repository => q[https://github.com/arhuman/Data-FR-Town],
            bugtracker => q[https://github.com/arhuman/Data-FR-Town/issues],
        },
    },
);

$builder->create_build_script();
