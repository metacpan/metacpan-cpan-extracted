#!/usr/bin/perl -w

use Module::Build;
my $build = Module::Build->new(
	module_name         => 'CGI::Application::Plugin::Config::Simple',
	license             => 'perl',
	requires            => {
		    'CGI::Application'  => 3.21,
		    'Exporter'          => 0,
            'Config::Simple'    => 0,
            'Test::More'        => 0,
		},
	create_makefile_pl  => 'traditional',
	create_readme       => 1,
	);
$build->create_build_script();
