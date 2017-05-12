use strict;
use warnings;

use Test::More tests => 6;

use Acme::Iota;
use constant {
    A => iota(ord('A')),
    B => iota,
    C => iota,
};

my ($two, $four, $six) = map { 2 * $_ } iota(1), iota, iota;

ok A == ord('A');
ok B == ord('B');
ok C == ord('C');

ok $two  == 2;
ok $four == 4;
ok $six  == 6;
