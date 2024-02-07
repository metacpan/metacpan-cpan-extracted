use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
is_deeply(
	$obj->data,
	[],
	'Get data (blank array).',
);

# Test.
$obj = Data::HTML::Element::Select->new(
	'data' => ['<option>Value</option>'],
	'data_type' => 'plain',
);
is_deeply(
	$obj->data,
	['<option>Value</option>'],
	'Get data (array with one item - plain mode).',
);

# Test.
$obj = Data::HTML::Element::Select->new(
	'data' => [
		['b', 'option'],
		['d', 'Value'],
		['e', 'option'],
	],
	'data_type' => 'tags',
);
is_deeply(
	$obj->data,
	[
		['b', 'option'],
		['d', 'Value'],
		['e', 'option'],
	],
	'Get data (array with one item - tags mode).',
);
