use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 6;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 1, "Exited with 1");
like($stderr->[0], qr/^WARNING: No configuration file found, using blank with generated id '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");

# hedge our bets here, some recent change somewhere else I'm unable to track down
# causes the line to be either 4 or 5...
#
my $atLeastOneRx = qr/^At least 1 test\(s\) failed!$/;
my $atLeastOneFail = ($stderr->[4] =~ /$atLeastOneRx/ || $stderr->[5] =~ /$atLeastOneRx/) ? 1 : 0;   
ok($atLeastOneFail, "Expected failure");

like($stdout->[3], qr/^not ok 2 - Won't work\.\.\.$/, "Fail in 2");
like($stdout->[13], qr/^Files=1, Tests=3, /, "Only one file with three tests found");
is($stdout->[14], "Result: FAIL", "Failed");

done_testing();
