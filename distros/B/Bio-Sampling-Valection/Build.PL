use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio-Sampling-Valection',
    license             => 'perl',
    dist_author         => [
    	'Chris Cooper <chris.cooper@oicr.on.ca>',
    	'Paul C. Boutros <paul.boutros@oicr.on.ca>'
    	],

    dist_version_from   => 'lib/Bio/Sampling/Valection.pm',
    dist_abstract       => 'A perl wrapper to allow use of the Boutros Lab valection C library for selecting verification candidates from competing tools (i.e. mutation callers) or parameterizations.',
    configure_requires => {
        'Module::Build'                  => 0,
    },
    build_requires => {
        'Module::Build'                  => 0,
    },
);

$builder->create_build_script();
