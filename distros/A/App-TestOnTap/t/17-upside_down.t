use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use App::TestOnTap::_dbgvars;

use TestUtils;

use Test::More tests => 12;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--order', 'natural']);

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t3\.pl /, "t3 first");
like($stdout->[4], qr/^t2\.pl /, "t2 in the middle");
like($stdout->[8], qr/^t1\.pl /, "t1 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

$App::TestOnTap::_dbgvars::IGNORE_DEPENDENCIES = 1;
($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--order', 'natural']);

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t1\.pl /, "t1 first");
like($stdout->[4], qr/^t2\.pl /, "t2 in the middle");
like($stdout->[8], qr/^t3\.pl /, "t3 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

done_testing();
