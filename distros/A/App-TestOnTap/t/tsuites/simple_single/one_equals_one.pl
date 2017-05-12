use strict;
use warnings;

use Test::More tests => 2;

ok(1 == 1, "yes, one equals one");

ok(exists($ENV{TESTONTAP_SUITE_DIR}), "present: TESTONTAP_SUITE_DIR");

done_testing();
