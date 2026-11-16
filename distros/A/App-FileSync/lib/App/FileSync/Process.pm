package App::FileSync::Process;

# Starts the child a transport talks to (filesync-server, or ssh) and reaps
# it.  Both transports used to call IPC::Open3 and then waitpid directly,
# which hung forever on Windows: the child inherited the parent's end of its
# own stdin pipe, so closing that end never gave it end of file.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use IO::Handle ();
use IPC::Open3 ();
use POSIX qw(WNOHANG);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();

use App::FileSync::Args qw(named);
use App::FileSync::I18N qw(throw);

use version; our $VERSION = version->declare('0.002.1');

# How long reap() waits for a child to exit by itself before stopping it.
# The server needs a moment after end of file to discard a half-received
# upload and journal the failed session; over ssh the remote end has to
# hear of it first.  A package variable, not Readonly, so tests can shrink it.
our $GRACE_SECONDS = 30;

# After SIGTERM, how long to wait before SIGKILL.
our $TERM_SECONDS = 5;

# How often reap() looks to see whether the child has gone.
Readonly::Scalar my $POLL_SECONDS => 0.05;

# Windows: handle inheritance is switched off per handle, not per process.
Readonly::Scalar my $IS_WINDOWS => $^O eq 'MSWin32';

# The value waitpid() returns once there is no such child left to reap.
Readonly::Scalar my $NO_CHILD => -1;

# Bits of $? that hold the exit status and the signal.
Readonly::Scalar my $EXIT_SHIFT  => 8;
Readonly::Scalar my $SIGNAL_MASK => 127;

=encoding utf8

=head1 NAME

App::FileSync::Process - start and reap a transport's child process

=head1 SYNOPSIS

	use App::FileSync::Process;

	my $child = App::FileSync::Process::spawn(command => [ 'ssh', 'host', 'filesync-server' ], stderr => fileno(STDERR));
	print { $child->{writer} } "...\n";
	close $child->{writer};
	close $child->{reader};
	my $end = App::FileSync::Process::reap(pid => $child->{pid});

=head1 DESCRIPTION

A transport writes to its child's standard input and reads its standard
output, and relies on the child seeing end of file when the transport closes
its end.  That only happens once every copy of the pipe's write end is
closed.  IPC::Open3 marks the parent's ends close-on-exec on Unix, but on
Windows it starts the child with every inheritable handle, so the child held
a copy of its own stdin's write end and waited for input forever.

C<spawn> therefore makes the parent's ends non-inheritable on Windows before
starting the child, and C<reap> never waits without limit: a child that has
not exited after C<$GRACE_SECONDS> is stopped.

=head1 FUNCTIONS

=head2 spawn

Purpose: start a child process with pipes to its standard input and output.

Args: C<command> (the argv, never passed through a shell), C<stderr> (a file
descriptor the child's standard error goes to).

Returns: a hashref: C<pid>, C<writer> (to the child's standard input),
C<reader> (from its standard output).  The writer is unbuffered.

Side Effects: starts the process.  On Windows, briefly points this process's
standard handles at the child's pipes while it starts.

Usage:

	my $child = App::FileSync::Process::spawn(command => \@argv, stderr => fileno(STDERR));

=head3 EXAMPLE

	my $child = App::FileSync::Process::spawn(command => [ $^X, '-pe1' ], stderr => fileno(STDERR));
	print { $child->{writer} } "echo\n";
	close $child->{writer};
	print readline $child->{reader};	# echo

=head3 API SPECIFICATION

=head4 INPUT

	{
		command => { type => 'arrayref', min => 1 },
		stderr  => { type => 'integer', min => 0 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			pid    => { type => 'integer', min => 1 },
			writer => { type => 'object' },
			reader => { type => 'object' },
		},
	}

=head3 MESSAGES

	Key              Meaning                       Resolution
	args.invalid     command or stderr is missing  pass them
	process.spawn    the program could not start   check that it exists and runs
	process.inherit  Windows refused a handle flag see the error text

=head3 FORMAL SPECIFICATION

	spawn(a) ⇒ ∃ c • argv(c) = a.command ∧ stdin(c) = pipe(writer) ∧ stdout(c) = pipe(reader)
	         ∧ writer ∉ handles(c) ∧ reader ∉ handles(c)

=head3 PSEUDOCODE

	if not Windows:
		open3 the command (it marks the parent's ends close-on-exec)
	else:
		make two pipes, and mark the parent's ends non-inheritable
		save STDIN, STDOUT, STDERR; point them at the child's ends and stderr
		start the command without waiting; restore the standard handles
		close the child's ends in this process
	return pid, writer, reader

=cut

sub spawn {
	my $args = named(\@_, {
		command => { type => 'arrayref', min => 1 },
		stderr  => { type => 'integer', min => 0 },
	}, 'Process::spawn');

	my @command = @{ $args->{command} };
	my ($pid, $writer, $reader);

	if ($IS_WINDOWS) {
		($pid, $writer, $reader) = _spawn_windows(\@command, $args->{stderr});
	} else {
		$pid = eval { IPC::Open3::open3($writer, $reader, '>&' . $args->{stderr}, @command) };
		throw('process.spawn', { program => $command[0], error => _reason($@) }) unless $pid;
	}
	$writer->autoflush(1);

	return { pid => $pid, writer => $writer, reader => $reader };
}

=head2 reap

Purpose: wait for a child to exit, stopping it if it does not.

Args: C<pid>, optional C<grace> (seconds to wait before stopping it; default
C<$GRACE_SECONDS>).

Returns: a hashref: C<status> (exit status, or -1 when the child had already
been reaped), C<signal> (the signal that ended it, or 0) and C<killed> (1 if
C<reap> had to stop it).

Side Effects: waits up to C<grace> seconds, then sends SIGTERM, waits up to
C<$TERM_SECONDS> more, then sends SIGKILL.  On Windows it sends SIGKILL
(TerminateProcess) straight away, since Perl delivers SIGTERM there as a
console Ctrl-Break.  Sets C<$?>.

Usage:

	close $child->{writer};
	close $child->{reader};
	my $end = App::FileSync::Process::reap(pid => $child->{pid});

=head3 EXAMPLE

	my $end = App::FileSync::Process::reap(pid => $pid, grace => 1);
	warn "the child would not exit\n" if $end->{killed};

=head3 API SPECIFICATION

=head4 INPUT

	{
		pid   => { type => 'integer', min => 1 },
		grace => { type => 'number', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			status => { type => 'integer', min => -1 },
			signal => { type => 'integer', min => 0 },
			killed => { type => 'integer', memberof => [ 0, 1 ] },
		},
	}

=head3 MESSAGES

	Key            Meaning          Resolution
	args.invalid   no pid given     pass it

=head3 FORMAL SPECIFICATION

	exits(c) within grace ⇒ killed! = 0 ∧ status! = exit(c)
	¬ exits(c) within grace ⇒ killed! = 1 ∧ c ∉ processes'

=head3 PSEUDOCODE

	wait up to grace seconds for the child to exit
	if it has not:
		send TERM and wait up to TERM_SECONDS (not on Windows)
		if it still has not: send KILL and wait for it
	return its exit status and signal, and whether it was stopped

=cut

sub reap {
	my $args = named(\@_, {
		pid   => { type => 'integer', min => 1 },
		grace => { type => 'number', min => 0, optional => 1 },
	}, 'Process::reap');

	my $pid = $args->{pid};
	my $killed = 0;

	unless (_wait_for($pid, $args->{grace} // $GRACE_SECONDS)) {
		$killed = 1;
		# Windows has no polite stop: Perl turns TERM into a console Ctrl-Break
		# event, which can reach other processes on the console.  KILL there is
		# TerminateProcess, for that child alone.
		CORE::kill('TERM', $pid) unless $IS_WINDOWS;
		unless (!$IS_WINDOWS && _wait_for($pid, $TERM_SECONDS)) {
			CORE::kill('KILL', $pid);
			waitpid($pid, 0);
		}
	}

	my $status = $?;
	return {
		status => $status == $NO_CHILD ? $NO_CHILD : $status >> $EXIT_SHIFT,
		signal => $status == $NO_CHILD ? 0 : $status & $SIGNAL_MASK,
		killed => $killed,
	};
}

# _wait_for
# Purpose:     poll for a child's exit for a limited time.
# Entry:       $pid is a child of this process; $seconds >= 0.
# Exit:        returns 1 once the child is reaped (or was already gone),
#              0 if it is still running when the time is up.
# Side effects: reaps the child, setting $?.
sub _wait_for :Private {
	my ($pid, $seconds) = @_;

	my $deadline = Time::HiRes::time() + $seconds;
	while (1) {
		my $reaped = waitpid($pid, WNOHANG);
		return 1 if $reaped == $pid || $reaped == $NO_CHILD;
		return 0 if Time::HiRes::time() >= $deadline;
		Time::HiRes::sleep($POLL_SECONDS);
	}
	return 0;
}

# _spawn_windows
# Purpose:     start a child on Windows without it inheriting our pipe ends.
# Entry:       $command is the argv; $stderr a file descriptor.
# Exit:        returns ($pid, $writer, $reader).
# Side effects: starts the process.  STDIN, STDOUT and STDERR point at the
#              child's handles while it starts (that is how a Windows child
#              is given them) and are restored before returning, even when
#              the start fails.  This is what IPC::Open3 does on Windows,
#              plus the inheritance flags it leaves set.
sub _spawn_windows :Private {
	my ($command, $stderr) = @_;

	pipe(my $child_in, my $writer);
	pipe(my $reader, my $child_out);
	_no_inherit($_) for $writer, $reader;

	STDOUT->flush();
	STDERR->flush();
	my @restore = (
		_point(\*STDIN,  '<', $child_in),
		_point(\*STDOUT, '>', $child_out),
		_point(\*STDERR, '>', $stderr),
	);

	my $pid = do {
		local $!;
		my $started = eval { CORE::system(1, @{$command}) };	# 1 == P_NOWAIT
		my $error = $@ || "$!";
		$_->() for reverse @restore;
		throw('process.spawn', { program => $command->[0], error => _reason($error) })
			unless $started && $started > 0;
		$started;
	};

	CORE::close($child_in);
	CORE::close($child_out);

	return ($pid, $writer, $reader);
}

# _point
# Purpose:     point a standard handle somewhere else for a while.
# Entry:       $handle is STDIN, STDOUT or STDERR; $mode '<' or '>';
#              $target a handle or a file descriptor.
# Exit:        returns a coderef that puts $handle back as it was.
# Side effects: dups $handle aside (not inheritable, so the child does not
#              keep this process's own output open), then dups $target onto it.
sub _point :Private {
	my ($handle, $mode, $target) = @_;

	# Already there (the server's stderr is usually ours): reopening a handle
	# as a dup of its own descriptor would close it first.
	my $current = fileno $handle;
	return sub { 1 } if !ref $target && defined $current && $target == $current;

	my $saved;
	if (defined fileno $handle) {
		open $saved, "$mode&", $handle;
		_no_inherit($saved);
	}
	open $handle, "$mode&", $target;

	return sub {
		if ($saved) {
			open $handle, "$mode&", $saved;
			CORE::close($saved);
		} else {
			CORE::close($handle);
		}
	};
}

# _no_inherit
# Purpose:     keep a child from inheriting a handle (Windows only).
# Entry:       $fh is an open Perl filehandle.
# Exit:        returns 1.
# Side effects: clears HANDLE_FLAG_INHERIT on the OS handle; raises
#              process.inherit if Windows refuses.
sub _no_inherit :Private {
	my ($fh) = @_;

	require Win32API::File;
	my $handle = Win32API::File::GetOsFHandle($fh);
	my $ok = $handle && $handle != Win32API::File::INVALID_HANDLE_VALUE()
		&& Win32API::File::SetHandleInformation($handle, Win32API::File::HANDLE_FLAG_INHERIT(), 0);
	throw('process.inherit', { error => "$^E" }) unless $ok;

	return 1;
}

# _reason
# Purpose:     the text of a failed start, without IPC::Open3's prefixes.
# Entry:       $error is $@ or $! text.
# Exit:        returns the reason, e.g. "No such file or directory".
# Side effects: none.
sub _reason :Private {
	my ($error) = @_;

	$error = "$error";
	$error =~ s/\Aopen3: //;
	$error =~ s/\AIO::Pipe: Can't spawn-NOWAIT: //;
	$error =~ s/\Aexec of .*? failed: //s;
	$error =~ s/ at \S+ line \d+\.?\s*\z//s;
	chomp $error;
	return $error;
}

1;

__END__

=head1 LIMITATIONS

On Windows, C<spawn> is not safe to call from two threads at once: it points
this process's standard handles at the child's pipes while the child starts.
App::FileSync does not use threads.

A child stopped by C<reap> does not get to clean up.  The server discards
temporaries it finds stale on a later session, and the lock is the
operating system's, so neither outlives it for long.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
