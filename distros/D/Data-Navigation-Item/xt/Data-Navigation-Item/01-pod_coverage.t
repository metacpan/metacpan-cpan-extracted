use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Navigation::Item',
	{ 'also_private' => ['BUILD'] },
	'Data::Navigation::Item is covered.');
