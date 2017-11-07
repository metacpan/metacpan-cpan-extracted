use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 3;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, -1, "Exited with -1");
like($stderr->[0], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stderr->[1], qr/^ERROR: Cyclic dependency detected: t.\.pl => t.\.pl => t.\.pl!$/, "Cyclic dep");

done_testing();
