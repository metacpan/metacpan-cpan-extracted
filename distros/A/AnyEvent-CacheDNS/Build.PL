#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;
use File::Spec::Functions;


my %requires = (
	perl        => '5.6.1',
	'AnyEvent'  => 0,
);

my %configure_requires = (
	'File::Spec::Functions' => 0,
);

my $url_resources = 'http://github.com/potyl/perl-AnyEvent-CacheDNS';
my $build = Module::Build->new(
	module_name       => 'AnyEvent::CacheDNS',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('lib', 'AnyEvent', 'CacheDNS.pm'),

	# Dependencies
	requires => \%requires,

	configure_requires => \%configure_requires,

	build_requires => {
		%configure_requires,
		'Test::More' => 0
	},

	meta_merge => {
		resources => {
			homepage   => $url_resources,
			bugtracker => "$url_resources/issues",
			repository => $url_resources,
		},
	},
);


$build->create_build_script();
