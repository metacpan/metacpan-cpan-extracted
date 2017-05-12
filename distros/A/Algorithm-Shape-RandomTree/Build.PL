use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::Shape::RandomTree',
    license             => 'perl',
    dist_author         => q{Tamir Lousky <tlousky@cpan.org>},
    dist_version_from   => 'lib/Algorithm/Shape/RandomTree.pm',
    build_requires      => {
        'Test::More' => 0,
    },
    requires => {
        'Moose'                => 0,
        'namespace::autoclean' => 0,
    },
    add_to_cleanup      => [ 'Algorithm-Shape-RandomTree-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    create_license      => 1,
);

$builder->create_build_script();
