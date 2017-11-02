use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 7;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose --execmap :internal)]);

is($ret, 0, "exit 0");
like($stdout->[25], qr/^Files=3, Tests=15,\s+\d+ wallclock secs /, "Three tests found");
is($stdout->[26], "Result: PASS", "Passed");

$stdout->[25] =~ / (\d+) wallclock secs /;
my $serial_secs = $1;

($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose --execmap :internal --jobs 3)]);

is($ret, 0, "exit 0");
like($stdout->[25], qr/^Files=3, Tests=15,\s+\d+ wallclock secs /, "Three tests found");
is($stdout->[26], "Result: PASS", "Passed");

$stdout->[25] =~ / (\d+) wallclock secs /;
my $parallel_secs = $1;

ok($parallel_secs < $serial_secs, "Quicker in parallel");

done_testing();
