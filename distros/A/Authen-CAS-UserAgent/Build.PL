#!/usr/bin/perl

use strict;

use Module::Build;

Module::Build->new(
	'module_name'        => 'Authen::CAS::UserAgent',
	'create_makefile_pl' => 'traditional',
	'dist_abstract'      => 'LWP::UserAgent subclass for a CAS aware UserAgent',
	'dist_author'        => 'Daniel Frett <daniel.frett@gmail.com>',
	'license'            => 'bsd',
	'meta_merge'         => {
		'resources' => {
			'license'    => 'http://www.opensource.org/licenses/BSD-3-Clause',
			'repository' => 'https://github.com/frett/perl-Authen-CAS-UserAgent',
		},
	},
	'configure_requires' => {
		'Module::Build'  => '0.36',
	},
	'build_requires'     => {
		'Test::More'     => 0,
	},
	'requires'           => {
		'Exporter'       => 0,
		'HTTP::Message'  => 0,
		'LWP::UserAgent' => 0,
		'URI'            => 0,
		'XML::LibXML'    => 0,
	},
)->create_build_script();
