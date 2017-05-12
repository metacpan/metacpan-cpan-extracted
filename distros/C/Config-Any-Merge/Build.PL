use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Config::Any::Merge',
	license             => 'perl',
	build_requires => {
		'Test::More' => 0,
		'Config::Tiny' => 0,
	},
	requires => {
		'Config::Any' => 0.15,
		'Hash::Merge' => 0,
	},
	add_to_cleanup      => [ 'Config-Any-Merge-*' ],
	create_makefile_pl  => 'traditional',
	create_readme	    => 1,
);

$builder->create_build_script();
