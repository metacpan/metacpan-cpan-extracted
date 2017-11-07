use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 7;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[3], qr/^ok 2 # skip broken$/, "Expected skip in 2");
like($stdout->[4], qr/^ok 3 # skip broken$/, "Expected skip in 3");
like($stdout->[8], qr/^Files=1, Tests=4, /, "Only one file with four tests found");
is($stdout->[9], "Result: PASS", "Passed");

done_testing();
