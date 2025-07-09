use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::CEFACT::Unit',
	{ 'also_private' => ['BUILD'] },
	'Data::CEFACT::Unit is covered.');
