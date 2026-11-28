package DBIx::QuickORM::Iterator;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Object::HashBase qw{
    <query
    <state
    +index
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Iterator - Iteration over the rows a query fetched.

=head1 DESCRIPTION

An iterator walks every row a query returned, fetched at once, with its own
position. C<next>, C<first>, C<last>, C<all>, and C<only> hand rows out, and
C<reset> rewinds. Each row is built anew through C<build> every time it is
handed out (the handle makes row objects there).

The rows live in a C<query> hashref that several iterators can share: a
handle's iterators all read its one query, each at its own position.

A pending iterator (from a handle's C<async>, C<aside>, or C<forked>) starts
with a query still running elsewhere and no rows. C<ready> checks on it
without waiting. The reading methods wait for its rows first. Once the result
is there, the rows are collected at once, for every iterator sharing the
query, and the iterator works like any other.

Only the process that started a pending query may collect it. A pending
query may also refuse to be read for now (C<aside> and C<forked> while a
transaction is open): every reading method, C<ready> included, croaks, and the
query stays pending. When the last
iterator over it is freed before it was collected, in that process, the query
is cancelled (a failed cancel warns).

When collecting fails (the query failed, or was cancelled when its
transaction was rolled back) the error is thrown, and every reading method of
every iterator sharing the query throws it again, every time. C<reset> and the
attribute accessors neither wait nor throw.

The C<state> says how many rows the query can rightly return. C<single> (a
foreign key followed to a primary or unique key) croaks when a second row is
asked for. C<multi> forbids C<only>, and undef allows anything.

=head1 SYNOPSIS

    my $it = $orm->handle('users')->order_by('name')->iter;

    my @names;
    while (my $user = $it->next) {
        push @names => $user->field('name');
    }

    $it->reset;              # back to the first row, without running the query again
    my @all   = $it->all;
    my $first = $it->first;

    # The one row, or undef. Croaks when there is more than one.
    my $bob = $orm->handle('users')
        ->where({email => 'bob@example.com'})
        ->iter
        ->only;

    my $later = $orm->handle('users')->async->iter;
    do_something_else() until $later->ready;
    my @rows = $later->all;

=head1 ATTRIBUTES

A constructor argument of the wrong shape croaks.

=over 4

=item \%query = $it->query

Required: the internal state a handle's iterators share (its rows, pending
query, and error). It is not an interface.

=item $state = $it->state

C<single>, C<multi>, or undef (the default).

=item \@rows = $it->rows

=item $code = $it->build

The query's C<rows> and C<build>.

=back

=cut

# The query hashref, shared by every iterator a handle gives out:
#   rows      => \@rows, the row data in order. Required unless pending,
#                undef until a pending query is collected.
#   build     => \&build, called with each row's data as it is handed out.
#                Rows go out as they are without it. Set on collection.
#   pending   => {ready => \&ready, collect => \&collect, cancel => \&cancel},
#                a query still running: ready checks without waiting, collect
#                waits and returns (\@rows, \&build), cancel gives up. At most
#                one of collect and cancel is called, once, never in global
#                destruction. An optional blocked returns why the query
#                cannot be read now, or undef.
#   pid       => the process that may collect the pending query
#   error     => a failed collection's error, rethrown on every read
#   iterators => how many live iterators hold it. The last one freed cancels
#                a pending query.
sub init {
    my $self  = shift;
    my $query = $self->{+QUERY};
    croak "'query' must be a hashref" unless ref($query) eq 'HASH';

    if (my $pending = $query->{pending}) {
        $query->{pid} //= $$;
        croak "'pending' must be a hashref of ready, collect, and cancel code references" if ref($pending) ne 'HASH' || grep { ref($pending->{$_}) ne 'CODE' } qw/ready collect cancel/;
    }
    elsif (!defined $query->{error}) {
        croak "'rows' must be an arrayref" unless ref($query->{rows}) eq 'ARRAY';
    }
    croak "'build' must be a code reference" if defined($query->{build}) && ref($query->{build}) ne 'CODE';

    my $state = $self->{+STATE};
    croak "'state' must be 'single', 'multi', or undef" if defined($state) && $state !~ m/^(?:single|multi)\z/;

    # Counted only once init succeeds, so DESTROY knows this one holds the query.
    $query->{iterators}++;
    $self->{+INDEX} = 0;
}

sub rows  { $_[0]->{+QUERY}->{rows} }
sub build { $_[0]->{+QUERY}->{build} }

=head1 PUBLIC METHODS

=over 4

=item $bool = $it->ready

True when the rows are there.

Always true for an iterator that is not pending. For a pending one it checks
without waiting and collects the rows once the result has arrived, so the
query's error is thrown here. After a failed collection it is true, and the
reading methods throw the error.

=back

=cut

sub ready {
    my $self    = shift;
    my $pending = $self->{+QUERY}->{pending} or return 1;
    $self->_check_pid;
    return 0 unless $pending->{ready}->();
    $self->_collect;
    return 1;
}

=pod

=over 4

=item $it->reset

Rewinds the position to the first row. It does not wait for a pending
iterator's rows, and does not throw a failed collection's error.

=back

=cut

sub reset { $_[0]->{+INDEX} = 0; return }

=pod

=over 4

=item $row = $it->next

The next row, or undef when there are no more.

=back

=cut

sub next {
    my $self = shift;
    $self->_collect;
    my $i = $self->{+INDEX};
    return undef unless $i < @{$self->{+QUERY}->{rows}};
    $self->{+INDEX} = $i + 1;
    return $self->_row($i);
}

=pod

=over 4

=item $row = $it->first

=item $row = $it->last

The first or last row, or undef when there are none. The position is left
alone.

=back

=cut

sub first {
    my $self = shift;
    $self->_collect;
    return @{$self->{+QUERY}->{rows}} ? $self->_row(0) : undef;
}

sub last {
    my $self = shift;
    $self->_collect;
    my $rows = $self->{+QUERY}->{rows};
    return @$rows ? $self->_row($#$rows) : undef;
}

=pod

=over 4

=item @rows = $it->all

Every row. The position is left alone.

=back

=cut

sub all {
    my $self = shift;
    $self->_collect;

    # Checks single once, then builds every row without asking again.
    my ($rows, $build) = @{$self->{+QUERY}}{qw/rows build/};
    $self->_row(1) if @$rows > 1 && ($self->{+STATE} // '') eq 'single';    # croaks
    return @$rows unless $build;
    return map { $build->($_) } @$rows;
}

=pod

=over 4

=item $row = $it->only

The one row, or undef when there are none. Croaks when there are more, and
always under C<multi>.

=back

=cut

sub only {
    my $self = shift;
    $self->_collect;
    croak "only() cannot be used on a multi-row iterator" if ($self->{+STATE} // '') eq 'multi';
    croak "only() found more than one row"                if @{$self->{+QUERY}->{rows}} > 1;
    return $self->first;
}

=head1 PRIVATE METHODS

=over 4

=item $it->_collect

Waits for a pending query's result and stores its rows and C<build> in the
shared query, for every iterator over it. Does nothing for one that is not
pending. An error thrown while collecting is stored there and thrown again on
every later call.

=back

=cut

sub _collect {
    my $self  = shift;
    my $query = $self->{+QUERY};
    die $query->{error} if defined $query->{error};
    return unless $query->{pending};
    $self->_check_pid;
    my $pending = delete $query->{pending};
    return if eval { @{$query}{qw/rows build/} = $pending->{collect}->(); 1 };
    die($query->{error} = $@);
}

=pod

=over 4

=item $it->_check_pid

Croaks unless this process started the query, and with the pending query's
C<blocked> reason when it gives one, before anything is read.

=back

=cut

sub _check_pid {
    my $self = shift;
    my $pid  = $self->{+QUERY}->{pid};
    croak "This iterator's query was started in process $pid; it cannot be read in process $$" unless $pid == $$;
    my $blocked = $self->{+QUERY}->{pending}->{blocked} or return;
    my $why     = $blocked->()                          or return;
    croak $why;
}

=pod

=over 4

=item $row = $it->_row($i)

The row at the index, through C<build>. Croaks for any row but the first
under C<single>.

=back

=cut

sub _row {
    my $self = shift;
    my ($i) = @_;
    croak "This iterator is for a single row (a primary key or unique key lookup), but the query found more than one" if $i && ($self->{+STATE} // '') eq 'single';

    my ($rows, $build) = @{$self->{+QUERY}}{qw/rows build/};
    my $data = $rows->[$i];
    return $data unless $build;
    return $build->($data);
}

sub DESTROY {
    my $self = shift;
    return unless defined $self->{+INDEX};    # init failed: never counted
    my $query = $self->{+QUERY};
    return if --$query->{iterators};          # another iterator still reads it
    return unless $query->{pending} && $query->{pid} == $$;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my $pending = delete $query->{pending};
    local $@;
    eval { $pending->{cancel}->(); 1 } or warn $@;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
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
