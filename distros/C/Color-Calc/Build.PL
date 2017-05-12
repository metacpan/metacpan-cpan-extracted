#!/usr/bin/perl

use 5.006;
use strict;
use utf8;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Color::Calc',
	'license'	=> 'perl',
	'dist_author'	=> 'Claus Faerber <CFAERBER@cpan.org>',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

    	'requires'	=> {
		'Graphics::ColorNames'	=> 2.10,
		'Graphics::ColorNames::WWW' => 0.01,
		'Graphics::ColorNames::HTML'=> 0,
		'Params::Validate'	=> 0.75,
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},

	auto_features => {
		'color_object_support' => {
			'description'	=> 'support for Color::Object (obsolete)',
			'requires'	=> {
				'Color::Object'	=> 1,
			}
		},
		'graphics_colorobject_support' => {
			'description'	=> 'support for Graphics::ColorObject',
			'requires'	=> {
				'Graphics::ColorObject'	=> 0.005,
			}
		},
	},

	'no_index' => {
		'directory' => ['eg']
	},
	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Color-Calc',
		'repository' => 'http://github.com/cfaerber/Color-Calc',
	},

);

$b->create_build_script;
