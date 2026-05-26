use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Verify the connection lifecycle documented in
# DBIx::QuickORM::Manual::Connections: $orm->connection is a memoized
# singleton, $con->reconnect swaps the dbh in place while preserving the
# Connection object (and its cache), transaction state is reflected by
# in_txn/current_txn, and the establishing pid is recorded.
#
# Cross-process fork behavior is intentionally NOT exercised here; that is
# covered by t/fork_safety.t.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/connection.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->do('INSERT INTO users (user_id, name) VALUES (1, ?)', undef, 'bob');
    $dbh->disconnect;
}

sub connect_orm { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, @_) }

subtest connection_is_memoized_singleton => sub {
    my $con = connect_orm();
    my $orm = $con->orm;

    ref_is($orm->connection, $con, "quick() returns the ORM's memoized connection");
    ref_is($orm->connection, $orm->connection, "connection() returns the same object every call");

    my $fresh = $orm->connect;
    ref_is_not($fresh, $con, "connect() builds a brand new, independent connection");
};

subtest orm_reconnect_replaces_connection => sub {
    my $con = connect_orm();
    my $orm = $con->orm;

    my $new = $orm->reconnect;
    ref_is_not($new, $con, "ORM->reconnect drops the cached connection and builds a new one");
    ref_is($orm->connection, $new, "the new connection is now the memoized one");
};

subtest pid_recorded => sub {
    my $con = connect_orm();
    is($con->pid, $$, "connection records the pid it was established under");
    ok($con->pid_check, "pid_check passes in the establishing process");
};

subtest reconnect_in_place_preserves_object_and_cache => sub {
    my $con = connect_orm();

    my $row = $con->handle('users')->one(user_id => 1);
    ok($row, "fetched a row before reconnect");

    my $old_dbh = $con->dbh;

    my $ret = $con;
    $con->reconnect;

    ref_is($ret, $con, "the Connection object reference is unchanged after reconnect");
    ref_is_not($con->dbh, $old_dbh, "the underlying dbh was swapped for a fresh one");
    is($con->pid, $$, "pid still recorded after reconnect");

    # The cache lives on the manager, which is preserved across in-place reconnect.
    my $cached = $con->state_cache_lookup('users', {user_id => 1});
    ref_is($cached, $row, "the row cache is preserved across an in-place reconnect");

    # The new handle is usable.
    my $again = $con->handle('users')->one(user_id => 1);
    ref_is($again, $row, "queries still work and return the cached identity after reconnect");
};

subtest transaction_state_reflected => sub {
    my $con = connect_orm();

    ok(!$con->current_txn, "no current transaction outside a txn");
    ok(!$con->in_txn, "in_txn is false outside a txn");

    $con->txn(sub {
        my $txn = shift;

        my $cur = $con->current_txn;
        ok($cur, "current_txn returns a transaction inside a txn block");
        ref_is($cur, $txn, "current_txn matches the transaction passed to the block");

        my $in = $con->in_txn;
        ok($in, "in_txn is true inside a txn block");
        ref_is($in, $txn, "in_txn returns the managed transaction object");

        $con->txn(sub {
            my $inner = shift;
            ref_is($con->current_txn, $inner, "nested savepoint becomes the current txn");
        });

        ref_is($con->current_txn, $txn, "current_txn restored to outer txn after nested block");
    });

    ok(!$con->current_txn, "current_txn cleared after the txn block exits");
    ok(!$con->in_txn, "in_txn false again after the txn block exits");
};

done_testing;
