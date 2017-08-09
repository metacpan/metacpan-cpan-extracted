use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 4;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No configuration file found, using blank with generated id '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stdout->[6], qr/^Files=1, Tests=2, /, "Only one file, two tests found");
is($stdout->[7], "Result: PASS", "Passed");

done_testing();
