use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::HTML::Element::A',
	{ 'also_private' => ['BUILD'] },
	'Data::HTML::Element::A is covered.');
