use strict;
use warnings;

use Data::Kramerius::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Kramerius::Object->new(
	'active' => 1,
	'id' => 'foo',
	'name' => 'Kramerius foo',
	'url' => 'foo.example.com',
	'version' => 4,
);
my $ret = $obj->active;
is($ret, 1, 'Get active value (1).');
