use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 5;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[6], qr/^Files=1, Tests=2, /, "Only one file, two tests found");
is($stdout->[7], "Result: PASS", "Passed");

done_testing();
