use strict;
use Module::Build;

my $build = Module::Build->new(
	create_makefile_pl => 'traditional',
	license			   => 'perl',
	module_name		   => 'Config::PackageGlobal::OO',
	requires		   => {
		'Context::Handle' => '0.01',
		'Test::Exception' => 0,
		'ok'			  => 0,
	},
	create_readme => 1,
	sign		  => 1,
);
$build->create_build_script;

