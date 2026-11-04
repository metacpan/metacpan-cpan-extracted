package BI::Test::Command;

# Run a command and collect what it wrote, without pipes and with a deadline.
#
# IPC::Open3 with a pipe for each stream hung t/extract-cli.t on Windows until
# the CI job's timeout: a read of one pipe to its end blocks for as long as
# the child, or anything that inherited the pipe's other end, keeps it open.
# Files cannot fill up or wait for a reader, and a deadline turns any hang left
# into a failure that says what the command had written by then.

use strict;
use warnings;

use Exporter   qw(import);
use File::Temp ();
use IPC::Open3 qw(open3);
use POSIX      qw(WNOHANG);
use Time::HiRes ();

our @EXPORT_OK = qw(run_command);

# run_command(\@cmd, timeout => $seconds) -> ($exit, $stdout, $stderr, $timed_out)
#
# $exit is the command's exit status, or -1 when it ran past the deadline
# (default 120 seconds) and was killed; $timed_out is then true.
sub run_command {
	my ($cmd, %arg) = @_;
	my $timeout = $arg{timeout} // 120;

	my $out_fh = File::Temp->new;
	my $err_fh = File::Temp->new;

	# The child takes copies of STDOUT and STDERR when it starts, so point them
	# at the files just for the spawn.  Test::More writes to its own copies,
	# made when it loaded, so TAP is not affected.
	open my $save_out, '>&', \*STDOUT or die "dup STDOUT: $!\n";
	open my $save_err, '>&', \*STDERR or die "dup STDERR: $!\n";
	open STDOUT, '>&', $out_fh or die "redirect STDOUT: $!\n";
	open STDERR, '>&', $err_fh or die "redirect STDERR: $!\n";
	my $pid = eval { open3(my $in, '>&STDOUT', '>&STDERR', @$cmd) };
	my $spawn_error = $@;
	open STDOUT, '>&', $save_out or die "restore STDOUT: $!\n";
	open STDERR, '>&', $save_err or die "restore STDERR: $!\n";
	die "cannot run @$cmd: $spawn_error" unless $pid;

	my $deadline  = Time::HiRes::time() + $timeout;
	my $timed_out = 0;
	while (waitpid($pid, WNOHANG) == 0) {
		if (Time::HiRes::time() > $deadline) {
			kill 'KILL', $pid;
			waitpid $pid, 0;
			$timed_out = 1;
			last;
		}
		Time::HiRes::sleep(0.05);
	}
	my $exit = $timed_out ? -1 : $? >> 8;

	my $slurp = sub {
		my ($fh) = @_;
		open my $r, '<', $fh->filename or return '';
		local $/;
		my $text = <$r>;
		return $text // '';
	};
	return ($exit, $slurp->($out_fh), $slurp->($err_fh), $timed_out);
}

1;
