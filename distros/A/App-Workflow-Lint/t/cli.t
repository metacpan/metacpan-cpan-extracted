use strict;
use warnings;
use Test::Most;
use File::Temp qw/tempfile/;

my $CLI = 'bin/workflow-lint';

ok( -f $CLI, "CLI script exists" ) or plan skip_all => "CLI script not found";

ok( -r $CLI, "CLI script is readable" );
SKIP: {
	skip "Windows does not support -x", 1 if $^O eq 'MSWin32';
	ok( -x $CLI, "CLI script is executable" );
}

# Create a temporary workflow file
my ($fh, $filename) = tempfile();
print $fh <<'YAML';
name: Test Workflow
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo Hello
YAML
close $fh;

# Run the CLI
my $cmd;

if ($^O eq 'MSWin32') {
	# Windows cannot execute scripts directly
	$cmd = qq{"$^X" "$CLI" check "$filename"};
} else {
	# Unix-like systems can run the script directly
	$cmd = qq{"$CLI" check "$filename"};
}

my $output = qx{$cmd 2>&1};
my $exit   = $? >> 8;

# EXPECT: non-zero exit because warnings were found
isnt($exit, 0, "CLI exits non-zero when workflow has issues");

# EXPECT: diagnostics appear
like($output, qr/missing-permissions/i, "Output includes missing-permissions warning");
like($output, qr/missing-timeout/i,     "Output includes missing-timeout warning");
like($output, qr/missing-concurrency/i, "Output includes missing-concurrency info");

done_testing();
