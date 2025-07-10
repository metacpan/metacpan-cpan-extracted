use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::OFN::Common::Quantity',
	{ 'also_private' => ['BUILD'] },
	'Data::OFN::Common::Quantity is covered.');
