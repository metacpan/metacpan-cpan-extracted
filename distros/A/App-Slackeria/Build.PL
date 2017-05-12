#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	build_requires => {
		'Module::Build' => '0.36',
		'Test::Compile' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
	},
	dist_name => 'App-Slackeria',
	dist_version_from => 'bin/slackeria',
	license => 'unrestricted',
	requires => {
		'autodie' => 0,
		'perl' => '5.10.1',
		'Carp' => 0,
		'Config::Tiny' => 0,
		'CPANPLUS' => 0,
		'File::BaseDir' => 0,
		'File::ShareDir' => 0,
		'File::Slurp' => 0,
		'HTML::Template' => 0,
		'List::Util' => 0,
		'LWP::UserAgent' => 0,
		'Net::GitHub' => 0,
		'Sort::Versions' => 0,
		'WWW::Freshmeat' => 0,
		'XML::LibXML' => 0,
	},
	script_files => 'bin/',
	share_dir => 'share',
	sign => 1,
);
$build->create_build_script();
