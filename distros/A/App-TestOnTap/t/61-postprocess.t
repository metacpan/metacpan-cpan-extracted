use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 4;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--verbose)]);

isnt($ret, 0, "Exit code not 0");
like($stderr->[0], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stderr->[1], qr/^This is postprocess$/, "postprocess output");
like($stderr->[2], qr/^WARNING: exit code '42' when running postprocess command$/, "postproc exit code");

done_testing();
