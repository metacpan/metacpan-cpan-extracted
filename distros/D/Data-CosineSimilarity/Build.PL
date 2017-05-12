use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::CosineSimilarity',
    license             => 'perl',
    dist_author         => 'Antoine Imbert <antoine.imbert@gmail.com>',
    dist_version_from   => 'lib/Data/CosineSimilarity.pm',
    dist_abstract       => 'Computes the Cosine Similarity',
    build_requires => {
        'Test::More' => 0,
        'Math::Trig' => 0,
    },
    add_to_cleanup      => [ 'Data-CosineSimilarity-*' ],
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script();
