{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "DateTime::TimeZone::SystemV",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Date::ISO8601" => 0,
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Date::ISO8601" => 0,
		"Params::Classify" => 0,
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
				mailto => "bug-DateTime-TimeZone-SystemV".
					"\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=".
					"DateTime-TimeZone-SystemV",
			},
			repository => {
				type => "git",
				url => "git://git.fysh.org/zefram/".
					"DateTime-TimeZone-SystemV.git",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
