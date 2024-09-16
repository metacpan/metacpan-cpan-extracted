use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::InfoBox::Item->new(
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
my $ret = $obj->text;
isa_ok($ret, 'Data::Text::Simple');
is($ret->text, 'Text', 'Get text (Text).');
