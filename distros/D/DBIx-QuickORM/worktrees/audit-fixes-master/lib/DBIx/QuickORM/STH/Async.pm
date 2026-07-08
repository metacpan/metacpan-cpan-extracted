package DBIx::QuickORM::STH::Async;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;
use Role::Tiny::With qw/with/;

# Role::Async composes Role::STH, and this class inherits from DBIx::QuickORM::STH
# (which composes Role::STH) as well, so composing it again here is redundant.
with 'DBIx::QuickORM::Role::Async';

use parent 'DBIx::QuickORM::STH';
use Object::HashBase qw{
    <got_result
    <invalidated
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::STH::Async - Driver-level asynchronous statement handle.

=head1 DESCRIPTION

A L<DBIx::QuickORM::STH> subclass for queries running asynchronously at the
driver level. The result is deferred: C<ready> polls the driver and C<result>
blocks until the result arrives. Finalizing the handle releases the async
slot on the owning connection, and (where the dialect supports it) an
in-flight query can be cancelled.

=head1 SYNOPSIS

    $sth->wait;
    while (my $row_hr = $sth->next) { ... }

=head1 ATTRIBUTES

=over 4

=item got_result

The driver result once it has arrived; absent until then.

=item invalidated

True once the owning connection has reconnected out from under this handle,
closing the driver handle it was running on.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $sth->deferred_result

Always true: the result is fetched lazily.

=item $bool = $sth->cancel_supported

True when the dialect supports cancelling an in-flight async query.

=item $sth->clear

Release the async slot on the owning connection.

=cut

# {{{ Role::STH / Role::Async interface

sub deferred_result { 1 }

sub cancel_supported { $_[0]->dialect->async_cancel_supported }

sub clear { $_[0]->{+CONNECTION}->clear_async($_[0]) }

=item $bool = $sth->invalidated

=item $sth->mark_invalidated

=item $sth->finalize_invalidated

Reconnect support. A driver-level async query runs on the connection's shared
database handle; if the connection reconnects (or disconnects) before the
result is collected, that handle is closed and the query can never complete.
C<mark_invalidated> flags this handle (the connection calls it during
C<reconnect>), C<invalidated> reports the flag, and C<finalize_invalidated>
drives the handle to its terminal state without touching the dead driver
handle. Once invalidated, C<ready> and C<result> croak rather than call the
closed driver.

=cut

sub mark_invalidated { $_[0]->{+INVALIDATED} = 1 }

sub finalize_invalidated {
    my $self = shift;

    # The driver handle is gone; mark the fetch spent so set_done neither reads
    # the dead handle for a result nor runs on_ready for a query that never
    # completed, then finalize (releasing the async slot on the connection).
    $self->{+FETCH_CB} = undef;
    $self->set_done;
}

# }}} Role::STH / Role::Async interface

=pod

=item $sth->cancel

Cancel the in-flight query (when no result has arrived yet) and finalize the
handle.

=cut

sub cancel {
    my $self = shift;

    return if $self->{+DONE};

    unless ($self->ready && defined $self->result) {
        $self->dialect->async_cancel(dbh => $self->{+DBH}, sth => $self->{+STH});

        # The query was cancelled, so there is no result to collect. Mark the
        # fetch spent so set_done's _fetch does not call async_result (e.g.
        # pg_result) on the cancelled query — which croaks — and does not run
        # on_ready (cache maintenance) for a write that never completed.
        $self->{+FETCH_CB} = undef;
    }

    $self->set_done;
}

=pod

=item $result = $sth->result

Block until the driver result is available, caching and returning it.

=cut

sub result {
    my $self = shift;
    return $self->{+GOT_RESULT} if exists $self->{+GOT_RESULT};

    croak "This asynchronous statement handle was invalidated by a database reconnect and can no longer be used"
        if $self->{+INVALIDATED};

    # Blocking
    $self->{+GOT_RESULT} = $self->dialect->async_result(sth => $self->{+STH}, dbh => $self->{+DBH});

    if ($self->no_rows) {
        $self->{+READY} = 1;
        $self->next;
        $self->set_done;
    }

    return $self->{+GOT_RESULT};
}

=pod

=item $bool = $sth->ready

Poll the driver; true once the result is available. Drains a no-row statement
on first readiness.

=back

=cut

sub ready {
    my $self = shift;
    return $self->{+READY} if $self->{+READY};

    croak "This asynchronous statement handle was invalidated by a database reconnect and can no longer be used"
        if $self->{+INVALIDATED};

    $self->{+READY} = $self->dialect->async_ready(dbh => $self->{+DBH}, sth => $self->{+STH});
    return 0 unless $self->{+READY};

    # result() performs the no_rows drain exactly once (it caches GOT_RESULT
    # before finalizing), so on_ready fires a single time; calling next()+
    # set_done() here re-entered _fetch and fired on_ready twice.
    $self->result if $self->no_rows;

    return $self->{+READY};
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
