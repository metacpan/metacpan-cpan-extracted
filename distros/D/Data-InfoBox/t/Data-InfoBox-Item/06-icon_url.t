use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::InfoBox::Item->new(
	'icon_url' => 'https://example.com/icon.ico',
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
my $ret = $obj->icon_url;
is($ret, 'https://example.com/icon.ico',
	'Get icon URL (https://example.com/icon.ico).');
