use strict;
use warnings;

use Data::HTML::Element::A;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::A->new;
is_deeply(
	$obj->data,
	[],
	'Get data (blank array).',
);

# Test.
$obj = Data::HTML::Element::A->new(
	'data' => ['simple button'],
	'data_type' => 'plain',
);
is_deeply(
	$obj->data,
	['simple button'],
	'Get data (array with one item - plain mode).',
);

# Test.
$obj = Data::HTML::Element::A->new(
	'data' => [['d', 'simple button']],
	'data_type' => 'tags',
);
is_deeply(
	$obj->data,
	[
		['d', 'simple button'],
	],
	'Get data (array with one item - tags mode).',
);
