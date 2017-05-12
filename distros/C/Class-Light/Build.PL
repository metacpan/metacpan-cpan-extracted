use strict;
use Module::Build;

Module::Build->new(
	create_makefile_pl => 'traditional',
	module_name        => "Class::Light",
	license            => 'perl',
	build_requires     => {
		'Test::More' => 0,
	},
)->create_build_script;

