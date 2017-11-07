use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 3;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

isnt($ret, 0, "exit not 0");
like($stderr->[0], qr/^Failure handling config in /, "failure");
like($stderr->[1], qr/^  Missing configuration /, "missing config");

done_testing();
