use strict;

use Test::More tests => 2;

use Acme::Math::XS::LeanDist;

is(add(3, -5), -2);
is(subtract(1000, 412), 588);
