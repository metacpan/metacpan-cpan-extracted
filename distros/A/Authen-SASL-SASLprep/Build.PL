#!/usr/bin/perl

use utf8;
use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Authen::SASL::SASLprep',
	'license'	=> 'perl',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires' 	=> {
		'perl'	=> 5.006,
		'Unicode::Stringprep'	=> 1.00,
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},

	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Authen-SASL-SASLprep',
		'repository' => 'http://github.com/cfaerber/Authen-SASL-SASLprep',
	},
);

$b->create_build_script;
