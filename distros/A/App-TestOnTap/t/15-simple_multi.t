use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 23;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[13], qr/^Files=3, Tests=3, /, "All three found");
is($stdout->[14], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose --jobs 2)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stderr->[2], qr/^WARNING: No 'parallelizable' rule found \('--jobs 2' has no effect\); all tests will run serially!$/, "Not parallelizable");
like($stdout->[13], qr/^Files=3, Tests=3, /, "All three found");
is($stdout->[14], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--include', 'regexp(two)']);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[5], qr/^Files=1, Tests=1, /, "Only one found");
is($stdout->[6], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--skip', 'not regexp(two)']);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[5], qr/^Files=1, Tests=1, /, "Only one found");
is($stdout->[6], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--include', 'regexp(two)', '--skip', 'not regexp(two)']);

is($ret, -1, "Exited with -1");
like($stderr->[1], qr/The options --skip and --include are mutually exclusive/, "Exclusive flags");

done_testing();
