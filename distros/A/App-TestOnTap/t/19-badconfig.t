use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 7;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 0, "Exited with 0");
is(@$stderr, 5, "Expecting 5 warnings");
like($stderr->[0], qr/^Unmatched 'cmd255' in section '\[EXECMAP\]'$/, "unmatched cmd255 in execmap");
like($stderr->[1], qr/^Unknown key 'invalid_execmap_key' in section '\[EXECMAP\]'$/, "unknown key in execmap");
like($stderr->[2], qr/^Unknown key 'invalid_dependency_key' in section '\[DEPENDENCY foo\]'$/, "unknown key in dependency");
like($stderr->[3], qr/^Unknown section: '\[INVALID_SECTION\]'$/, "unknown section");
like($stderr->[4], qr/^Unknown key 'invalid_key' in default section$/, "Unknown blank section key");

done_testing();
