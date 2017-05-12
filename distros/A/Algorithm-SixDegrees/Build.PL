use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Algorithm::SixDegrees',
	license => 'perl',
	requires => {
		'perl'                => '5.6',
		'Test::More'          => 0,
	},
	recommends => {
		'Test::Pod'           => '1.14',
		'Test::Pod::Coverage' => '1.04',
	},
);
$build->create_build_script;
