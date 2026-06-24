use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Metadata',
	{ 'also_private' => ['BUILD'] },
	'Data::Metadata is covered.');
