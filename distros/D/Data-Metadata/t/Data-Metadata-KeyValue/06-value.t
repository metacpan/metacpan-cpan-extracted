use strict;
use warnings;

use Data::Metadata::KeyValue;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata::KeyValue->new(
	'key' => 'text',
	'value' => 'This is text',
);
is($obj->value, 'This is text', 'Get value (This is text).');

# Test.
$obj = Data::Metadata::KeyValue->new(
	'key' => 'text',
);
is($obj->value, undef, 'Get value (undef - default).');
