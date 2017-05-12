#!/usr/bin/perl

use 5.006;
use strict;
use utf8;

use Module::Build;

eval { require 'lib/DateTime/Format/DBI.pm' };
my $db = \%DateTime::Format::DBI::_db_to_parser;

my $b = Module::Build->new(
	'module_name'	=> 'DateTime::Format::DBI',
	'license'	=> 'perl',
	'dist_author'	=> 'Claus Färber <CFAERBER@cpan.org>',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

    	'requires'	=> {
		'DateTime'	=> 0.10,
		'DBI'		=> 1.21,
	},
	'recommends'	=> {
		'Test::Database' => 0,
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},
	'no_index' => {
		'directory' => ['eg',],
	},
	'resources' => {
		'homepage' 	=> 'http://search.cpan.org/dist/DateTime-Format-DBI/',
		'repository'	=> 'https://guthub.com/cfaerber/DateTime-Format-DBI/',
		'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-DBI',
	},
);

$b->create_build_script;
