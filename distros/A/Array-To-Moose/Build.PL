use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Array::To::Moose',
    license             => 'perl',
    dist_author         => 'Sam Brain <samb@stanford.edu>',
    dist_version_from   => 'lib/Array/To/Moose.pm',
    requires => {
        'Array::GroupBy'            => 0,
        'Moose'                     => 0,
        'MooseX::StrictConstructor' => 0,
        'Params::Validate::Array'   => 0,
        'Carp'                      => 0,
        'namespace::autoclean'      => 0,
        'Test::More'                => 0,
        'Data::Dumper'              => 0,
        'version'                   => 0,
    },

    configure_requires => {
        'Module::Build' => 0.38
    },

    add_to_cleanup      => [ 'Array-To-Moose-*' ],
);

$builder->create_build_script();
