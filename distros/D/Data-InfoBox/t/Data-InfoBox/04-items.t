use strict;
use warnings;

use Data::InfoBox;
use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::InfoBox->new(
	'items' => [
		Data::InfoBox::Item->new(
			'text' => Data::Text::Simple->new(
				'text' => 'foo',
			),
		),
	],
);
my $ret_ar = $obj->items;
is(@{$ret_ar}, 1, 'Get number of items (1).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->text->text, 'foo', 'Get text of first item (foo).');
