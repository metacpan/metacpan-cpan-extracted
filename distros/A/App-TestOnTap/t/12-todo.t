use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 6;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite();

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No configuration file found, using blank with generated id '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stdout->[1], qr/All tests successful/, "No failures");
like($stdout->[6], qr/TODO passed:\s+3$/, "Expected bonus pass of 3");
like($stdout->[7], qr/^Files=1, Tests=4, /, "Only one file with four tests found");
is($stdout->[8], "Result: PASS", "Passed");

done_testing();
