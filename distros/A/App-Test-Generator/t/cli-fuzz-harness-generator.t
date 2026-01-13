use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile tempdir);
use IPC::Run3;
use Symbol qw(gensym);
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'fuzz-harness-generator');
ok(-e $script, 'fuzz-harness-generator exists');
ok(-x $script, "$script is executable") if ($^O ne 'MSWin32');

my $valid_conf = $ENV{FUZZ_CONF} // 't/conf/abs.yml';
ok(-e $valid_conf, 'Valid test config exists');

# Helper to run the CLI
sub run_cmd {
	my (@cmd) = @_;
	my ($stdout, $stderr);
	run3([$^X, @cmd], \undef, \$stdout, \$stderr);
	my $exit = $? >> 8;
	return ($exit, $stdout // '', $stderr // '');
}

# --help
{
	my ($exit, $out, $err) = run_cmd($script, '--help');
	is($exit, 0, '--help exits cleanly');
	like($out, qr/Usage:/i, '--help output looks correct');
}

# --version
{
	my ($exit, $out, $err) = run_cmd($script, '--version');
	is($exit, 0, '--version exits cleanly');
	like($out, qr/\d+\.\d+/, '--version prints version');
}

# --dry-run
{
	my ($exit, $out, $err) = run_cmd(
		$script,
		'--dry-run',
		'--input', $valid_conf
	);

	is($exit, 0, '--dry-run exits cleanly');
	like($out, qr/Dry-run OK/i, '--dry-run reports success');
	is($err, '', '--dry-run emits no stderr');
}

# --dry-run should not create output
{
	my ($fh, $outfile) = tempfile();
	close $fh;
	unlink $outfile;

	my ($exit, $out, $err) = run_cmd(
		$script,
		'--dry-run',
		'--input',  $valid_conf,
		'--output', $outfile
	);

	ok(!-e $outfile, '--dry-run does not create output file');
}

# Normal generation creates output
{
	my ($fh, $outfile) = tempfile();
	close $fh;
	unlink $outfile;

	my ($exit, $out, $err) = run_cmd(
		$script,
		'--input',  $valid_conf,
		'--output', $outfile
	);

	is($exit, 0, 'Normal run exits cleanly');
	ok(-e $outfile, 'Output file created');
	ok(-s $outfile, 'Output file is non-empty');

	unlink $outfile;
}

# Invalid config fails
{
	my ($exit, $out, $err) = run_cmd($script, '--dry-run', '--input', 't/conf/does_not_exist.conf');

	isnt($exit, 0, 'Invalid config causes failure');
	like($err, qr/(No such file|failed|error)/i,
		'Error message shown for invalid input');
}

done_testing();
