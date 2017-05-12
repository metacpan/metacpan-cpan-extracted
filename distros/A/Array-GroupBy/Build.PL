use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Array::GroupBy',
    license             => 'perl',
    dist_author         => 'Sam Brain <samb@stanford.edu>',
    dist_version_from   => 'lib/Array/GroupBy.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'List::Util' => 1.23,
        'Params::Validate' => 1.0,
        'Carp'       => 1.25,
    },
    configure_requires => {
        'Module::Build' => 0.38
    },
    add_to_cleanup      => [ 'Array-GroupBy-*' ],
);

$builder->create_build_script();
