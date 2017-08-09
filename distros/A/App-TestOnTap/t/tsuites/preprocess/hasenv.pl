use strict;
use warnings;

use Test::More tests => 2;

my $now = $ARGV[0];
ok(exists($ENV{"TESTONTAP_PREPROCESS_TEST_$now"}), "present in env: TESTONTAP_PREPROCESS_TEST_$now");

my $now1 = $now+1;
ok(grep(/^\Q$now1\E$/, @ARGV), "present in argv: $now1");

done_testing();
