{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Data::ID::Maildir",
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
		"Exporter" => 0,
		"Sys::Hostname" => 0,
		"Time::HiRes" => "1.00",
		"parent" => 0,
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
				mailto => "bug-Data-ID-Maildir\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Data-ID-Maildir",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
