package DBIx::QuickORM::CAS::Result;
use strict;
use warnings;

our $VERSION = '0.000025';

use Carp qw/croak/;

use overload(
    'bool'   => sub { $_[0]->won },
    '""'     => sub { $_[0]->state },
    fallback => 1,
);

use Object::HashBase qw{
    +sth
    +resolver
    <row
    <changes
    +count
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::CAS::Result - Outcome of a compare-and-set operation.

=head1 DESCRIPTION

The value returned by C<< $handle->cas >> and C<< $row->cas >>. It reports
whether the guarded update matched a row. In boolean context it is true only
on a win, so C<if ($result) { ... }> tells you the update went through.

A compare-and-set can end three ways: it won (exactly one row matched and was
updated), it lost (no row matched, because the guard values had changed or the
row was gone), or the outcome is unknown (the database driver could not report
how many rows were affected). C<lost> and C<unknown> are both false in boolean
context; use C<unknown> to tell a genuine loss apart from a count the driver
would not give.

A result from an async or aside handle starts out pending. C<ready> reports,
without blocking, whether the database has answered yet. Every other method
(and boolean or string context) blocks until the answer is in, resolves once,
and then behaves like a normal result. The row update is applied at resolution
on a win. A synchronous result is already resolved, so C<ready> is true and
nothing ever blocks.

=head1 SYNOPSIS

    my $result = $row->cas([qw/revision/], {body => $new_body});

    if ($result) {
        # won: nobody else changed the row
    }
    elsif ($result->unknown) {
        # driver could not report the affected count
    }
    else {
        # lost: someone changed the guarded values, refetch and retry
    }

    # Async: poll instead of blocking.
    my $pending = $handle->async->cas([qw/revision/], \%changes);
    until ($pending->ready) { ... }
    print "won\n" if $pending->won;

=head1 ATTRIBUTES

=over 4

=item row

The row object the operation targeted. It carries the new values on a win and
is left untouched on a loss or unknown outcome.

=item changes

The changes hashref that was applied (or attempted).

=item sth

=item resolver

Internal: the pending statement handle and the coderef that turns it into the
affected-row count (applying the row update on a win). Both are consumed at
resolution.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $result->ready

True once the result is available: always true for a synchronous result, and
for an async result once the database has answered. Does not block and does not
apply the row update, but it does reap the statement once the database answers,
so a real database error surfaces here rather than being deferred to a later
method.

=item $int = $result->count

The affected row count: C<1> on a win, C<0> on a loss, or C<-1> when the driver
could not report it. Resolves the result first (may block).

=item $bool = $result->won

=item $bool = $result->result

True only on a win (C<count> is 1). This is also the boolean overload.

=item $bool = $result->lost

True on a loss (C<count> is 0).

=item $bool = $result->unknown

True when the driver could not report the affected count (C<count> is -1). The
result is false, but this was not a confirmed loss.

=item $string = $result->state

One of C<'won'>, C<'lost'>, or C<'unknown'>. This is also the string overload.

=back

=head1 PRIVATE METHODS

=over 4

=item $result->_resolve

Block until the count is available, store it, and apply the row update on a win.
A no-op once resolved.

=back

=cut

sub init {
    my $self = shift;
    return if defined $self->{+COUNT};
    croak "A pending result requires 'sth' and 'resolver'"
        unless $self->{+STH} && $self->{+RESOLVER};
}

sub ready {
    my $self = shift;
    return 1 if defined $self->{+COUNT};
    return $self->{+STH}->ready ? 1 : 0;
}

sub count   { $_[0]->_resolve->{+COUNT} }
sub won     { $_[0]->_resolve->{+COUNT} == 1  ? 1 : 0 }
sub lost    { $_[0]->_resolve->{+COUNT} == 0  ? 1 : 0 }
sub unknown { $_[0]->_resolve->{+COUNT} == -1 ? 1 : 0 }
sub result  { $_[0]->won }

sub state {
    my $self = shift;
    $self->_resolve;
    return 'won'     if $self->{+COUNT} == 1;
    return 'unknown' if $self->{+COUNT} == -1;
    return 'lost';
}

sub _resolve {
    my $self = shift;
    return $self if defined $self->{+COUNT};

    my $count = $self->{+RESOLVER}->($self->{+STH});
    croak "Invalid count '" . (defined($count) ? $count : 'undef') . "', expected -1, 0, or 1"
        unless defined($count) && ($count == -1 || $count == 0 || $count == 1);

    $self->{+COUNT} = $count;

    # Drop the statement handle and resolver now that the count is cached;
    # keeping them would pin the live database statement handle and the
    # originating handle/connection for the rest of the result's life.
    delete @{$self}{(STH(), RESOLVER())};

    return $self;
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
