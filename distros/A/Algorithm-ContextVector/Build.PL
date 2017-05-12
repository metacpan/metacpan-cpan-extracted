use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::ContextVector',
    license             => 'perl',
    dist_author         => 'Antoine Imbert <antoine.imbert@gmail.com>',
    dist_version_from   => 'lib/Algorithm/ContextVector.pm',
    dist_abstract       => 'Simple implementation based on Data::CosineSimilarity',
    build_requires => {
        'Test::More' => 0,
        'Data::CosineSimilarity' => 0,
    },
    add_to_cleanup      => [ 'Algorithm-ContextVector-*' ],
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script();
