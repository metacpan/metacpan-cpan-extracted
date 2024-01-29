use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::HTML::Element::Form',
	{ 'also_private' => ['BUILD'] },
	'Data::HTML::Element::Form is covered.');
