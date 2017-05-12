use strict;
use Module::Build;

my $build = Module::Build->new(
	create_makefile_pl => 'traditional',
	license			   => 'perl',
	module_name		   => 'Callback::Cleanup',
	requires		   => {
		'ok' => 0,
		'Sub::Exporter' => 0,
		'Sub::Clone' => 0,
		'Hash::Util::FieldHash::Compat' => 0,
	},
	create_readme => 1,
	sign		  => 1,
);
$build->create_build_script;

