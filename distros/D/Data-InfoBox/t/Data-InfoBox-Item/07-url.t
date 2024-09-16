use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::InfoBox::Item->new(
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'url' => 'https://example.com',
);
my $ret = $obj->url;
is($ret, 'https://example.com',
	'Get URL (https://example.com).');
