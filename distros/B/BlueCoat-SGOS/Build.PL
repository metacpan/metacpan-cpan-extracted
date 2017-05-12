#!/usr/bin/perl
#
#
use strict;
use Module::Build;
my $build = Module::Build->new(
	module_name       => 'BlueCoat::SGOS',
	license           => 'gpl2',
	dist_author       => 'Matthew Lange <mmlange@cpan.org>',
	dist_version_from => 'lib/BlueCoat/SGOS.pm',
	requires          => {
		'perl'                 => '5.6.0',
		'Date::Parse'          => '0',
		'Test::More'           => '0',
		'LWP::UserAgent'       => '6.00',    # requires ssl_opts
		'HTTP::Request'        => '6.00',
		'LWP::Protocol::https' => '0',
	},
	build_requires => {
		'TAP::Harness'     => '3.18',
		'Test::NoWarnings' => '1.04'
	},
	configure_requires => {'Module::Build' => 0.40},
	create_license     => 1,
	sign               => 1,
);

$build->create_build_script;

print <<TOHERE;

Build script created.  Now run the following:
    ./Build build
    ./Build test
    ./Build install
TOHERE

