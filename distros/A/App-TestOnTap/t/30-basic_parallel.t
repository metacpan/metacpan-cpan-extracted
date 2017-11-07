use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 9;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

is($ret, 0, "exit 0");
like($stderr->[0], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[25], qr/^Files=3, Tests=15,\s+\d+ wallclock secs /, "Three tests found");
is($stdout->[26], "Result: PASS", "Passed");

$stdout->[25] =~ / (\d+) wallclock secs /;
my $serial_secs = $1;

($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose --jobs 3)]);

is($ret, 0, "exit 0");
like($stderr->[0], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[25], qr/^Files=3, Tests=15,\s+\d+ wallclock secs /, "Three tests found");
is($stdout->[26], "Result: PASS", "Passed");

$stdout->[25] =~ / (\d+) wallclock secs /;
my $parallel_secs = $1;

ok($parallel_secs < $serial_secs, "Quicker in parallel");

done_testing();
