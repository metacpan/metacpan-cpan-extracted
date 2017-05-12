#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use CPAN::WWW::Top100::Generator ();

# Create the test directory
my $dir = catdir('t', 'site');
clear($dir);
mkdir($dir) or die "Failed to create $dir";

# Generate the site
ok(
	CPAN::WWW::Top100::Generator->new( dir => $dir )->run,
	'->run ok',
);
