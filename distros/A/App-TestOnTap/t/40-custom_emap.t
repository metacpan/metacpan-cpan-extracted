use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use App::TestOnTap::_dbgvars;

use TestUtils;

use Test::More tests => 9;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^Files=0, Tests=0, /, "No tests recognized");
is($stdout->[1], "Result: NOTESTS", "Nothing tested");

$App::TestOnTap::_dbgvars::CONFIG_FILE_NAME = 'alt_config.testontap';
($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 0, "Exited with 0");
like($stdout->[9], qr/^Files=2, Tests=2, /, "Two tests recognized");
is($stdout->[10], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--execmap', "$Bin/misc/weird.execmap"]);

is($ret, 0, "Exited with 0");
like($stdout->[17], qr/^Files=4, Tests=4, /, "Four tests recognized");
is($stdout->[18], "Result: PASS", "Passed");

done_testing();
