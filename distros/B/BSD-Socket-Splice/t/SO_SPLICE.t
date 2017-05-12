use strict;
use warnings;
use BSD::Socket::Splice 'SO_SPLICE';

use Test::More tests => 2;

is(SO_SPLICE, 0x1023, "SO_SPLICE constant value is 0x1023");

eval { SO_SPLICE("foobar") };
like($@, qr/^Usage: BSD::Socket::Splice::SO_SPLICE\(\) /,
    "SO_SPLICE function does not take arguments");
