use strict;
use Module::Build;

my $build = Module::Build->new(
	create_makefile_pl => 'traditional',
	license			   => 'perl',
	module_name		   => 'Context::Handle',
	requires		   => {
		perl => '5.6.1',
		Want => '0.10',
		ok   => 0,
	},
	create_readme => 1,
	sign		  => 1,
);
$build->create_build_script;

