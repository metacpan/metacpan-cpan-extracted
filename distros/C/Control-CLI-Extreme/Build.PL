#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
		module_name => 'Control::CLI::Extreme',
		license  => 'perl',
		requires => { 'Control::CLI' => 2.02 },
		build_requires => {
			'Net::Telnet'		=> 0,
			'IO::Interactive'	=> 0,
			perl			=> '5.6.0',
		},
		configure_requires => { 'Module::Build' => 0.36 },
	);
$build->create_build_script;

