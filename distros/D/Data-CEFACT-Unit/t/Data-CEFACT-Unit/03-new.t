use strict;
use warnings;

use Data::CEFACT::Unit;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
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
isa_ok($obj, 'Data::CEFACT::Unit');

# Test.
eval {
	Data::CEFACT::Unit->new(
		'conversion_factor' => 'kg',
		'description' => 'A unit of mass equal to one thousand grams.',
		'level_category' => 1,
		'name' => 'kilogram',
		'symbol' => 'kg',
	);
};
is($EVAL_ERROR, "Parameter 'common_code' is required.\n",
	"Parameter 'common_code' is required.");
clean();
