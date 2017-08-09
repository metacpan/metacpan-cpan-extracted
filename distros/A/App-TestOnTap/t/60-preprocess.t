use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 3;

my $now = time();
my $now1 = $now+1;
my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose'], [$now]);

is($ret, 0, "Exited with 0");
like($stdout->[2], qr/^ok 1 - present in env: TESTONTAP_PREPROCESS_TEST_\Q$now\E$/, "saw preproc var");
like($stdout->[3], qr/^ok 2 - present in argv: \Q$now1\E$/, "saw preproc arg");

done_testing();
