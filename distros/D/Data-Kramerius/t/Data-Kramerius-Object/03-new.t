use strict;
use warnings;

use Data::Kramerius::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Kramerius::Object->new(
	'active' => 1,
	'id' => 'foo',
	'name' => 'Kramerius foo',
	'url' => 'foo.example.com',
	'version' => 4,
);
isa_ok($obj, 'Data::Kramerius::Object');

# Test.
$obj = Data::Kramerius::Object->new(
	'active' => 0,
	'id' => 'foo',
	'name' => 'Kramerius foo',
	'url' => 'foo.example.com',
	'version' => 4,
);
isa_ok($obj, 'Data::Kramerius::Object');
