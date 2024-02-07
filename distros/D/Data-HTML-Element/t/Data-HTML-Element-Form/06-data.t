use strict;
use warnings;

use Data::HTML::Element::Form;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Form->new;
is_deeply(
	$obj->data,
	[],
	'Get data (blank array).',
);

# Test.
$obj = Data::HTML::Element::Form->new(
	'data' => ['text'],
	'data_type' => 'plain',
);
is_deeply(
	$obj->data,
	['text'],
	'Get data (array with one item - plain mode).',
);

# Test.
$obj = Data::HTML::Element::Form->new(
	'data' => [
		['d', 'text'],
	],
	'data_type' => 'tags',
);
is_deeply(
	$obj->data,
	[
		['d', 'text'],
	],
	'Get data (array with one item - tags mode).',
);
