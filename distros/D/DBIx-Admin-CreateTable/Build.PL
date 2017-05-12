use strict;
use warnings;

use Module::Build;

print "The tests in t/syntax.error.t will only by run if \$DBI_DSN, \$DBI_USER and \$DBI_PASS are defined. \n";

Module::Build -> new
(
	module_name    => 'DBIx::Admin::CreateTable',
	license        => 'artistic_2',
	dist_abstract  => 'Create and drop tables, primary indexes, and sequences',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More'    => 0,
#		'Test::Pod'     => 1.45, # Make it optional. See t/pod.t
		'Test::Version' => 1.002003,
	},
	configure_requires =>
	{
		'Module::Build' => 0.3800,
	},
	requires =>
	{
		'DBI'      => 0,
		'Moo'      => 1.004002,
		'strict'   => 0,
		'warnings' => 0,
	},
) -> create_build_script();

