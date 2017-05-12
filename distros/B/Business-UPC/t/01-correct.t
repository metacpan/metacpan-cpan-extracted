
use strict;
use Test;

BEGIN { plan tests => 6, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

# some tests with a complete, correct UPC
$upc = new Business::UPC('012345678905');

ok($upc);
ok($upc->is_valid);
ok($upc->number_system, '0');
ok($upc->mfr_id, '12345');
ok($upc->prod_id, '67890');
ok($upc->check_digit, '5');

