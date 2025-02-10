use strict;
use warnings;

use Data::Icon;
use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::InfoBox::Item->new(
	'icon' => Data::Icon->new(
		'url' => 'https://example.com/icon.ico',
	),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
my $ret = $obj->icon->url;
is($ret, 'https://example.com/icon.ico',
	'Get icon URL (https://example.com/icon.ico).');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon' => Data::Icon->new(
		'char' => decode_utf8('⌂'),
	),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
$ret = $obj->icon->char;
is($ret, decode_utf8('⌂'),
	'Get icon character (⌂).');
