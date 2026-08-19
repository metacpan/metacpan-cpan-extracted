use strict;
use warnings;

use Test::Most;
use IPC::Run3;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;

# Regression test for the command-injection fix in the --changed_only
# code path: --base_sha used to be interpolated straight into a
# backtick-executed `git diff` shell command.

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'test-generator-mutate');
ok(-x $script, "$script is executable") if ($^O ne 'MSWin32');

my $tmpdir = tempdir(CLEANUP => 1);
my $orig_cwd = File::Spec->rel2abs('.');

# git -C <dir> was introduced in git 1.8.5; use chdir for portability.
sub git_in {
	my ($dir, @args) = @_;
	chdir $dir or die "chdir $dir: $!";
	my $rc = system('git', @args);
	chdir $orig_cwd or die "chdir $orig_cwd: $!";
	return $rc;
}

sub git_in_capture {
	my ($dir, @args) = @_;
	chdir $dir or die "chdir $dir: $!";
	my $out;
	run3(['git', @args], \undef, \$out, \undef);
	chdir $orig_cwd or die "chdir $orig_cwd: $!";
	return $out // '';
}

{
	# Set up a minimal git repo with one committed lib/*.pm file, so
	# --changed_only --base_sha has something real to diff against.
	git_in($tmpdir, 'init', '-q')                          and die 'git init failed';
	git_in($tmpdir, 'config', 'user.email', 'a@b.com')     and die 'git config failed';
	git_in($tmpdir, 'config', 'user.name', 'test')         and die 'git config failed';

	mkdir File::Spec->catdir($tmpdir, 'lib') or die $!;
	my $pm = File::Spec->catfile($tmpdir, 'lib', 'Foo.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "package Foo;\n1;\n";
	close $fh;

	git_in($tmpdir, 'add', 'lib/Foo.pm')                   and die 'git add failed';
	git_in($tmpdir, 'commit', '-q', '-m', 'init')          and die 'git commit failed';
}

# Runs the script with $tmpdir as the cwd, since --changed_only relies
# on relative git commands. Always restores the original cwd, even on
# die, so later blocks aren't affected by a failed run.
sub run_cmd {
	my (@cmd) = @_;
	my ($stdout, $stderr);
	chdir $tmpdir or die "chdir $tmpdir: $!";
	run3([$^X, '-I', File::Spec->catdir($orig_cwd, 'lib'), $script, @cmd], \undef, \$stdout, \$stderr);
	my $exit = $? >> 8;
	chdir $orig_cwd or die "chdir $orig_cwd: $!";
	return ($exit, $stdout // '', $stderr // '');
}

# --------------------------------------------------------------------
# A shell-metacharacter-laden --base_sha must not be executed.
# --------------------------------------------------------------------

{
	my $marker = File::Spec->catfile($tmpdir, 'injected');
	unlink $marker;

	my ($exit, $out, $err) = run_cmd(
		'--changed_only',
		'--base_sha', "\$(touch $marker)",
		'--lib', 'lib',
		'--json', File::Spec->catfile($tmpdir, 'mutation.json'),
	);

	ok(!-f $marker, 'injected command via --base_sha was not executed');
	isnt($exit, 0, 'malicious --base_sha is rejected with a non-zero exit');
	like($err, qr/Invalid base_sha/, 'error names the rejected option');
}

# --------------------------------------------------------------------
# A well-formed --base_sha (a real commit SHA) still works.
# --------------------------------------------------------------------

{
	my $head_out = git_in_capture($tmpdir, qw(rev-parse HEAD));
	chomp $head_out;

	my ($exit, $out, $err) = run_cmd(
		'--changed_only',
		'--base_sha', $head_out,
		'--lib', 'lib',
		'--json', File::Spec->catfile($tmpdir, 'mutation.json'),
	);

	unlike($err, qr/Invalid base_sha/, 'a real commit SHA passes validation')
		or diag("stdout: $out\nstderr: $err");
}

# --------------------------------------------------------------------
# Regression: prove is called with -r so tests in subdirectories of
# --tests are included in both the baseline check and per-mutant runs.
# Before the fix (GitHub issue #10), prove ran without -r and silently
# skipped any .t files inside subdirs, letting all mutants survive.
# These blocks run a full mutation cycle so they are only run under
# EXTENDED_TESTING=1 (each spawns multiple prove processes).
# --------------------------------------------------------------------

SKIP: {
	skip 'EXTENDED_TESTING not set', 4 unless $ENV{EXTENDED_TESTING};

{
	my $rdir  = tempdir(CLEANUP => 1);
	my $rlib  = File::Spec->catdir($rdir, 'lib');
	my $rt    = File::Spec->catdir($rdir, 't');
	my $rsub  = File::Spec->catdir($rt,   'boundary');

	# prove -Mblib requires blib/, blib/lib/, and blib/arch/ to all exist.
	for my $d (
		File::Spec->catdir($rdir, 'blib'),
		File::Spec->catdir($rdir, 'blib', 'lib'),
		File::Spec->catdir($rdir, 'blib', 'arch'),
		$rlib, $rt, $rsub,
	) {
		mkdir $d or die "mkdir $d: $!";
	}

	# Module under test: a numeric comparison that generates mutants.
	# NumericBoundary will mutate "> 10" to ">= 10", "> 11", "> 9", etc.
	{
		open my $fh, '>', File::Spec->catfile($rlib, 'Bar.pm') or die $!;
		print $fh <<'PM';
package Bar;
sub check { my ($x) = @_; return $x > 10 ? 1 : 0; }
1;
PM
	}

	# Top-level test: trivially passes for every mutant — never kills anything.
	{
		open my $fh, '>', File::Spec->catfile($rt, 'dummy.t') or die $!;
		print $fh "use Test::More; ok(1, 'loaded'); done_testing;\n";
	}

	# Subdirectory test: verifies the exact boundary value.
	# With ">= 10", Bar::check(10) returns 1 — this test expects 0, so the
	# mutant is killed.  Without -r, this file is never run and the mutant
	# survives.
	{
		open my $fh, '>', File::Spec->catfile($rsub, 'boundary.t') or die $!;
		print $fh <<'SUBT';
use Test::More;
require Bar;
is(Bar::check(10), 0, 'check(10) must return 0 — 10 is not strictly > 10');
is(Bar::check(11), 1, 'check(11) must return 1 — 11 is > 10');
done_testing;
SUBT
	}

	my ($stdout, $stderr);
	chdir $rdir or die "chdir $rdir: $!";
	run3(
		[
			$^X, '-I', File::Spec->catdir($orig_cwd, 'lib'),
			$script,
			'--file',  File::Spec->catfile('lib', 'Bar.pm'),
			'--lib',   'lib',
			'--tests', 't',
		],
		\undef, \$stdout, \$stderr,
	);
	my $exit = $? >> 8;
	chdir $orig_cwd or die "chdir $orig_cwd: $!";

	isnt($exit, 2,
		'baseline did not fail — subdirectory test was included in prove -r baseline')
		or diag("stderr:\n$stderr");

	like($stdout, qr/Killed:\s*[1-9]/,
		'at least one mutant killed by the subdirectory test (proves -r flag is active)')
		or diag("stdout:\n$stdout\nstderr:\n$stderr");
}

# Complementary check: confirm that with only a top-level test that never
# kills anything, ALL mutants survive — this isolates the regression.
# The subdirectory killer test is absent here, so the only way mutants
# get killed is if some other test happens to cover them, which dummy.t
# cannot do (it is unconditional ok(1)).

{
	my $rdir  = tempdir(CLEANUP => 1);
	my $rlib  = File::Spec->catdir($rdir, 'lib');
	my $rt    = File::Spec->catdir($rdir, 't');

	for my $d (
		File::Spec->catdir($rdir, 'blib'),
		File::Spec->catdir($rdir, 'blib', 'lib'),
		File::Spec->catdir($rdir, 'blib', 'arch'),
		$rlib, $rt,
	) {
		mkdir $d or die "mkdir $d: $!";
	}

	{
		open my $fh, '>', File::Spec->catfile($rlib, 'Bar.pm') or die $!;
		print $fh <<'PM';
package Bar;
sub check { my ($x) = @_; return $x > 10 ? 1 : 0; }
1;
PM
	}

	{
		open my $fh, '>', File::Spec->catfile($rt, 'dummy.t') or die $!;
		print $fh "use Test::More; ok(1, 'loaded'); done_testing;\n";
	}

	my ($stdout, $stderr);
	chdir $rdir or die "chdir $rdir: $!";
	run3(
		[
			$^X, '-I', File::Spec->catdir($orig_cwd, 'lib'),
			$script,
			'--file',  File::Spec->catfile('lib', 'Bar.pm'),
			'--lib',   'lib',
			'--tests', 't',
		],
		\undef, \$stdout, \$stderr,
	);
	my $exit = $? >> 8;
	chdir $orig_cwd or die "chdir $orig_cwd: $!";

	isnt($exit, 2, 'baseline passes with top-level-only test')
		or diag("stderr:\n$stderr");

	like($stdout, qr/Survived:\s*[1-9]/,
		'mutants survive when killer test is top-level-only — confirms subdirectory isolation')
		or diag("stdout:\n$stdout\nstderr:\n$stderr");
}

} # end SKIP: EXTENDED_TESTING

done_testing();
