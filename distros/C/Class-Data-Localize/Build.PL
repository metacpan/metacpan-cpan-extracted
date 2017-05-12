use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Data::Localize',
    license             => 'perl',
    dist_author         => 'Sebastian Knapp <sk@computer-leipzig.com>',
    dist_version        => '0.0401',
    dist_abstract       => 
      'Localizable, inheritable, overridable class data',
    requires => {
        'perl'          => '5.6.0',
        'ReleaseAction' => '0.07'   
	},
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Class-Data-Localize-*' ],
	create_makefile_pl  => 'traditional', 
);

$builder->create_build_script();
