use 5.006;
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
		"Crypt::SysRandom" => 0,
		"Crypt::UnixCrypt_XS" => "0.08",
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
	meta_merge => {
		x_deprecated => 1,
		"meta-spec" => {
			"version" => 2,
		},
		resources => {
			repository => {
				type => "git",
				web => "https://github.com/Leont/authen-passphrase",
			},
		},
	},
)->create_build_script;

1;
