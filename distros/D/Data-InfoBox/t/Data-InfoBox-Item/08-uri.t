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
	'uri' => 'https://example.com',
);
my $ret = $obj->uri;
is($ret, 'https://example.com',
	'Get URI (https://example.com).');
