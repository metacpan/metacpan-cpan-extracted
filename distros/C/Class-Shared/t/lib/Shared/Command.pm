package Shared::Command;

use strict;
use warnings;

use Exporter 'import';
use File::Spec ();
use POSIX ();

our @EXPORT_OK = ('run_command');

# Purpose:       run a program with a time limit, the way `timeout 25 ...`
#                does, on a system that has no timeout command (macOS has none).
# Entry:         $limit is a number of seconds; @command is the program and its
#                arguments, as a list, so that no shell is involved and no
#                quoting can go wrong.
# Exit status:   ($exit_code, $output): the program's exit code and everything
#                it wrote to standard output and standard error, or 124 and
#                what it had written if it ran out of time (as timeout does).
# Side effects:  forks; kills the child if it is too slow.
sub run_command {
	my ($limit, @command) = @_;

	pipe(my $reader, my $writer) or die "cannot make a pipe: $!\n";

	my $pid = fork;
	die "cannot fork: $!\n" unless defined $pid;

	if ($pid == 0) {
		# Standard input is empty, so that a program that asks for input fails
		# at once instead of waiting for it.
		close($reader);
		open(STDIN, '<', File::Spec->devnull) or POSIX::_exit(127);
		open(STDOUT, '>&', $writer) or POSIX::_exit(127);
		open(STDERR, '>&', $writer) or POSIX::_exit(127);
		close($writer);

		{
			no warnings 'exec';    # exec only returns when it has failed
			exec(@command);
		}

		POSIX::_exit(127);
	}

	close($writer);

	my $output = '';
	my $timed_out = !eval {
		local $SIG{ALRM} = sub { die "timed out\n" };
		alarm $limit;

		while (1) {
			my $got = sysread($reader, my $chunk, 65536);
			last if !defined $got || $got == 0;
			$output .= $chunk;
		}

		alarm 0;
		1;
	};
	alarm 0;

	kill('KILL', $pid) if $timed_out;
	waitpid($pid, 0);
	close($reader);

	return ($timed_out ? 124 : $? >> 8, $output);
}

1;
