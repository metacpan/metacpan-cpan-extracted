use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Person',
	{ 'also_private' => ['BUILD'] },
	'Data::Person is covered.');
