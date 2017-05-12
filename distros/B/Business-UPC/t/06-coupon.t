
use strict;
use Test;

BEGIN { plan tests => 9, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

$upc = new Business::UPC('012000000133');

# test for coupon stuff

ok($upc);
ok(! $upc->is_coupon);

$upc = new Business::UPC('512345678900');

ok($upc);
ok($upc->is_valid);
ok($upc->is_coupon);
ok($upc->number_system_description, 'Coupon');
ok($upc->coupon_value, '$0.90');
ok($upc->coupon_family_code, '678');
ok($upc->coupon_family_description, 'Unknown');

