package DBIx::Loop;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('DBIx::Loop', $VERSION);

use DBI;
use DBIx::Loop::Future;

=head1 NAME

DBIx::Loop - non-blocking DBI on your event loop

=head1 VERSION

Version 0.01

=cut

# connect() is a thin convenience over DBI->connect + new(): the DBI connect is
# irreducibly DBI's Perl API. Everything else - the object, capability probe,
# query/do dispatch, disconnect, and DBIx::Loop::Future - is XS/C.
sub connect {
    my $class = shift;
    my ($dsn, $user, $pass, $attr, @opt) = @_;
    my %opt = @opt;
    $opt{loop} = $class->_auto_loop
        if ($opt{loop} || '') eq 'auto';
    my $dbh = DBI->connect($dsn, $user, $pass, $attr);
    # keep the connect args so the pool's workers can open their own handles
    return $class->new(
        dbh  => $dbh,
        dsn  => $dsn, user => $user, pass => $pass, attr => $attr,
        %opt,
    );
}

# The DBI select* family is XS (xs/loop.xs): each is query() plus one fixed
# reshape of the result, done as a builtin continuation rather than a Perl
# closure, so nothing is compiled per call and no Perl frame runs when the
# result lands.

sub _auto_loop {
    my ($class) = @_;
    if ($INC{'Mojo/IOLoop.pm'}) {
        require DBIx::Loop::Loop::Mojo;
        return DBIx::Loop::Loop::Mojo->new;
    }
    if ($INC{'IO/Async/Loop.pm'}) {
        require DBIx::Loop::Loop::IOAsync;
        return DBIx::Loop::Loop::IOAsync->new;
    }
    if ($INC{'AnyEvent.pm'}) {
        require DBIx::Loop::Loop::AnyEvent;
        return DBIx::Loop::Loop::AnyEvent->new;
    }
    Carp::croak("DBIx::Loop: loop => 'auto' found no loaded event loop "
        . "(Mojo::IOLoop / IO::Async::Loop / AnyEvent) - load one first or "
        . "pass loop => \$adapter");
}

1;

__END__

=head1 SYNOPSIS

    use DBIx::Loop;
    use DBIx::Loop::Loop::IOAsync;

    my $adapter = DBIx::Loop::Loop::IOAsync->new;
    my $db = DBIx::Loop->connect(
        'dbi:SQLite:dbname=app.db', '', '',
        { RaiseError => 1 },
        loop => $adapter, workers => 4,
    );

    # non-blocking: the query runs on a pool worker (or, for Pg, on the
    # connection's own socket) while the loop keeps serving
    $db->query("SELECT * FROM pets WHERE id = ?", $id)->on_ready(sub {
        my $res = shift->get;   # { rows => [[...],...], columns => [...] }
        ...
    });

    # transactions, pinned to one connection
    $db->txn(sub {
        my ($tx) = @_;
        $tx->do("INSERT INTO pets (name) VALUES (?)", 'rex')
           ->then(sub { $tx->do("UPDATE counts SET pets = pets + 1") });
    })->on_ready(sub { ... });

=head1 DESCRIPTION

DBIx::Loop runs DBI queries without blocking an event loop, behind one
future-returning API. It is about B<concurrency and latency isolation>, not
per-query speed. DBD::SQLite and DBD::Pg already sit at parity with their C
libraries (a direct-libsqlite3 comparison showed a dead heat), but a blocking
query inside an event-driven server stalls every connection on that worker.
DBIx::Loop keeps the loop live.

DBIx::Loop is B<not an event loop and ships none> - you always supply a loop
adapter (L<IO::Async|DBIx::Loop::Loop::IOAsync>,
L<Mojo::IOLoop|DBIx::Loop::Loop::Mojo>,
L<AnyEvent|DBIx::Loop::Loop::AnyEvent>, Hyperman, ...). The engine - object,
capability probe, both backends, transactions, and L<DBIx::Loop::Future> - is
C.

=head1 THE TWO BACKENDS

DBI has no standard async API, so DBIx::Loop carries two backends behind the
one interface and picks per driver at connect time (see L</capability>):

=over 4

=item * B<The worker pool> (universal). For drivers with no async surface -
SQLite is the extreme: in-process, synchronous, un-yieldable - the blocking
call runs on a forked worker holding its own connection, framed over a
socketpair the loop watches. Works with every DBD. Workers use
C<prepare_cached>, crashed workers respawn (a storm cap applies), and
C<max_queue> bounds backpressure.

=item * B<Native fd async> (Pg; opt-in fast path). DBD::Pg exposes a
non-blocking execute and the connection's socket, so queries fire with
C<pg_async>, the loop watches C<pg_socket>, and results collect on readiness -
no workers, no serialization. One query per connection is in flight (a libpq
limit); the rest queue.

=back

Either way the result is the same shape: C<query> resolves to
C<< { rows => [ [...], ... ], columns => [ ... ] } >> (arrayref rows - they
benchmarked ~4x faster to build than hashrefs) and C<do> to
C<< { rows_affected => $n, insert_id => $id } >> (insert_id best-effort via
C<last_insert_id>).

=head1 CONSTRUCTORS

=head2 connect

    my $db = DBIx::Loop->connect($dsn, $user, $pass, \%attr,
        loop      => $adapter,   # required; or 'auto'
        workers   => 4,          # pool backend: worker count
        max_queue => 0,          # pool backend: pending cap (0 = unbounded)
    );

Connects via C<< DBI->connect >> and keeps the connect arguments so pool
workers can open their own handles (a live handle cannot cross a fork).
C<< loop => 'auto' >> adapts an already-loaded loop (Mojo::IOLoop, then
IO::Async, then AnyEvent) and croaks when none is loaded - there is no
built-in loop, by design.

=head2 new

    my $db = DBIx::Loop->new(dbh => $dbh, loop => $adapter);

Wrap an existing handle. Without connect arguments the pool backend cannot
fork workers, so queries on a bare wrapped handle run synchronously; use
C<connect> for the non-blocking pool.

=head1 METHODS

=head2 query / do

    my $future = $db->query($sql, @bind);   # SELECT-style: rows + columns
    my $future = $db->do($sql, @bind);      # writes: rows_affected, insert_id

Both return a future immediately. C<< ->on_ready >>, C<< ->then >>,
C<< ->else >> chain; C<< ->get >> returns the result once ready (awaiting a
pending future is the adapter's job: C<< $adapter->await($future) >>).
Failures carry the DBI error string.

=head2 txn

    my $future = $db->txn(sub {
        my ($tx) = @_;
        # $tx->query / $tx->do are pinned to ONE connection
        return $tx->do(...)->then(sub { $tx->do(...) });
    });

Acquires a pool slot (waiting when all are busy), runs C<BEGIN>, calls the
block with a L<DBIx::Loop::Txn> handle pinned to that connection, then
C<COMMIT>s - or C<ROLLBACK>s when the block dies or its returned future fails,
failing the outer future with the original error. The block may return a plain
value or a future; the outer future resolves to it after commit.

Plain C<$db> statements during a transaction run on B<other> slots - they
never join the transaction and never steal its connection. A C<txn> inside a
block is an independent transaction on another slot (beware awaiting one while
its parents hold every slot). If a worker dies mid-transaction the transaction
B<fails> - it is never silently resumed on the respawned connection. Pool
backend only for now; native (Pg) transactions arrive with the native
connection pool.

=head2 The DBI select family

The familiar DBI conveniences exist as async counterparts - same names, same
result shapes, wrapped in a future:

    $db->selectall_arrayref($sql, @bind)   # -> [ [...], [...] ]
    $db->selectrow_arrayref($sql, @bind)   # -> [...] or undef
    $db->selectrow_array($sql, @bind)      # -> (list of first-row values)
    $db->selectrow_hashref($sql, @bind)    # -> { col => val } or undef
    $db->selectcol_arrayref($sql, @bind)   # -> [ first column... ]
    $db->selectall_hashref($sql, $key, @bind)  # -> { key_val => {row} }

Unlike DBI these take C<@bind> directly (no C<\%attr> slot). There is
deliberately no C<prepare>/C<execute>/C<fetchrow_*> statement-handle surface:
C<query>/C<do> subsume prepare+execute+fetch in one round trip, pool workers
already reuse statements via C<prepare_cached>, and row-at-a-time fetching
across an async boundary would cost a round trip per row.

=head2 capability

C<'native'> when the driver has a usable async surface (DBD::Pg with its
async constants loaded), else C<'pool'>. Probed per handle at construction.

=head2 loop / dbh / disconnect

Accessors, and teardown: C<disconnect> reaps pool workers (failing any
in-flight or queued futures with a clear message) and closes the handle.

=head1 LOOP ADAPTERS

An adapter is five methods - C<add_reader($fd,$cb)>, C<add_writer($fd,$cb)>,
C<remove($fd)>, C<timer($after,$cb)>, C<new_future()> - plus C<await> and, on
loops with a native future type, C<to_native> to bridge a query future into
that ecosystem (IO::Async C<Future>, C<Mojo::Promise>, AnyEvent condvar). One
conformance suite (t/lib/AdapterConformance.pm) proves every adapter behaves
identically. Adapters with a C-side loop (Hyperman) can install a C vtable so
readiness dispatches with no Perl call frame.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
