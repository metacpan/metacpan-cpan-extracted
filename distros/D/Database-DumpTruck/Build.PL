use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Database::DumpTruck',
	license => 'perl',
	dist_author => 'Lubomir Rintel <lkundrak@v3.sk>',
	meta_merge => {
		resources => {
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Database-DumpTruck',
			repository => 'https://github.com/lkundrak/perl-database-dumptruck',
		}
	},
	configure_requires => {
		'Module::Build' => 0,
	},
	requires => {
		'B' => 0,
		'JSON' => 0,
		'DBI' => 0,
		'DBD::SQLite' => 0,
	},
	build_requires => {
		'Test::Pod' => '1.00',
		'Test::More' => 0,
		'Test::Exception' => 0,
		'File::Temp' => 0,
	},
);

$build->create_build_script;
