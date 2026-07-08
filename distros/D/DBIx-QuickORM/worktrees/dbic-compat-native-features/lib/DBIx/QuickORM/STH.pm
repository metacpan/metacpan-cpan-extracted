package DBIx::QuickORM::STH;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;

use Role::Tiny::With qw/with/;

with 'DBIx::QuickORM::Role::STH';

use Object::HashBase qw{
    <connection
    <dbh
    <sth
    <sql
    <source

    only_one
    no_rows

    +dialect
    +ready
    <result
    <done

    on_ready
    +fetch_cb
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::STH - Synchronous statement-handle wrapper.

=head1 DESCRIPTION

Wraps a live C<DBI> statement handle and its result, implementing the
statement-handle iteration contract (see L<DBIx::QuickORM::Role::STH>):
fetch a row factory, pull rows one at a time, and finalize when exhausted.
The synchronous base class treats results as immediately available; the
async and fork subclasses defer them.

When C<only_one> is set, fetching a second row is an error. When C<no_rows>
is set the statement yields no rows. An optional C<on_ready> callback builds
the per-row fetch coderef once the result is available.

=head1 SYNOPSIS

    my $sth = DBIx::QuickORM::STH->new(
        connection => $connection,
        dbh        => $dbh,
        sth        => $dbi_sth,
        sql        => $sql,
        source     => $source,
        result     => $result,
    );

    while (my $row_hr = $sth->next) { ... }

=head1 ATTRIBUTES

=over 4

=item connection

The owning connection.

=item dbh

The C<DBI> database handle.

=item sth

The C<DBI> statement handle.

=item sql

The SQL string that was executed.

=item source

The source the rows belong to.

=item only_one

When true, more than one row is an error.

=item no_rows

When true, the statement is expected to yield no rows.

=item dialect

The dialect, lazily taken from the connection.

=item ready

True once results are available.

=item result

The driver result for the executed statement.

=item done

True once iteration has finished and the handle has been finalized.

=item on_ready

Optional callback invoked with C<($dbh, $sth, $result, $sql)> to build the
per-row fetch coderef.

=back

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $sth->clear

Release any resources tied to the statement. No-op in the synchronous base
class; subclasses override it.

=item $bool = $sth->ready

True once results are available; always true for the synchronous base class.

=item $bool = $sth->got_result

True once a result has been obtained; always true for the synchronous base
class.

=item $dialect = $sth->dialect

The dialect, lazily taken from the connection.

=item $bool = $sth->deferred_result

True when the result is fetched lazily rather than up front. False for the
synchronous base class.

=cut

# {{{ Role::STH interface

sub clear      { }
sub ready      { $_[0]->{+READY} //= 1 }
sub got_result { 1 }

sub dialect { $_[0]->{+DIALECT} //= $_[0]->{+CONNECTION}->dialect }

sub deferred_result { 0 }

# }}} Role::STH interface

=pod

=item $sth->init

Constructor hook that validates required attributes.

=cut

sub init {
    my $self = shift;

    croak "'connection' is a required attribute" unless $self->{+CONNECTION};
    croak "'source' is a required attribute"     unless $self->{+SOURCE};
    croak "'sth' is a required attribute"        unless $self->{+STH};
    croak "'dbh' is a required attribute"        unless $self->{+DBH};
    croak "'result' is a required attribute"     unless exists($self->{+RESULT}) || $self->deferred_result;
}

=pod

=item $row_hr = $sth->next

Return the next row as a hashref, or undef once exhausted. With C<only_one>
set, a second row is an error.

=cut

sub next {
    my $self = shift;
    my $row_hr  = $self->_next;

    if ($self->{+ONLY_ONE}) {
        # Finalize before throwing so the statement (and any async slot on
        # the connection) is released even on the error path.
        if ($self->_next) {
            $self->set_done;
            croak "Expected only 1 row, but got more than one";
        }
        $self->set_done;
    }

    return $row_hr;
}

=pod

=back

=head1 PRIVATE METHODS

=over 4

=item $cb = $sth->_fetch

Build (and cache) the per-row fetch coderef, running C<on_ready> once if set.

=cut

sub _fetch {
    my $self = shift;
    return $self->{+FETCH_CB} if exists $self->{+FETCH_CB};

    if (my $on_ready = $self->{+ON_READY}) {
        return $self->{+FETCH_CB} = $on_ready->($self->{+DBH}, $self->{+STH}, $self->result, $self->{+SQL});
    }

    $self->result;
    $self->{+FETCH_CB} = undef;
    return;
}

=pod

=item $row_hr = $sth->_next

Pull one row from the fetch coderef, finalizing the handle when exhausted.

=item $sth->set_done

Finalize the handle: run any pending C<on_ready>, clear resources, and mark
it done. Idempotent.

=item $sth->DESTROY

Finalize the handle on destruction if it has not already finished.

=back

=cut

sub _next {
    my $self = shift;

    return if $self->{+DONE};

    if (my $fetch = $self->_fetch) {
        my $row_hr = $fetch->();
        return $row_hr if $row_hr;
    }

    $self->set_done;

    return undef;
}

sub set_done {
    my $self = shift;

    return if $self->{+DONE};

    # Do this to make sure on_ready runs if it has not already.
    $self->_fetch;
    $self->clear;

    $self->{+DONE} = 1;
}

sub DESTROY {
    my $self = shift;
    return if $self->{+DONE};
    $self->set_done();
    return;
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
