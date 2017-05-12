#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	build_requires => {
		'Test::Compile' => 0,
		'Test::Fatal' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
	},
	license => 'unrestricted',
	module_name => 'App::Raps2',
	requires => {
		'perl' => '5.10.0',
		'Carp' => 0,
		'Config::Tiny' => 0,
		'Crypt::CBC' => 0,
		'Crypt::Eksblowfish' => 0,
		'Crypt::Eksblowfish::Bcrypt' => 0,
		'File::BaseDir' => 0,
		'File::Path' => 2.06_05,
		'File::Slurp' => 0,
		'Getopt::Long' => 0,
		'POSIX' => 0,
		'Term::ReadLine' => 0,
	},
	script_files => 'bin/',
	sign => 1,
);
$build->create_build_script();
