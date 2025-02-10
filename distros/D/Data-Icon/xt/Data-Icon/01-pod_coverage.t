use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Icon',
	{ 'also_private' => ['BUILD'] },
	'Data::Icon is covered.');
