use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
is_deeply(
	$obj->data,
	[],
	'Get data ([] - default).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'data' => [
		'foo',
		'bar',
	],
);
is_deeply(
	$obj->data,
	[
		'foo',
		'bar',
	],
	'Get data ([foo, bar]).',
);
