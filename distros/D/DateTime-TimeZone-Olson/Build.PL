{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "DateTime::TimeZone::Olson",
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
		"DateTime::TimeZone::Tzfile" => "0.010",
		"Time::OlsonTZ::Data" => "0.201012",
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-DateTime-TimeZone-Olson".
					"\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=".
					"DateTime-TimeZone-Olson",
			},
			repository => {
				type => "git",
				url => "git://git.fysh.org/zefram/".
					"DateTime-TimeZone-Olson.git",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
