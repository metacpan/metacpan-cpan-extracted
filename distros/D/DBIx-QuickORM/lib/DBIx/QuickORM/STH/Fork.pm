package DBIx::QuickORM::STH::Fork;
use strict;
use warnings;

our $VERSION = '0.000023';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use Carp qw/croak/;
use POSIX qw/WNOHANG/;
use Time::HiRes qw/sleep/;
use Cpanel::JSON::XS qw/decode_json/;

use Object::HashBase qw{
    <connection
    <source

    only_one

    +dialect
    +ready
    <got_result
    <done
    <pid
    <owner_pid
    <pipe

    on_finish
    +terminated
    +clean
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::STH::Fork - Statement handle backed by a forked child process.

=head1 DESCRIPTION

An asynchronous statement-handle variant whose query runs in a forked child
process that streams JSON-encoded messages back over a pipe. Every message is
an envelope with exactly one key: C<result> (always first, the driver result),
C<row> (one row), then a terminal C<done> on success or C<error> on failure.
The terminal frame lets the parent tell a clean end from a child that died
mid-stream: end-of-file with no terminal frame is reported as a truncated
result rather than silently looking like the last row. C<ready> peeks the pipe
without blocking, C<result> and row fetches block on it. Finalizing the handle
drains the pipe, reaps the child, and releases the connection's fork slot;
cancelling additionally signals the child with C<TERM>.

The reap, cancel, and slot-release operations are guarded by the owning
process id: if the owner forks again the child inherits this object, and its
destructor must not disturb the owner's child process or connection state.

=head1 SYNOPSIS

    while (my $row_hr = $sth->next) { ... }

=head1 ATTRIBUTES

=over 4

=item connection

The owning connection.

=item source

The source the rows belong to.

=item only_one

When true, more than one row is an error.

=item dialect

The dialect, lazily taken from the connection.

=item ready

True once the result message has been read from the pipe.

=item got_result

The driver result once it has been read; absent until then.

=item done

True once iteration has finished and the handle has been finalized.

=item pid

PID of the forked child process.

=item owner_pid

PID of the process that created this handle. Reap/cancel/clear operations
no-op unless they run in this process, so an inherited copy in a forked child
cannot disturb the owner's child process or connection state.

=item on_finish

Optional parent-side completion callback. It runs once, in the owning process,
after the child has completed cleanly (used to apply row-cache maintenance for
a forked write, where the work happened in the child but the parent owns the
cache). It is skipped if the child errored or its stream was truncated.

=item pipe

The pipe object messages are read from.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $sth->cancel_supported

Always true: a forked query can be cancelled by signalling the child.

=item $dialect = $sth->dialect

The dialect, lazily taken from the connection.

=item $sth->clear

Release the fork slot on the owning connection.

=cut

# {{{ Role::STH / Role::Async interface

sub cancel_supported { 1 }

sub dialect { $_[0]->{+DIALECT} //= $_[0]->{+CONNECTION}->dialect }
sub clear   { $_[0]->{+CONNECTION}->clear_fork($_[0]) }

# }}} Role::STH / Role::Async interface

=pod

=item $sth->init

Constructor hook that validates required attributes.

=cut

sub init {
    my $self = shift;

    croak "'pid' is a required attribute"         unless $self->{+PID};
    croak "'pipe' is a required attribute"        unless $self->{+PIPE};
    croak "'connection' is a required attribute"  unless $self->{+CONNECTION};
    croak "'source' is a required attribute" unless $self->{+SOURCE};

    # The process that owns this handle. If the owner forks again, the child
    # inherits this object; its destructor must not reap the child process,
    # signal it, or release the parent's fork slot. Guarded operations no-op
    # unless they run in the owning process.
    $self->{+OWNER_PID} //= $$;
}

=pod

=item $bool = $sth->in_owner_process

True when running in the process that created this handle. The reap/cancel/
clear operations are no-ops elsewhere so an inherited copy in a forked child
cannot disturb the owner's child process or connection state.

=cut

sub in_owner_process { $_[0]->{+OWNER_PID} == $$ }

=pod

=item $bool = $sth->ready

Non-blocking peek at the pipe; true once the result message has been read.

=cut

sub ready {
    my $self = shift;
    return 1 if $self->{+READY};
    return 1 if exists $self->{+GOT_RESULT};

    my $msg = $self->_read_message(0);    # non-blocking peek for the result message
    return 0 unless defined $msg;

    $self->{+GOT_RESULT} = $self->_decode_result($msg);
    return $self->{+READY} = 1;
}

=pod

=item $result = $sth->result

Block on the pipe until the result message arrives, caching and returning it.

=cut

sub result {
    my $self = shift;
    return $self->{+GOT_RESULT} if exists $self->{+GOT_RESULT};

    my $msg = $self->_read_message(1);    # blocking
    $self->{+READY} //= 1;
    return $self->{+GOT_RESULT} = $self->_decode_result($msg);
}

=pod

=item $sth->cancel

Signal and reap the child process and finalize the handle.

=cut

sub cancel {
    my $self = shift;

    return if $self->{+DONE};

    # An inherited copy in a forked child must not signal or reap the owner's
    # child process; only mark itself spent locally.
    unless ($self->in_owner_process) {
        $self->{+DONE} = 1;
        return;
    }

    delete $self->{+PIPE};

    if (waitpid($self->{+PID}, WNOHANG) <= 0) {
        kill('TERM', $self->{+PID});
        waitpid($self->{+PID}, 0);
    }

    $self->clear;
    $self->{+DONE} = 1;
}

=pod

=item $row_hr = $sth->next

Return the next row as a hashref, or undef once exhausted. With C<only_one>
set, a second row is an error.

=back

=cut

sub next {
    my $self = shift;
    my $row = $self->_next;

    if ($self->{+ONLY_ONE}) {
        # Finalize before throwing so the child is reaped and the connection's
        # fork slot is released even on the error path.
        if ($self->_next) {
            $self->set_done;
            croak "Expected only 1 row, but got more than one";
        }
        $self->set_done;
    }

    return $row;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $row_hr = $sth->_next

Read and decode the next row message from the pipe, finalizing when the child
signals exhaustion.

=cut

sub _next {
    my $self = shift;

    return if $self->{+DONE};

    $self->result unless exists $self->{+GOT_RESULT};

    my $msg = $self->_read_message(1);    # blocking

    unless (defined $msg) {
        # EOF with no terminal frame: the child died before signalling
        # completion, so the streamed rows are truncated.
        $self->{+TERMINATED} = 1;
        $self->{+CLEAN}      = 0;
        $self->set_done;
        croak "Forked query ended before the child signalled completion (result was truncated)";
    }

    my $frame = decode_json($msg);

    if ($frame->{done}) {            # clean end of stream
        $self->{+TERMINATED} = 1;
        $self->{+CLEAN}      = 1;
        $self->set_done;
        return;
    }

    if (exists $frame->{error}) {    # the child reported a failure
        $self->{+TERMINATED} = 1;
        $self->{+CLEAN}      = 0;
        $self->set_done;
        $self->_croak_child_error($frame->{error});
    }

    return $frame->{row} if exists $frame->{row};

    $self->{+TERMINATED} = 1;
    $self->{+CLEAN}      = 0;
    $self->set_done;
    croak "Got invalid data from pipe: $msg";
}

=pod

=item $msg = $sth->_read_message($blocking)

Read one raw message from the pipe, blocking or not per the argument.

=cut

sub _read_message {
    my $self = shift;
    my ($blocking) = @_;

    my $pipe = $self->{+PIPE} or return undef;
    $pipe->read_blocking($blocking ? 1 : 0);
    return $pipe->read_message;
}

=pod

=item $result = $sth->_decode_result($msg)

Decode the JSON result message and return its C<result> payload, croaking on
invalid data.

=cut

sub _decode_result {
    my $self = shift;
    my ($msg) = @_;

    my $data = defined($msg) ? decode_json($msg) : undef;
    return $data->{result} if $data && exists $data->{result};

    # An error frame or EOF arrived where the result frame was expected.
    # Finalize so the child is reaped and the fork slot released, then surface
    # the failure rather than hanging or returning bad data.
    $self->{+TERMINATED} = 1;
    $self->{+CLEAN}      = 0;
    $self->set_done;
    $self->_croak_child_error($data->{error}) if $data && exists $data->{error};
    croak "Forked query produced no result before the child exited";
}

=pod

=item $sth->_croak_child_error($message)

Croak reporting an error the forked child sent back over the pipe.

=cut

sub _croak_child_error {
    my $self = shift;
    my ($err) = @_;
    $err = 'unknown error' unless defined($err) && length($err);
    croak "Forked query failed in the child process: $err";
}

=pod

=item $bool = $sth->cancel_on_destroy

False when an C<on_finish> callback is set: such a handle wraps a write that
must run to completion, so its destructor waits for the child instead of
signalling it.

=cut

sub cancel_on_destroy { $_[0]->{+ON_FINISH} ? 0 : 1 }

=pod

=item $sth->set_done

Drive the stream to its terminal frame (when nothing else has), reap the
child, release the fork slot, mark the handle done, and run any C<on_finish>
callback if the child completed cleanly. Idempotent.

=back

=cut

sub set_done {
    my $self = shift;

    return if $self->{+DONE};

    # An inherited copy in a forked child must not reap the owner's child or
    # release the owner's fork slot; only mark itself spent locally.
    unless ($self->in_owner_process) {
        $self->{+DONE} = 1;
        return;
    }

    # If nothing drove the stream to its terminal frame (e.g. a forked write
    # that no one iterated) read it to completion now, so we know whether the
    # child finished cleanly before running the parent-side completion.
    $self->_drive_to_terminal unless $self->{+TERMINATED};

    delete $self->{+PIPE};
    waitpid($self->{+PID}, 0) if $self->{+PID};
    $self->clear;
    $self->{+DONE} = 1;

    if (my $on_finish = $self->{+ON_FINISH}) {
        $on_finish->() if $self->{+CLEAN};
    }
}

=pod

=head1 PRIVATE METHODS (cont.)

=over 4

=item $sth->_drive_to_terminal

Read and discard frames until the terminal C<done> or C<error> frame (or EOF),
recording whether the child finished cleanly. Used by C<set_done> for handles
whose stream nobody iterated, such as forked writes. Warns rather than croaks
on an unclean end, since it usually runs from a destructor.

=cut

sub _drive_to_terminal {
    my $self = shift;
    return if $self->{+TERMINATED};

    unless (exists $self->{+GOT_RESULT}) {
        my $msg  = $self->_read_message(1);
        my $data = defined($msg) ? decode_json($msg) : undef;

        if    ($data && exists $data->{result}) { $self->{+GOT_RESULT} = $data->{result} }
        elsif ($data && exists $data->{error})  { return $self->_terminate_unclean($data->{error}) }
        else                                    { return $self->_terminate_unclean() }
    }

    while (1) {
        my $msg = $self->_read_message(1);
        return $self->_terminate_unclean() unless defined $msg;

        my $frame = decode_json($msg);

        if ($frame->{done}) {
            $self->{+TERMINATED} = 1;
            $self->{+CLEAN}      = 1;
            return;
        }

        return $self->_terminate_unclean($frame->{error}) if exists $frame->{error};

        # Any stray row frames are discarded: a write streams none, and a
        # select abandoned here no longer has a consumer.
    }
}

=pod

=item $sth->_terminate_unclean($message)

Mark the stream terminated without a clean completion and warn. Used when the
child errored or died while C<set_done> was draining the pipe.

=back

=cut

sub _terminate_unclean {
    my $self = shift;
    my ($err) = @_;

    $self->{+TERMINATED} = 1;
    $self->{+CLEAN}      = 0;

    my $detail = (defined($err) && length($err)) ? ": $err" : " (child died before completion)";
    warn "Forked query did not complete cleanly$detail\n";

    return;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
