
use strict;
use Test;

BEGIN { plan tests => 39, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

# tests for constructing with unknown check digit

$upc = new Business::UPC('01200000013x');

ok($upc);
ok(uc($upc->check_digit), 'X');
ok($upc->fix_check_digit);
ok($upc->check_digit, '3');
ok($upc->is_valid);

ok(Business::UPC->new('012000000102')->is_valid);
ok(Business::UPC->new('012000000119')->is_valid);
ok(Business::UPC->new('012000000126')->is_valid);
ok(Business::UPC->new('012000000133')->is_valid);
ok(Business::UPC->new('012000000140')->is_valid);
ok(Business::UPC->new('012000000157')->is_valid);
ok(Business::UPC->new('012000000164')->is_valid);
ok(Business::UPC->new('012000000171')->is_valid);
ok(Business::UPC->new('012000000188')->is_valid);
ok(Business::UPC->new('012000000195')->is_valid);
ok(! Business::UPC->new('012000000190')->is_valid);

ok(Business::UPC->new('012000000034')->is_valid);
ok(Business::UPC->new('012000000133')->is_valid);
ok(Business::UPC->new('012000000232')->is_valid);
ok(Business::UPC->new('012000000331')->is_valid);
ok(Business::UPC->new('012000000430')->is_valid);
ok(Business::UPC->new('012000000539')->is_valid);
ok(Business::UPC->new('012000000638')->is_valid);
ok(Business::UPC->new('012000000737')->is_valid);
ok(Business::UPC->new('012000000836')->is_valid);
ok(Business::UPC->new('012000000935')->is_valid);
ok(! Business::UPC->new('012000000930')->is_valid);

ok(Business::UPC->new('000000000017')->is_valid);
ok(Business::UPC->new('000000000109')->is_valid);
ok(Business::UPC->new('000000001007')->is_valid);
ok(Business::UPC->new('000000010009')->is_valid);
ok(Business::UPC->new('000000100007')->is_valid);
ok(Business::UPC->new('000001000009')->is_valid);
ok(Business::UPC->new('000010000007')->is_valid);
ok(Business::UPC->new('000100000009')->is_valid);
ok(Business::UPC->new('001000000007')->is_valid);
ok(Business::UPC->new('010000000009')->is_valid);
ok(Business::UPC->new('100000000007')->is_valid);
ok(Business::UPC->new('111111111117')->is_valid);

