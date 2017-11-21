use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 7;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[0], qr/^Files=0, Tests=0, /, "No tests recognized");
is($stdout->[1], "Result: NOTESTS", "Nothing tested");

($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--cfg', "$Bin/misc/40-alt_config.testontap"]);

is($ret, 0, "Exited with 0");
like($stdout->[9], qr/^Files=2, Tests=2, /, "Two tests recognized");
is($stdout->[10], "Result: PASS", "Passed");

done_testing();
