use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Compress::WithExclusions',
    license             => 'perl',
    dist_author         => q{Jody Clements <cpan@jodyclements.com>},
    dist_version_from   => 'lib/Catalyst/Plugin/Compress/WithExclusions.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
        'Catalyst::Plugin::Compress' => '0.005',
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-Compress-WithExclusions-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
