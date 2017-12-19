use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use File::Temp qw(tempdir);

use Test::More tests => 9;

my $suitename = TestUtils::suitename_from_script();

my $tmpdir = tempdir(CLEANUP => 1);
ok(-d $tmpdir, "Created tmpdir $tmpdir");

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose', '--savedirectory', $tmpdir]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: No execmap found, using internal default!$/, "default execmap");
like($stdout->[14], qr/^Files=1, Tests=10, /, "Only one file with 10 tests found");
is($stdout->[15], "Result: PASS", "Passed");
like($stdout->[16], qr(^Result saved to '\Q$tmpdir\E[\\/]\Q$suitename\E\.\d{8}T\d{6}Z\.[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'$), "Saved to directory");

$stdout->[16] =~ m#'(\Q$tmpdir\E[\\/]\Q$suitename\E\.\d{8}T\d{6}Z\.[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'#;
my $saveddir = $1;

ok(-d $saveddir, "Savedir $saveddir exists");

my $actual_tree = TestUtils::get_tree($saveddir);
note("Saved dir tree: '$_'") foreach (@$actual_tree);

my $expected_tree = 
	[
		qw
			(
				suite/
				suite/persist
				testontap/
				testontap/env.json
				testontap/meta.json
				testontap/result/
				testontap/result/t.pl.json
				testontap/summary.json
				testontap/tap/
				testontap/tap/t.pl.tap
				testontap/testinfo.json
			)
	];

#/ just a comment to stop weird IDE scanning due to the slashes above :-)...

is_deeply($actual_tree, $expected_tree, "Saved tree contents");

done_testing();
