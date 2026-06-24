use strict;
use warnings;

use Data::Metadata::KeyValue;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata::KeyValue->new(
	'key' => 'text',
);
is($obj->key, 'text', 'Get key (text).');
