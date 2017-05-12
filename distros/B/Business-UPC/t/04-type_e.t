
use strict;
use Test;

BEGIN { plan tests => 25, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

# some tests with a complete type-e upc

$upc = type_e Business::UPC('01201303');

ok($upc);
ok($upc->is_valid);
ok($upc->as_upc, '012000000133');
ok($upc->number_system, '0');
ok($upc->mfr_id, '12000');
ok($upc->prod_id, '00013');
ok($upc->check_digit, '3');

# some tests with an incomplete type-e upc

$upc = type_e Business::UPC('1201303');

ok($upc);
ok($upc->is_valid);
ok($upc->as_upc, '012000000133');
ok($upc->number_system, '0');
ok($upc->mfr_id, '12000');
ok($upc->prod_id, '00013');
ok($upc->check_digit, '3');

ok(Business::UPC->type_e('01201303')->is_valid);
ok(Business::UPC->type_e('01201312')->is_valid);
ok(Business::UPC->type_e('01201321')->is_valid);
ok(Business::UPC->type_e('01201333')->is_valid);
ok(Business::UPC->type_e('01201341')->is_valid);
ok(Business::UPC->type_e('01201352')->is_valid);
ok(Business::UPC->type_e('01201369')->is_valid);
ok(Business::UPC->type_e('01201376')->is_valid);
ok(Business::UPC->type_e('01201383')->is_valid);
ok(Business::UPC->type_e('01201390')->is_valid);
ok(! Business::UPC->type_e('01201393')->is_valid);

