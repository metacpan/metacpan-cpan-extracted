use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::InfoBox::Item',
	{ 'also_private' => ['BUILD'] },
	'Data::InfoBox::Item is covered.');
