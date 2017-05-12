
# Time-stamp: "2004-12-29 22:05:02 AST"

require 5;
use strict;
use Test;
BEGIN { plan tests => 4 };
use Business::US_Amort;
ok 1;

my $payment = Business::US_Amort::simple( 123_000, 6, 5);
# First test imprecisely, to distinguish roundoff errors from plain craziness
ok $payment >= 2377.90;
ok $payment <= 2377.95;
ok $payment,   2377.93;

