use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::OFN::Address',
	{ 'also_private' => ['BUILD'] },
	'Data::OFN::Address is covered.');
