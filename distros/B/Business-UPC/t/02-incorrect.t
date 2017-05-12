
use strict;
use Test;

BEGIN { plan tests => 6, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

# some tests with a complete, incorrect upc
$upc = new Business::UPC('012345678900');

ok($upc);
ok(! $upc->is_valid);
ok($upc->check_digit, '0');
ok($upc->fix_check_digit);
ok($upc->is_valid);
ok($upc->check_digit, '5');

