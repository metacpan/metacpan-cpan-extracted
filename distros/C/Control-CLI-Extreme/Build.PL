#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
		module_name => 'Control::CLI::Extreme',
		license  => 'perl',
		requires => {
			'Control::CLI' 		=> 2.02,
			perl			=> '5.6.0',
		},
		build_requires => {
			'Net::Telnet'		=> 0,
			'IO::Interactive'	=> 0,
		},
		configure_requires => { 'Module::Build' => 0.36 },
		meta_merge => {
			resources => {
				repository => 'https://github.com/lgastevens/Control-CLI-Extreme',
				bugtracker => 'https://github.com/lgastevens/Control-CLI-Extreme/issues',
#				bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Control-CLI-Extreme',
			}
		},
	);
$build->create_build_script;
