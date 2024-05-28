use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::Message::Board',
	{ 'also_private' => ['BUILD'] },
	'Data::Message::Board is covered.');
