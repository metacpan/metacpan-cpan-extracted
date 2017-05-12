#!/usr/bin/perl
use lib './mylib';
use Module::Build::Yapp;
my $build = Module::Build::Yapp->new(
	module_name        => 'Config::Irssi::Parser',
	dist_version       => '0.0.4',
	dist_author        => 'Dylan William Hardison <dhardison@cpan.org>',
	dist_abstract      => 'Read Irssi-style config files',
	license            => 'perl',
	requires           => {
		'perl'            => '5.8.0',
		'Test::More'      => 0.47,
		# 'Parse::Yapp'   => 0,
	},
	create_makefile_pl => 'passthrough',
	yapp_files    => ['lib/Config/Irssi/Parser.yp'],
);

$build->create_build_script;
