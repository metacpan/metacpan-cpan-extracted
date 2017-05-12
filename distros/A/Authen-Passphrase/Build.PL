{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Authen::Passphrase",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"MIME::Base64" => "2.21",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Authen::DecHpwd" => "2.003",
		"Carp" => 0,
		"Crypt::DES" => 0,
		"Crypt::Eksblowfish::Bcrypt" => "0.008",
		"Crypt::Eksblowfish::Uklblowfish" => "0.008",
		"Crypt::MySQL" => "0.03",
		"Crypt::PasswdMD5" => "1.0",
		"Crypt::UnixCrypt_XS" => "0.08",
		"Data::Entropy::Algorithms" => 0,
		"Digest" => "1.00",
		"Digest::MD4" => "1.2",
		"Digest::MD5" => "1.9953",
		"Digest::SHA" => 0,
		"MIME::Base64" => "2.21",
		"Module::Runtime" => "0.011",
		"Params::Classify" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
