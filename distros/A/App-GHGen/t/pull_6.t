#!/usr/bin/env perl

# Regression test for https://github.com/nigelhorne/App-GHGen/pull/6
#
# Bug: "\$savings->{cost}/month" in bin/ghgen escaped the $ so the hash
# dereference was never interpolated.  The output read literally
# "$savings->{cost}/month" instead of e.g. "$0.60/month".
#
# Fix: "\$$savings->{cost}/month" — \$ gives a literal $ then
# $savings->{cost} is interpolated normally.

use v5.36;
use Test::Most;
use Path::Tiny;
use IPC::Run3;

use_ok('App::GHGen::CostEstimator', qw(estimate_savings));

# ── Unit: estimate_savings returns a numeric cost ──────────────────────────

subtest 'estimate_savings cost field is a formatted decimal' => sub {
	my @issues = (
		{ type => 'performance', severity => 'warning', message => 'No dependency caching found' },
		{ type => 'cost', severity => 'warning', message => 'No concurrency group defined' },
	);
	my $savings = estimate_savings(\@issues);

	ok(defined $savings->{cost}, 'cost key is present');
	like($savings->{cost}, qr/^\d+\.\d{2}$/, 'cost is a formatted decimal (e.g. "0.60")');
};

# ── Unit: the fixed interpolation produces a $ + digits string ─────────────

subtest 'fixed string interpolation yields dollar amount not literal variable' => sub {
	my @issues = (
		{ type => 'performance', severity => 'warning', message => 'No dependency caching found' },
	);
	my $savings = estimate_savings(\@issues);

	# Reproduce what bin/ghgen now does after the fix
	my $display = "\$$savings->{cost}/month";

	like($display, qr/^\$\d+\.\d{2}\/month$/, 'interpolated value is $N.NN/month' );
	unlike($display, qr/\$savings/,  'does not contain the literal variable name' );
};

# ── Integration: CLI output must not contain the raw variable reference ────

subtest 'ghgen analyze --estimate output contains dollar amount not raw variable' => sub {
	my $tmpdir	 = Path::Tiny->tempdir;
	my $workflow_dir = $tmpdir->child('.github/workflows');
	$workflow_dir->mkpath;

	# Workflow with no caching and no concurrency — guarantees issues exist
	# so the Potential Savings block is reached
	$workflow_dir->child('test.yml')->spew_utf8(<<'END_YAML');
name: Test CI
on:
  push: {}
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
  - uses: actions/checkout@v6
  - run: npm test
END_YAML

	my $lib = path(__FILE__)->parent->parent->child('lib')->absolute->stringify;
	my $bin = path(__FILE__)->parent->parent->child('bin/ghgen')->absolute->stringify;

	my $orig = Path::Tiny->cwd;
	chdir $tmpdir;

	my ($stdout, $stderr);
	run3([ perl => "-I$lib", $bin, 'analyze', '--estimate' ],
		  \undef, \$stdout, \$stderr );

	chdir $orig;

	# Regardless of whether savings were non-zero, the literal variable
	# reference must never appear
	unlike($stdout, qr/\$savings->\{cost\}/,
			'output does not contain the uninterpolated variable "$savings->{cost}"' );

	# If the savings block was printed, verify it shows a real dollar amount.
	# Strip ANSI colour codes before matching so the regex stays simple.
	(my $plain = $stdout) =~ s/\e\[[0-9;]*m//g;

	if ($plain =~ /Cost savings:/) {
		like($plain, qr/Cost savings:.*\$\d+\.\d{2}\/month/,
			  'Cost savings line contains a real dollar amount' );
	}
};

done_testing();
