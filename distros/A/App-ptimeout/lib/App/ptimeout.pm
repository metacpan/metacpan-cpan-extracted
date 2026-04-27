package App::ptimeout;

use strict;
use warnings;
no warnings 'numeric';

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use POSIX qw(WNOHANG);
use Proc::ProcessTable;

our $VERSION = '1.0.3';

sub _run {
    my($timeout, @argv) = @_;

    if($timeout =~ /m$/) { $timeout *= 60 }
     elsif($timeout =~ /h$/) { $timeout *= 3600 }

    pipe(my $stderr_reader, my $stderr_writer)
        or die("Error creating stderr pipe\n");
    _set_nonblocking($stderr_reader);

    my $pid = fork();
    if(!defined($pid)) {
        die("Error forking\n")
    } elsif(!$pid) {
        # the child process, which runs the command

        # only the parent cares about this end of the pipe, so close the copy in this process
        close $stderr_reader or die("Error closing stderr reader\n");
        # re-open STDERR as a duplicate of the pipe we inherited from the parent
        open STDERR, '>&', $stderr_writer
            or die("Error redirecting stderr\n");
        # now that we've duplicated it we don't need another copy
        close $stderr_writer or die("Error closing stderr writer\n");

        my $status = system @argv;
        exit _normalise_status($status);
    }

    # only the parent process, the watchdog, gets here

    # only the child cares about this end of the pipe, it now has a copy, so close ours
    close $stderr_writer or die("Error closing stderr writer\n");

    my $deadline = time + $timeout;
    my $timed_out = 0;
    my $child_status;
    my $stderr_buffer = '';
    my $held_line;

    # Loop while the process we're monitoring does its thang
    while(1) {
        # The background process is running, and its STDERR is being captured.
        # If it's said anything on its STDERR, flush it to the *real* STDERR.
        _pump_stderr(
            $stderr_reader,
            \$stderr_buffer,
            \$held_line,
            timed_out => $timed_out,
        );

        # Has the process finished?
        my $waited = waitpid($pid, WNOHANG);
        if($waited == $pid) {   # yes, and it exited
            $child_status = $?;
            last;
        }
        if($waited == -1) {     # it's all gone wrong
            die("Error waiting for child process\n");
        }

        if(time >= $deadline) { # still running, but been running too long
            # looks like dpulicate code, but it avoids a race condition
            $waited = waitpid($pid, WNOHANG);
            if($waited == $pid) {
                $child_status = $?;
                last;
            }
            warn "timed out\n";
            $timed_out = 1;
            $child_status = _terminate_process_tree($pid);
            last;
        }

        select undef, undef, undef, 0.1;
    }

    _flush_remaining_stderr(
        $stderr_reader,
        \$stderr_buffer,
        \$held_line,
        timed_out => $timed_out,
    );
    close $stderr_reader or die("Error closing stderr reader\n");

    exit($timed_out ? 124 : _normalise_status($child_status));
}

sub _normalise_status {
    my($status) = @_;

    return 255 if($status == -1);
    return $status >> 8;
}

sub _set_nonblocking {
    my($fh) = @_;

    my $flags = fcntl($fh, F_GETFL, 0);
    defined($flags) or die("Error reading stderr flags\n");
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
        or die("Error setting stderr nonblocking\n");
}

sub _set_blocking {
    my($fh) = @_;

    my $flags = fcntl($fh, F_GETFL, 0);
    defined($flags) or die("Error reading stderr flags\n");
    fcntl($fh, F_SETFL, $flags & ~O_NONBLOCK)
        or die("Error restoring blocking stderr\n");
}

sub _emit_stderr_lines {
    my($buffer_ref, $held_line_ref, %options) = @_;

    while($$buffer_ref =~ s/\A([^\n]*\n)//) {
        my $line = $1;
        # OpenBSD sometimes (?) spits out this unnecessary diagnostic when sh is SIGTERMed
        if(
            $options{timed_out} &&
            $^O eq 'openbsd' &&
            $line =~ /\ATerminated\s*\z/
        ) {
            $$held_line_ref = $line;
            next;
        }

        if(defined($$held_line_ref)) {
            print STDERR $$held_line_ref;
            undef $$held_line_ref;
        }
        print STDERR $line;
    }
}

sub _pump_stderr {
    my($stderr_reader, $buffer_ref, $held_line_ref, %options) = @_;

    while(1) {
        my $chunk = '';
        my $bytes = sysread($stderr_reader, $chunk, 4096);
        if(!defined($bytes)) {
            last if($!{EAGAIN} || $!{EWOULDBLOCK});
            die("Error reading stderr\n");
        }
        last if($bytes == 0);
        $$buffer_ref .= $chunk;
        _emit_stderr_lines($buffer_ref, $held_line_ref, %options);
    }
}

sub _flush_remaining_stderr {
    my($stderr_reader, $buffer_ref, $held_line_ref, %options) = @_;

    _set_blocking($stderr_reader);
    while(1) {
        my $chunk = '';
        my $bytes = sysread($stderr_reader, $chunk, 4096);
        die("Error reading stderr\n") if(!defined($bytes));
        last if($bytes == 0);
        $$buffer_ref .= $chunk;
        _emit_stderr_lines($buffer_ref, $held_line_ref, %options);
    }

    if(length($$buffer_ref)) {
        if(
            $options{timed_out} &&
            $^O eq 'openbsd' &&
            $$buffer_ref =~ /\ATerminated\s*\z/
        ) {
            $$buffer_ref = '';
        } else {
            if(defined($$held_line_ref)) {
                print STDERR $$held_line_ref;
                undef $$held_line_ref;
            }
            print STDERR $$buffer_ref;
            $$buffer_ref = '';
        }
    }

    if(defined($$held_line_ref) && !($options{timed_out} && $^O eq 'openbsd')) {
        print STDERR $$held_line_ref;
    }
}

sub _terminate_process_tree {
    my($pid) = @_;

    my $process_table = Proc::ProcessTable->new->table;
    my @victims = _get_pids($process_table, $pid);
    kill SIGTERM => @victims, $pid;

    my $deadline = time + 2;
    while(time < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
        return $? if($waited == $pid || $waited == -1);
        select undef, undef, undef, 0.1;
    }

    $process_table = Proc::ProcessTable->new->table;
    @victims = _get_pids($process_table, $pid);
    kill SIGKILL => @victims, $pid;
    waitpid($pid, 0);
    $?;
}

# Copied from Proc::Killfam::get_pids in Proc-ProcessTable-0.634 which is
# GPL/Artistic licenced. It's undocumented there so should be considered
# unstable, hence why copied.
sub _get_pids {
    my($procs, @kids) = @_;
    my @pids;
    foreach my $kid (@kids) {
        foreach my $proc (@$procs) {
            if ($proc->ppid == $kid) {
                my $pid = $proc->pid;
                push @pids, $pid, _get_pids($procs, $pid);
            }
        }
    }
    @pids;
}

=head1 NAME

App::ptimeout - module implementing L<ptimeout>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2026 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This is also free-as-in-mason software.

1;
