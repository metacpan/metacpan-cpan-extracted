use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::MARC::Leader',
	{ 'also_private' => ['BUILD'] },
	'Data::MARC::Leader is covered.');
