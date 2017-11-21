use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 6;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 0, "Exited with 0");
is(@$stderr, 4, "Expecting 4 warnings");
like($stderr->[0], qr/^WARNING: Unknown key 'invalid_execmap_key' in execmap section 'plfiles'$/, "unknown key in execmap");
like($stderr->[1], qr/^WARNING: Unknown key 'invalid_dependency_key' in section '\[DEPENDENCY foo\]'$/, "unknown key in dependency");
like($stderr->[2], qr/^WARNING: Unknown section: '\[INVALID_SECTION\]'$/, "unknown section");
like($stderr->[3], qr/^WARNING: Unknown key 'invalid_key' in default section$/, "Unknown blank section key");

done_testing();
