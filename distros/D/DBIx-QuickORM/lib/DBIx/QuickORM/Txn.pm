package DBIx::QuickORM::Txn;
use strict;
use warnings;

our $VERSION = '0.000031';

use Object::HashBase qw{
    <connection
    <name
    <depth
    <caller
    <failed
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Txn - A transaction or savepoint.

=head1 DESCRIPTION

Returned by C<< $orm->txn >>, and given to the block of
C<< $orm->txn(sub { ... }) >>. Finish it with C<commit> or C<rollback>. The
outermost transaction is a database transaction. One opened while another is
open is a savepoint inside it. See L<DBIx::QuickORM/Transactions> for how
transactions affect the rows the ORM holds.

The outermost transaction opens at an explicit isolation level, C<'read
committed'> unless the ORM or the C<txn> call names another (SQLite and
DuckDB have none to set). A savepoint runs at its transaction's level. See
L<DBIx::QuickORM::Manual::Transactions/ISOLATION>.

Only the innermost open transaction may be committed or rolled back. One is
finished once the database has confirmed its commit or rollback.

A statement that fails inside a transaction marks the innermost one failed,
even when the error is caught. Then every statement on the connection
croaks, except the rollback, and C<commit> rolls back instead and croaks.
Rolling back a savepoint clears its mark, so a nested transaction around work
that may fail is the way to recover and go on. See
L<DBIx::QuickORM::Manual::Transactions/"A FAILED STATEMENT">.

An unfinished transaction that goes out of scope is rolled back, together
with any transaction still open inside it, with a warning naming where it was
opened. An async query still pending is cancelled first. If the rollback
fails, the warning says so and the transaction is dropped from the stack
anyway.

Whenever a transaction's outcome is unknown like this, no row cached from inside
the root transaction stays canonical. Rows cached from before it that the
transaction did not touch do. Refresh a row before writing it again.

Row state (C<is_in_db>, C<was_deleted>) then follows the rollback rules, but
that is a guess: the database may have committed. Re-read the rows the
transaction touched.

One still open at program exit is left to the database, which discards it
when the connection closes. One inherited by a forked child does nothing
there, issues no SQL, and croaks if committed or rolled back.

=head1 SYNOPSIS

=head2 Block form

    # Commits when the block returns. An exception rolls back and is rethrown.
    $orm->txn(sub {
        my $bob = $orm->insert(users => {name => 'Bob'});
        $orm->insert(
            posts => {
                user_id => $bob->field('id'),
                title   => 'Hello',
            },
        );
    });

    # Commit or roll back early through the transaction the block is given.
    $orm->txn(sub {
        my $txn = shift;
        $orm->insert(users => {name => 'Temp'});
        $txn->rollback;
    });

=head2 Object form

    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Carol'});
    $txn->commit;

    my $undo = $orm->txn;
    $orm->insert(users => {name => 'Nobody'});
    $undo->rollback;

=head1 ATTRIBUTES

=over 4

=item $conn = $txn->connection

The L<DBIx::QuickORM::Connection> that opened it.

=item $name = $txn->name

Unique within its Connection, and used as a savepoint's name in SQL.

=item $depth = $txn->depth

1 for the outermost transaction, 2 for a savepoint inside it, and so on.

=item $frame = $txn->caller

Where it was opened, as C<caller> returns it: C<[$package, $file, $line]>.

=item $error = $txn->failed

The error of the statement that marked it failed, or undef.

=back

=head1 PUBLIC METHODS

=over 4

=item $txn->commit

Commits the transaction, or releases the savepoint. Returns 1.

On a transaction marked failed it rolls back instead, then croaks.

When the database refuses, the transaction is rolled back and the database's
error rethrown. When the rollback fails too, the transaction is dropped from
the stack, no row cached from inside the root transaction stays canonical, and
the croak says its outcome is unknown.

=item $txn->rollback

Rolls back the transaction or savepoint. Returns 1.

When the database refuses, the transaction stays open and the error is thrown.

=back

Both croak when the transaction is finished, when one opened inside it is
still open, while an async query is pending on the connection, or when called
in a process other than the one that opened it.

=cut

sub commit   { $_[0]->{+CONNECTION}->commit_txn($_[0]) }
sub rollback { $_[0]->{+CONNECTION}->rollback_txn($_[0]) }

=pod

=over 4

=item $where = $txn->opened_at

Where it was opened, as C<"FILE line N">.

=back

=cut

sub opened_at { "$_[0]->{+CALLER}->[1] line $_[0]->{+CALLER}->[2]" }

sub DESTROY {
    my $self = shift;

    # At program exit references to other objects may already be cleared. The database discards the transaction.
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my $conn = $self->{+CONNECTION} or return;
    return unless $conn->pid == $$ && $conn->_is_open($self);

    my $where = $self->opened_at;
    local $@;
    my $ok = eval { $conn->_unwind($self); 1 };
    return warn "The transaction opened at $where went out of scope without commit() or rollback(); it was rolled back\n" if $ok;

    # Nothing can close it once this object is gone, so it leaves the stack either way.
    my $err = $@;
    $conn->_abandon($self);
    warn "The transaction opened at $where went out of scope without commit() or rollback(), and rolling it back failed: $err";
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
