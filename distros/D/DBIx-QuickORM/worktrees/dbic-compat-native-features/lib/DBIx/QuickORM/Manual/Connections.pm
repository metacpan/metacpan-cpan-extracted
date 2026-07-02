package DBIx::QuickORM::Manual::Connections;
use strict;
use warnings;

our $VERSION = '0.000027';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Connections - A guide to the connection lifecycle in
L<DBIx::QuickORM>.

=head1 DESCRIPTION

A L<DBIx::QuickORM::Connection> is the live link between your code and the
database: it holds the C<DBI> handle, a connection-local copy of the schema,
the transaction stack, and the per-connection row cache. This guide covers how
you obtain a connection, how it is reconnected, why connections cannot cross a
C<fork>, and how the underlying database link is configured.

=head1 GETTING A CONNECTION

An L<DBIx::QuickORM::ORM> owns the primary connection to its database. You do
not construct a connection directly; you ask the ORM for one.

    my $con = $orm->connection;

C<connection> is a memoized singleton: it builds the connection on first use
and returns the B<same> object every time after that. There is no need to cache
the result yourself - call C<< $orm->connection >> wherever you need it and you
will get the one shared connection.

Most of the time you do not even need to call it explicitly. The ORM proxies
the common entry point for you:

    my $handle = $orm->handle('users');   # same as $orm->connection->handle('users')

If you want a brand new, independent connection instead of the shared one, call
C<connect>:

    my $con = $orm->connect;   # a fresh DBIx::QuickORM::Connection, not cached

The C<quick()> interface returns an already-connected
L<DBIx::QuickORM::Connection> directly, so you can start querying immediately
without building an ORM by hand - see L<DBIx::QuickORM::Manual::QuickStart>.

=head1 RECONNECTING

There are two distinct "reconnect" operations, and they behave differently.

=head2 Connection->reconnect (in-place)

    $con->reconnect;

This swaps out the underlying C<DBI> handle for a fresh one B<on the same
connection object>. The connection object itself - and therefore its row cache,
schema, and the transaction stack - is preserved. The same C<$con> reference
remains valid. This is what you use after a C<fork> (see below), and it is what
C<auto_retry> uses internally to recover from a dropped link.

=head2 ORM->reconnect (drop and rebuild)

    my $con = $orm->reconnect;

This drops the ORM's cached connection entirely and builds a new one from
scratch, returning it. The old connection object - along with its row cache - is
discarded. Any references you were holding to the previous connection now point
at the old, orphaned object, so re-fetch via C<< $orm->connection >>.

To drop the cached connection without immediately rebuilding it, use
C<< $orm->disconnect >>; the next call to C<< $orm->connection >> will build a
fresh one lazily.

In short: C<< $con->reconnect >> keeps everything except the C<dbh>, while
C<< $orm->reconnect >> throws the whole connection (and its
L<cache|DBIx::QuickORM::Manual::Caching>) away and starts over.

=head1 FORK SAFETY

A connection records the PID it was established under, and a C<DBI> handle
B<cannot> be shared across processes. After a C<fork> the child and parent would
otherwise stomp on the same socket. To prevent this, the connection checks the
PID before performing work and throws an exception if it is used from a process
other than the one that created it.

The fix in a forked child is to reconnect in place:

    my $pid = fork // die "fork failed: $!";
    if ($pid == 0) {
        # child
        $con->reconnect;   # gives the child its own dbh, keeps the cache
        ...
        exit 0;
    }

C<< $con->reconnect >> marks the inherited handle C<InactiveDestroy> when it
belongs to another process (so the child does not tear down the parent's
socket), then opens a new handle owned by the child. Each process must do this
for itself before issuing queries.

If you want forked queries managed for you rather than forking by hand, see
L<DBIx::QuickORM::Manual::Async>.

=head1 AUTO-RETRY FOR TRANSIENT FAILURES

Network blips and dropped connections happen. C<auto_retry> runs a block,
retrying it if it throws, and reconnects in place between attempts when the
handle is no longer responding:

    my $result = $con->auto_retry(sub { ... });
    my $result = $con->auto_retry($count => sub { ... });

C<auto_retry> cannot be used inside a transaction (a half-applied transaction
cannot be safely retried). For the transactional case use C<auto_retry_txn>,
which wraps the retried block in a transaction for you. Both are documented in
detail in L<DBIx::QuickORM::Manual::Transactions>.

=head1 CONFIGURING THE CONNECTION

How the C<DBI> handle is actually built is defined by the
L<DBIx::QuickORM::DB> object behind the ORM. There are two ways to specify it.

=head2 Credentials

Provide the pieces and let the ORM call C<< DBI->connect >> for you:

=over 4

=item dsn

The C<DBI> DSN string. When omitted it is built from the dialect and the
connection coordinates (C<host>/C<port>/C<socket> and C<db_name>).

=item user

=item pass

Credentials passed through to C<< DBI->connect >>.

=item attributes

A hashref of C<DBI> attributes. Sensible defaults (C<RaiseError>,
C<PrintError>, C<AutoCommit>, C<AutoInactiveDestroy>) are filled in for you.

=item dbi_driver

The C<DBI> driver name associated with the database.

=back

=head2 A connect callback

Alternatively, supply a C<connect> coderef that returns a fresh C<DBI> handle.
When present it is used instead of the DSN-based path, giving you full control
over how the handle is opened (custom drivers, connection pools, extra setup,
and so on):

    connect => sub { DBI->connect($dsn, $user, $pass, \%attrs) },

Each new handle - whether for the first connection, a reconnect, or a forked
child - is produced the same way: via your callback if you provided one,
otherwise via C<< DBI->connect >> with the resolved DSN and credentials. See
L<DBIx::QuickORM::DB> for the full set of configuration attributes.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Connection>

The connection object itself: transactions, handles, async/aside/forked
queries, and the state operations backing the row cache.

=item L<DBIx::QuickORM::ORM>

The owner of the primary connection.

=item L<DBIx::QuickORM::DB>

The database connection definition.

=item L<DBIx::QuickORM::Manual::Transactions>

Transactions, savepoints, and automatic retry.

=item L<DBIx::QuickORM::Manual::Caching>

The per-connection row cache that reconnecting in place preserves and that
C<< $orm->reconnect >> discards.

=item L<DBIx::QuickORM::Manual::QuickStart>

The C<quick()> interface that hands back a ready connection.

=item L<DBIx::QuickORM::Manual>

The documentation hub.

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
