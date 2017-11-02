use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 9;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--execmap :internal --no-harness)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No configuration file found, using blank with generated id '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stdout->[0], qr/^#+$/, "top delimiter");
like($stdout->[1], qr/^Run test 'normal.pl' using:$/, "info");
like($stdout->[4], qr/^-+$/, "bottom delimiter");
like($stdout->[5], qr/^1..2$/, "plan");
like($stdout->[6], qr/^ok 1 - yes, one equals one$/, "test 1");
like($stdout->[7], qr/^# note$/, "note");
like($stdout->[8], qr/^ok 2 - yes, two equals two$/, "test 2");

done_testing();
