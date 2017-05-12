# Safe Perl
use strict;
use autodie;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'BoutrosLab-TSVStream',
    license             => 'perl',
    dist_author         => ['John Macdonald  <John.Macdonald@oicr.on.ca>'],

    dist_version_from   => 'lib/BoutrosLab/TSVStream.pm',
    dist_abstract       => 'An object oriented mechanism for tab separated columnar files.',

    # Modules required to build this module
    configure_requires => {
		'Module::Build' => 0.42,
    },

    build_requires => {
        'Test::More'    => '0.10',
    },

    # Modules required to use this module
    requires => {
		'List::MoreUtils' => '0.33',
		'Module::Build' => '0.421',
		'Moose' => '2.1208',
		'Moose::Role' => '2.1208',
		'Moose::Util' => '2.1403',
		'Moose::Util::TypeConstraints' => '2.1208',
		'MooseX::ClassAttribute' => '0.27',
		'MooseX::Types' => '0.45',
		'MooseX::Types::Moose' => '0.45',
		'Try::Tiny' => '0.22',
    }
);

$builder->create_build_script();
