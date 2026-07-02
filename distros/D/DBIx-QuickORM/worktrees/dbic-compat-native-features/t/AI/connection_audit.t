use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Regression tests for Connection fixes: reconnect rebuilding the dialect,
# reconnect guard rails, auto_retry behavior, source(no_fatal), handle(undef),
# and row-manager validation.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/connection_audit.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->do('INSERT INTO users (user_id, name) VALUES (1, ?)', undef, 'bob');
    $dbh->disconnect;
}

sub connect_orm { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, @_) }

sub raw_names {
    my $dbh   = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my $names = $dbh->selectcol_arrayref('SELECT name FROM users ORDER BY name');
    $dbh->disconnect;
    return $names;
}

subtest reconnect_rebuilds_dialect => sub {
    my $con = connect_orm();

    my $old_dialect = $con->dialect;
    $con->reconnect;

    ref_is_not($con->dialect, $old_dialect, "reconnect built a fresh dialect instance");
    ref_is($con->dialect->dbh, $con->dbh, "the new dialect is bound to the new dbh");

    # Transactions must actually function on the new handle.
    my $ok = eval {
        $con->txn(sub {
            ok($con->in_txn, "in_txn true inside a post-reconnect txn");
            $con->handle('users')->insert({name => 'post-reconnect-commit'});
        });
        1;
    };
    my $err = $@;
    ok($ok, "post-reconnect transaction committed without error") or diag $err;
    ok((grep { $_ eq 'post-reconnect-commit' } @{raw_names()}), "committed row visible to an independent connection");

    my $ok2 = eval {
        $con->txn(sub {
            $con->handle('users')->insert({name => 'post-reconnect-rollback'});
            die "force rollback\n";
        });
        1;
    };
    ok(!$ok2, "post-reconnect transaction rolled back via exception");
    ok(!(grep { $_ eq 'post-reconnect-rollback' } @{raw_names()}), "rolled back row really was rolled back on the new handle");
};

subtest reconnect_guards => sub {
    my $con = connect_orm();

    my $txn = $con->txn();
    my $err = dies { $con->reconnect };
    like($err, qr/Cannot reconnect while there are active ORM-managed transactions/, "reconnect croaks with an open managed transaction");
    $txn->rollback;

    # Simulate a previously failed reconnect that left no dbh behind.
    delete $con->{dbh};
    ok(lives { $con->reconnect }, "reconnect survives a missing dbh from a prior failed reconnect");
    ok($con->dbh->ping, "fresh dbh works");
};

subtest source_no_fatal => sub {
    my $con = connect_orm();

    ok($con->source('users'), "source() resolves a known table");

    is($con->source('no_such_table', no_fatal => 1), undef, "no_fatal => 1 returns undef for an unknown table");

    my $err = dies { $con->source('no_such_table') };
    like($err, qr/Could not find the 'no_such_table' table in the schema/, "unknown table croaks without no_fatal");
};

subtest blessed_manager_validation => sub {
    my $con = connect_orm();
    my $orm = $con->orm;

    require DBIx::QuickORM::Connection;

    my $err = dies { DBIx::QuickORM::Connection->new(orm => $orm, manager => bless({}, 'My::Test::NotAManager')) };
    like($err, qr/does not subclass 'DBIx::QuickORM::RowManager'/, "a blessed manager that is not a RowManager croaks");

    require DBIx::QuickORM::RowManager::Cached;
    my $manager = DBIx::QuickORM::RowManager::Cached->new(connection => $con);
    my $con2;
    ok(lives { $con2 = DBIx::QuickORM::Connection->new(orm => $orm, manager => $manager) }, "a real RowManager instance is accepted") or diag $@;
    ref_is($con2->manager, $manager, "the provided manager instance is used");
    ref_is($manager->connection, $con2, "the manager was re-pointed at the new connection");

    require Scalar::Util;
    ok(Scalar::Util::isweak($manager->{connection}), "the manager's connection reference is weak (no cycle)");
};

subtest auto_retry_terminal_failure => sub {
    my $con = connect_orm();

    my $calls = 0;
    my ($err, $warnings);
    $warnings = warns {
        $err = dies { $con->auto_retry(2, sub { $calls++; die "always fails\n" }) };
    };

    is($calls, 3, "auto_retry attempted count + 1 times");
    is($warnings, 2, "warned for each retry, but not for the terminal failure");
    like($err, qr/auto_retry did not succeed \(attempted 3 times\)/, "terminal croak reports the attempt count");
    like($err, qr/always fails/, "terminal croak includes the last exception");
};

subtest handle_undef => sub {
    my $con = connect_orm();

    my $err = dies { $con->handle(undef) };
    like($err, qr/handle\(\) requires a source, a handle, or handle constructor arguments; got undef/, "handle(undef) croaks with a clear message");

    $err = dies { $con->handle() };
    like($err, qr/handle\(\) requires a source/, "handle() with no arguments croaks the same way");
};

done_testing;
