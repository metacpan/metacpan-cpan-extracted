use strict;
use warnings;

use Data::Kramerius::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Kramerius::Object->new(
	'id' => 'foo',
	'name' => 'Kramerius foo',
	'url' => 'foo.example.com',
	'version' => 4,
);
isa_ok($obj, 'Data::Kramerius::Object');
