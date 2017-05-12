use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'DateTime::Event::WarwickUniversity',
	dist_author => 'Tim Retout <tim@retout.co.uk>',
	license => 'perl',
	requires => {
		'perl'			=> '5.8.4',
		'DateTime'		=> 0,
	},
	build_requires => {
		'Test::Exception'	=> 0,
		'Test::More'		=> 0,
		'Test::Pod'		=> 0,
		'Test::Pod::Coverage'	=> 0,
	},
);

$build->create_build_script;
