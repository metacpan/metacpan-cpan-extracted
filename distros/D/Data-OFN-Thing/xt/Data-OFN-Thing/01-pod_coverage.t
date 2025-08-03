use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::OFN::Thing',
	{ 'also_private' => ['BUILD'] },
	'Data::OFN::Thing is covered.');
