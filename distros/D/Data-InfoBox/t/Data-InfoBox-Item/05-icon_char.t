use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::InfoBox::Item->new(
	'icon_char' => decode_utf8('⌂'),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
my $ret = $obj->icon_char;
is($ret, decode_utf8('⌂'),
	'Get icon character (⌂).');
