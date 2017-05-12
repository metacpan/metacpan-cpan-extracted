#!perl -T

use strict;
use warnings;

use Test::More;


# Load Test::Pod.
my $min_version = '1.22';
eval "use Test::Pod $min_version";
plan( skip_all => "Test::Pod $min_version required." )
	if $@;

# Check POD.
all_pod_files_ok();
