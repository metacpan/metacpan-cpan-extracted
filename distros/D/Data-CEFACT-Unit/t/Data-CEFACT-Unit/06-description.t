use strict;
use warnings;

use Data::CEFACT::Unit;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $desc = 'A unit of mass equal to one thousand grams.';
my $obj = Data::CEFACT::Unit->new(
	'common_code' => 'KGM',
	'conversion_factor' => 'kg',
	'description' => $desc,
	'level_category' => 1,
	'name' => 'kilogram',
	'symbol' => 'kg',
);
my $ret = $obj->description;
is($ret, $desc, 'Get description ('.$desc.').');
