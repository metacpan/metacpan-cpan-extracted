# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Array-Frugal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_# print';

use Test;
BEGIN { plan tests => 46 };
use Array::Frugal;
ok(1); # If we made it this far, we're ok.


# we have at this time: new PUSH STORE FETCH DELETE


ok($n = new Array::Frugal);

# print STDERR "@$n\n";
ok($i = $n->PUSH(20));
# print STDERR "@$n\n";
ok($j = $n->PUSH(21));
# print STDERR "@$n\n";
ok($k = $n->PUSH(22));
# print STDERR "@$n\n";
ok($l = $n->PUSH(23));
# print STDERR "@$n\n";
ok($m = $n->PUSH(24));
# print STDERR "@$n\n";
ok($o = $n->PUSH(25));
# print STDERR "@$n\n";
ok($p = $n->PUSH(26));
# print STDERR "@$n\n";
ok($q = $n->PUSH(27));
# print STDERR "@$n\n";
ok($r = $n->PUSH(28));
# print STDERR "@$n\n";
ok($s = $n->PUSH(29));
# print STDERR "@$n\n";
ok($t = $n->PUSH(30));
# print STDERR "@$n\n";
ok($u = $n->PUSH(31));
# print STDERR "@$n\n";


ok( $n->FETCH($i) == 20);
ok( $n->FETCH($j) == 21);
ok( $n->FETCH($k) == 22);
ok( $n->FETCH($l) == 23);
ok( $n->STORE($m,44));
# print STDERR "@$n\n";

ok( $n->FETCH($o) == 25);
ok( $n->FETCH($p) == 26);
ok( $n->FETCH($q) == 27);
ok( $n->FETCH($r) == 28);
ok( $n->FETCH($s) == 29);
ok( $n->FETCH($t) == 30);
ok( $n->FETCH($u) == 31);

ok( $n->DELETE($p) == 26);
# print STDERR "@$n\n";
ok( $n->DELETE($l) == 23);
# print STDERR "@$n\n";
ok( $n->DELETE($m) == 44);
# print STDERR "@$n\n";
ok( $n->DELETE($q) == 27);
# print STDERR "@$n\n";
ok( $n->DELETE($r) == 28);
# print STDERR "@$n\n";
ok( $n->DELETE($s) == 29);
# print STDERR "@$n\n";
ok( $n->DELETE($t) == 30);
# print STDERR "@$n\n";
ok( $n->DELETE($u) == 31);
# print STDERR "@$n\n";
ok( $n->DELETE($o) == 25);
# print STDERR "@$n\n";
ok( $n->DELETE($i) == 20);
# print STDERR "@$n\n";
ok( $n->DELETE($j) == 21);
# print STDERR "@$n\n";
ok( $n->DELETE($k) == 22);
# print STDERR "@$n\n";

ok($i = $n->PUSH(20));
# print STDERR "@$n\n";
ok($j = $n->PUSH(21));
# print STDERR "@$n\n";
ok($k = $n->PUSH(22));
# print STDERR "@$n\n";
ok($l = $n->PUSH(23));
# print STDERR "@$n\n";
ok( $n->FETCH($i) == 20);
ok( $n->FETCH($j) == 21);
ok( $n->FETCH($k) == 22);
ok( $n->FETCH($l) == 23);




