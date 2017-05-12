use warnings;
use strict;

use Module::Build;

Module::Build -> new
(
	module_name    => 'Data::Session',
	license        => 'artistic_2',
	dist_abstract  => 'Persistent session data management',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Config::Tiny' => 2.14,
		'DBIx::Admin::CreateTable' => 2.07,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
	},
	configure_requires =>
	{
		'Module::Build' => 0.4211,
	},
	requires =>
	{
		'autovivification' => 0,
		'CGI' => 3.63,
		'Class::Load' => 0.19,
		'Config::Tiny' => 2.14,
		'Data::Dumper' => 2.145,
		'Data::UUID' => 1.218,
		'DBD::SQLite' => 1.39,
		'DBI' => 1.627,
		'DBIx::Admin::CreateTable' => 2.07,
		'Digest::MD5' => 2.52,
		'Digest::SHA' => 5.84,
		'Fcntl' => 1.06,
		'File::Basename' => 2.77,
		'File::Path' => 2.07,
		'File::Slurp' => 9999.19,
		'File::Spec' => 3.30,
		'File::Temp' => 0.22,
		'FreezeThaw' => 0.5001,
		'Hash::FieldHash' => 0.14,
		'JSON' => 2.59,
		'overload' => 0,
		'parent' => 0,
		'Safe' => 2.35,
		'Scalar::Util' => 1.27,
		'Storable' => 2.39,
		'strict' => 0,
		'Try::Tiny' => 0.12,
		'vars' => 0,
		'warnings' => 0,
		'YAML::Tiny' => 1.51,
	},
) -> create_build_script();
