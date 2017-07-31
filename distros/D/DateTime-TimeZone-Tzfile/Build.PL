{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "DateTime::TimeZone::Tzfile",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Date::ISO8601" => 0,
		"IO::File" => "1.13",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Date::ISO8601" => 0,
		"DateTime::TimeZone::SystemV" => "0.009",
		"IO::File" => "1.13",
		"IO::Handle" => "1.08",
		"Params::Classify" => 0,
		"integer" => 0,
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
				mailto => "bug-DateTime-TimeZone-Tzfile".
					"\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=".
					"DateTime-TimeZone-Tzfile",
			},
			repository => {
				type => "git",
				url => "git://git.fysh.org/zefram/".
					"DateTime-TimeZone-Tzfile.git",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
