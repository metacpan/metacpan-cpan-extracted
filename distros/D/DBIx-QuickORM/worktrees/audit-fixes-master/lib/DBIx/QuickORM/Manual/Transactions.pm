package DBIx::QuickORM::Manual::Transactions;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Transactions - A guide to transactions in
L<DBIx::QuickORM>.

=head1 DESCRIPTION

This guide covers transactions in L<DBIx::QuickORM>: starting a transaction,
nesting transactions as savepoints, queuing success / fail / completion
callbacks, controlling a transaction by hand, and automatically retrying work
when a connection is lost.

Transactions are controlled through the connection
(L<DBIx::QuickORM::Connection>). Each transaction or savepoint is represented
by a L<DBIx::QuickORM::Connection::Transaction> object.

This is part of the L<DBIx::QuickORM> documentation; see
L<DBIx::QuickORM::Manual> for the documentation hub.

=head1 BASIC TRANSACTIONS

The simplest way to run a transaction is to pass an action callback to
C<txn()> on the connection:

    $con->txn(sub {
        my $txn = shift;
        $foo->update(...);
        $bar->insert(...);
    });

If the callback returns normally the transaction is committed. If it throws an
exception, the transaction is rolled back and the exception propagates.

C<transaction()> is a full alias for C<txn()>; use whichever reads better.

C<txn()> always returns a L<DBIx::QuickORM::Connection::Transaction> object.
When you pass an action callback the returned object is already complete, so
you can inspect its outcome (see L</"THE TRANSACTION OBJECT"> below).

=head2 MANUAL CONTROL FROM INSIDE THE CALLBACK

The callback receives the transaction object as its only argument. You can end
the transaction early by calling C<commit> or C<rollback> on it; either one
breaks out of the action callback:

    $con->txn(sub {
        my $txn = shift;
        ...
        $txn->rollback if $should_abort;     # exits the callback, rolls back
        ...
        $txn->commit("looks good");          # exits the callback, commits
    });

C<abort> is an alias for C<rollback>. Both C<commit> and C<rollback> accept an
optional reason string.

=head1 NESTED TRANSACTIONS AND SAVEPOINTS

Calls to C<txn()> may be nested. The outermost call starts a real database
transaction; each nested call creates a savepoint instead. Committing an inner
transaction releases its savepoint; rolling one back rolls back to its
savepoint without disturbing the outer transaction.

    $con->txn(sub {            # real transaction
        $foo->insert(...);

        $con->txn(sub {        # savepoint
            $bar->insert(...);
            # rolling this back undoes only $bar's insert
        });

        $baz->insert(...);
    });                        # commit happens here

Use C<is_savepoint> on a transaction object to tell which kind it is.

=head1 CALLBACKS

You can queue callbacks to run when a transaction finishes. They are fired
after the underlying commit or rollback has been issued.

=over 4

=item on_success

Runs only if the transaction commits.

=item on_fail

Runs only if the transaction is rolled back.

=item on_completion

Runs when the transaction finishes, regardless of outcome.

=back

Pass them as parameters to C<txn()>:

    $con->txn(
        on_success    => sub { my $txn = shift; ... },
        on_fail       => sub { my $txn = shift; ... },
        on_completion => sub { my $txn = shift; ... },
        action        => sub { my $txn = shift; ... },
    );

You can also queue callbacks against an existing transaction object directly
with C<add_success_callback>, C<add_fail_callback>, and
C<add_completion_callback>.

=head2 PARENT AND ROOT CALLBACKS

When you are inside a nested transaction you can attach callbacks to an outer
transaction instead of the current one. This is useful when a savepoint wants
to defer work until the enclosing transaction actually commits.

The C<on_parent_*> variants attach to the immediate parent transaction; the
C<on_root_*> variants attach to the outermost (root) transaction no matter how
deeply nested you are:

    $con->txn(
        on_parent_success    => sub { ... },
        on_parent_fail       => sub { ... },
        on_parent_completion => sub { ... },

        on_root_success    => sub { ... },
        on_root_fail       => sub { ... },
        on_root_completion => sub { ... },

        action => sub { ... },
    );

When there is no parent or root transaction above the current one, the
corresponding parent / root callbacks are simply no-ops.

=head1 LONG-LIVED TRANSACTIONS

If you need a transaction that is not bound to a single callback, call C<txn()>
without an action. It returns a live L<DBIx::QuickORM::Connection::Transaction>
object that you control by hand:

    my $txn = $con->txn();
    ...
    $txn->commit;    # or $txn->rollback;

If the transaction object falls completely out of scope and is destroyed while
still open, it is rolled back automatically as a safety net. Never rely on this
for normal flow; commit or roll back explicitly.

=head1 THE TRANSACTION OBJECT

A L<DBIx::QuickORM::Connection::Transaction> exposes its state:

=over 4

=item $txn->state

Returns one of C<active>, C<committed>, or C<rolled_back>. Derived from
C<result>.

=item $txn->committed

=item $txn->rolled_back

True/false/undef booleans derived from C<result>: C<committed> is true after a
successful commit, C<rolled_back> is its inverse, and both return undef while
the transaction is still open.

=item $txn->exception

The exception that forced a rollback, if any. Set when the transaction body
threw or the object fell out of scope; undef for a normal commit or an explicit
C<rollback>.

=item $txn->is_savepoint

True when this transaction is a savepoint (i.e. it was nested inside another
transaction).

=item $txn->result

Undef while the transaction is still open; C<1> after a successful commit, C<0>
after a rollback.

=back

See L<DBIx::QuickORM::Connection::Transaction> for the full interface.

=head1 INSPECTING THE CURRENT TRANSACTION

The connection can tell you whether a transaction is active:

=over 4

=item $con->in_txn

Returns true if any transaction is active. If the transaction is managed by
L<DBIx::QuickORM> the transaction object is returned; if a transaction is open
but not managed by the ORM, a plain true value is returned instead.
C<in_transaction> is an alias.

=item $con->current_txn

Returns the current L<DBIx::QuickORM::Connection::Transaction>, or undef if
none is active. Note that this returns undef for transactions not managed by
the ORM, so do not use it as a generic "am I in a transaction" check; use
C<in_txn> for that. C<current_transaction> is an alias.

=back

=head1 AUTOMATIC RETRY

Some failures (notably a dropped connection) are worth retrying. Two helpers on
the connection handle this.

C<auto_retry> runs a callback, retrying it until it succeeds or a retry count
is exhausted. If the connection appears to be down between attempts it
reconnects before retrying. The default count is C<1> (so up to two attempts
total). It returns whatever the callback returns (in scalar context).

    my $result = $con->auto_retry(sub { ... });
    my $result = $con->auto_retry($count, sub { ... });

C<auto_retry_txn> is the transaction-aware convenience form. It runs the action
inside a transaction and retries the whole transaction on failure. It is
roughly equivalent to:

    $con->auto_retry(sub { $con->txn(sub { ... }) });

Usage:

    $con->auto_retry_txn(sub { my $txn = shift; ... });
    $con->auto_retry_txn(\%params, sub { my $txn = shift; ... });
    $con->auto_retry_txn(%params, action => sub { my $txn = shift; ... });

Use C<< count => $NUM >> to set the maximum number of retries (default C<1>);
all other parameters are passed through to C<txn()>.

B<Important:> C<auto_retry> cannot be used inside an open transaction, and will
croak if you try. Retrying only makes sense around a whole transaction, not in
the middle of one, because a half-applied transaction cannot be safely
replayed. Reach for C<auto_retry_txn> when you want the retry to wrap the
transaction itself.

=head1 TRANSACTIONS AND ROW STATE

Row objects are transaction-aware: a row tracks its data through the
transaction / savepoint stack, so changes made inside a transaction are unwound
correctly when that transaction (or savepoint) rolls back. The mechanics of
this are described elsewhere rather than repeated here; see
L<DBIx::QuickORM::Row> for how a row stages and unwinds pending changes, and
L<DBIx::QuickORM::Connection> for the connection-level details.

=head1 TRANSACTIONS AND ASYNC QUERIES

Transactions and out-of-band queries interact. You cannot start a transaction
while an async query is active, and by default an active aside or forked query
also blocks a new transaction (the C<force>, C<ignore_aside>, and
C<ignore_forks> parameters to C<txn()> relax this). For the full picture of
async, aside, and forked queries and how they relate to transactions, see
L<DBIx::QuickORM::Manual::Async>.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Connection>

The connection object, where transactions are controlled.

=item L<DBIx::QuickORM::Connection::Transaction>

The transaction / savepoint object.

=item L<DBIx::QuickORM::Manual::Async>

Asynchronous, aside, and forked queries and how they interact with
transactions.

=item L<DBIx::QuickORM::Row>

The row object, including transaction-aware row state - pending changes staged
against the current transaction or savepoint that unwind when it rolls back.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

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
