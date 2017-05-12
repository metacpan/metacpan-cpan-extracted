{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Data::Entropy",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Crypt::Rijndael" => 0,
		"Data::Float" => "0.008",
		"IO::File" => "1.03",
		"Module::Build" => 0,
		"Test::More" => 0,
		"constant" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Crypt::Rijndael" => 0,
		"Data::Float" => "0.008",
		"Errno" => "1.00",
		"Exporter" => 0,
		"HTTP::Lite" => "2.2",
		"IO::File" => "1.03",
		"Params::Classify" => 0,
		"constant" => 0,
		"integer" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	conflicts => {
		"Math::BigInt" => "< 1.60",
		"Math::BigRat" => "< 0.04",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
