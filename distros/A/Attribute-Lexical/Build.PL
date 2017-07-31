{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Attribute::Lexical",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Lexical::SealRequireHints" => "0.008",
		"Params::Classify" => 0,
		"constant" => 0,
		"if" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-Attribute-Lexical\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Attribute-Lexical",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
