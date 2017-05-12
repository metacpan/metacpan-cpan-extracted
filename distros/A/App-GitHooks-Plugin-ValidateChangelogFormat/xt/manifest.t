#!perl -T

use strict;
use warnings;

use Test::More;


# Load Test::CheckManifest.
my $min_version = '0.9';
eval "use Test::CheckManifest $min_version";
plan( skip_all => "Test::CheckManifest $min_version required" )
	if $@;

# Verify files against manifest.
ok_manifest(
	{
		exclude => [ '/.git/' ],
	}
);
