use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->cadastral_area, undef, 'Get cadastral area (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'cadastral_area' => 'https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/123',
);
is(
	$obj->cadastral_area,
	'https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/123',
	'Get cadastral area (https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/123)',
);
