use Test2::V0;
use File::Temp qw/tempdir/;

# DuckDB tracks its own in-transaction flag because it drives transactions with
# raw BEGIN/COMMIT/ROLLBACK rather than DBI AutoCommit. A COMMIT or ROLLBACK
# that the engine rejects must still clear the flag: otherwise the flag wedges
# on and the next start_txn is refused as "transaction already open". The flag
# is also only meaningful for the dialect's own handle.

BEGIN {
    skip_all "DBD::DuckDB is required for these tests"
        unless eval { require DBD::DuckDB; 1 };
}

require DBIx::QuickORM::Dialect::DuckDB;
require DBI;

my $dir = tempdir(CLEANUP => 1);
my $dbh = DBI->connect("dbi:DuckDB:dbname=$dir/txn.duckdb", '', '', {RaiseError => 1, PrintError => 0});

my $dialect = DBIx::QuickORM::Dialect::DuckDB->new(dbh => $dbh, db_name => 'txn');

subtest failed_rollback_clears_flag => sub {
    $dialect->start_txn;
    ok($dialect->in_txn, "in a transaction after start_txn");

    # Close the engine's transaction behind the dialect's flag, so the flag says
    # "in txn" but the engine has none.
    $dbh->do('COMMIT');

    my $ok = eval { $dialect->rollback_txn; 1 };
    ok(!$ok, "rollback_txn dies when the engine has no active transaction");

    ok(!$dialect->in_txn, "the in-transaction flag is cleared despite the failed rollback");
    ok(eval { $dialect->start_txn; 1 }, "a fresh transaction can be started after the failure");

    $dialect->rollback_txn;
};

subtest alternate_handle_does_not_flip_flag => sub {
    my $other = DBI->connect("dbi:DuckDB:dbname=$dir/txn.duckdb", '', '', {RaiseError => 1, PrintError => 0});

    ok(!$dialect->in_txn, "dialect starts with no transaction");
    $dialect->start_txn(dbh => $other);
    ok(!$dialect->in_txn, "starting a txn on an alternate handle does not set the dialect's own flag");
    $dialect->rollback_txn(dbh => $other);
    $other->disconnect;
};

done_testing;
