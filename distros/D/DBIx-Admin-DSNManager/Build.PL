use strict;
use warnings;

use Module::Build;

Module::Build -> new
(
	module_name    => 'DBIx::Admin::DSNManager',
	license        => 'artistic_2',
	dist_abstract  => 'Manage a file of DSNs, for both testing and production',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More'    => 0.96,
#		'Test::Pod'     => 1.45, # Make it optional. See t/pod.t
		'Test::Version' => 1.002003,
	},
	configure_requires =>
	{
 		'Module::Build' => 0.3800,
	},
	requires =>
	{
		'Config::Tiny' => 2.12,
		'File::Slurp'  => 9999.13,
		'File::Spec'   => 3.31,
		'File::Temp'   => 0.22,
		'Moo'          => 1.004002,
		'Try::Tiny'    => 0.06,
		'strict'       => 0,
		'warnings'     => 0,
	},
) -> create_build_script();
