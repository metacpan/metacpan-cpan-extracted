use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 5;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "exit 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "generate id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[0], qr/^Files=0, Tests=0, /, "nothing found");
is($stdout->[1], "Result: NOTESTS", "No tests run");

done_testing();
