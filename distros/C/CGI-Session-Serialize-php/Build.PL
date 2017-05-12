use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name		=> 'CGI::Session::Serialize::php',
	license			=> 'bsd',
	dist_abstract	=> 'CGI::Session::Serialize::php - PHP serializer for CGI::Session',
	dist_author		=> 'Ian McWilliam <kaosagnt@gmail.com>',
	configure_requires => { 'Module::Build' => 0.38 },
	build_requires => {
		'Test::More' => 0,
		'Test::Pod'  => 0
	},
	requires => {
		'CGI::Session' => 0,
		'PHP::Session' => 0
	},
	no_index => {
		'package' => [
        ],
	}
);

$build->create_build_script();