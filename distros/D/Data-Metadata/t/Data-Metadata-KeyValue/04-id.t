use strict;
use warnings;

use Data::Metadata::KeyValue;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata::KeyValue->new(
	'id' => 7,
	'key' => 'text',
);
is($obj->id, 7, 'Get id (7).');

# Test.
$obj = Data::Metadata::KeyValue->new(
	'key' => 'text',
);
is($obj->id, undef, 'Get id (undef - default).');
