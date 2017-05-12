use 5.008;
use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Class::DBI::DDL',
	license     => 'perl',
	requires    => {
		'perl'				=> '5.8',
		'Class::DBI'		=> '0.96',
	},
	recommends  => {
		'DBD::mysql'        => 0,
		'DBD::Pg'           => 0,
		'DBD::SQLite'       => 0,
	},
	create_makefile_pl => 'passthrough',
);

$build->create_build_script;
