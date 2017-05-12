{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "App::olson",
	dist_version => "0.000",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Date::ISO8601" => 0,
		"DateTime::TimeZone::Olson" => "0.003",
		"DateTime::TimeZone::SystemV" => "0.002",
		"DateTime::TimeZone::Tzfile" => "0.007",
		"Getopt::Std" => "1.02",
		"Params::Classify" => 0,
		"Time::OlsonTZ::Data" => "0.201012",
		"Time::Unix" => "1.02",
		"integer" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "script" },
	meta_merge => {
		resources => {
			repository => "git://lake.fysh.org/zefram/App-olson.git",
		},
	},
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
