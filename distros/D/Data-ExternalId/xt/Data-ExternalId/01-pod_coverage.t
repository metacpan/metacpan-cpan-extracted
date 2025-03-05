use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::ExternalId',
	{ 'also_private' => ['BUILD'] },
	'Data::ExternalId is covered.');
