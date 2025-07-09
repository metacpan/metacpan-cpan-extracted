use strict;
use warnings;

use Data::CEFACT::Unit;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::CEFACT::Unit->new(
	'common_code' => 'KGM',
	'conversion_factor' => 'kg',
	'description' => 'A unit of mass equal to one thousand grams.',
	'level_category' => 1,
	'name' => 'kilogram',
	'symbol' => 'kg',
);
my $ret = $obj->conversion_factor;
is($ret, 'kg', 'Get conversion factor (kg).');
