#!perl -T

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Only authors test POD coverage
plan skip_all => 'set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::Pod::Coverage' => '1.08';
test_requires 'Pod::Coverage'       => '0.18';

# Add this here to fool the Kwalitee for the time being
eval { require Test::Pod::Coverage; };

# Test the POD, except for Moose privates
all_pod_coverage_ok({
	'also_private' => [qw(BUILD DEMOLISH)],
});

