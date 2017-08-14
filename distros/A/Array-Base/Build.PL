{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Array::Base",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"ExtUtils::CBuilder" => "0.15",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Lexical::SealRequireHints" => "0.008",
		"XSLoader" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	conflicts => {
		"B::Hooks::OP::Check" => "< 0.19",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-Array-Base\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Array-Base",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
