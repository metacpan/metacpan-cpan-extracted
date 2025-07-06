use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->momc, undef, 'Get momc (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'momc' => 'https://linked.cuzk.cz/resource/ruian/momc/556904',
);
is($obj->momc, 'https://linked.cuzk.cz/resource/ruian/momc/556904',
	'Get momc (https://linked.cuzk.cz/resource/ruian/momc/556904).');
