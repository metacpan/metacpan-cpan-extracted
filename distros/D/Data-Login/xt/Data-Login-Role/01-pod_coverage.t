use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Login::Role',
	{ 'also_private' => ['BUILD'] },
	'Data::Login::Role is covered.');
