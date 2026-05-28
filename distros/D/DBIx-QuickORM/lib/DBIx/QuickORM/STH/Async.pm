package DBIx::QuickORM::STH::Async;
use strict;
use warnings;

our $VERSION = '0.000021';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use Carp qw/croak/;
use Time::HiRes qw/sleep/;

use parent 'DBIx::QuickORM::STH';
use Object::HashBase qw{
    <got_result
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
    $self->{+READY} = $self->dialect->async_ready(dbh => $self->{+DBH}, sth => $self->{+STH});
    return 0 unless $self->{+READY};

    if ($self->no_rows) {
        $self->next;
        $self->set_done;
    }

    return $self->{+READY};
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
