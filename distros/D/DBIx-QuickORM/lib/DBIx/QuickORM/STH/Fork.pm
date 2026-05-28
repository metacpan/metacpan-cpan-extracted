package DBIx::QuickORM::STH::Fork;
use strict;
use warnings;

our $VERSION = '0.000021';

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
    <pipe
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::STH::Fork - Statement handle backed by a forked child process.

=head1 DESCRIPTION

An asynchronous statement-handle variant whose query runs in a forked child
process that streams JSON-encoded messages back over a pipe. The first message
carries the driver result; each subsequent message is one row. C<ready> peeks
the pipe without blocking, C<result> and row fetches block on it. Finalizing
the handle drains the pipe, reaps the child, and releases the connection's
fork slot; cancelling additionally signals the child with C<TERM>.

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
}

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
    if (defined $msg) {
        my $row = decode_json($msg);
        return $row if $row;
    }

    $self->set_done;

    return;
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

    croak "Got invalid data from pipe: " . (defined($msg) ? $msg : '<eof>');
}

=pod

=item $sth->set_done

Drain the pipe, reap the child, release the fork slot, and mark the handle
done. Idempotent.

=back

=cut

sub set_done {
    my $self = shift;

    return if $self->{+DONE};

    delete $self->{+PIPE};
    waitpid($self->{+PID}, 0) if $self->{+PID};
    $self->clear;
    $self->{+DONE} = 1;
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
