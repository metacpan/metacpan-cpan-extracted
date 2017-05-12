#!perl -T

use strict;
use warnings;

use Test::More;


# Load Test::Dist::VersionSync.
my $min_version = '1.0.0';
eval "use Test::Dist::VersionSync $min_version";
plan( skip_all => "Test::Dist::VersionSync $min_version required." )
	if $@;

# Check that all the module versions in the distribution are the same.
Test::Dist::VersionSync::ok_versions();
