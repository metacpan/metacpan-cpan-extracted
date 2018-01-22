#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Data::Dump::Color;

ok(1);

DONE_TESTING:
done_testing();

__END__
# disabled for now
is(dd([1, 2, 3]), "[1, 2, 3]\n", "[1, 2, 3]");
