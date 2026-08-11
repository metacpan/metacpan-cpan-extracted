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

done_testing();
