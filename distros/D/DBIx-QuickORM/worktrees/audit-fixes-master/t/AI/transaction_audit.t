use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Regression tests for transaction fixes: auto_retry_txn argument parsing,
# finalize recovery after a failed commit, on_parent_* with no parent,
# double-finalization of cb-managed transactions, and savepoint metadata
# surviving completion.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/transaction_audit.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE things (thing_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->disconnect;
}

sub connect_orm { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, @_) }

subtest auto_retry_txn_forms => sub {
    my $con = connect_orm();

    my $calls = 0;
    my $txn = $con->auto_retry_txn(sub { $calls++ });
    is($calls, 1, "single coderef form ran the action once");
    ok($txn->committed, "single coderef form committed");

    $calls = 0;
    my $done = 0;
    $txn = $con->auto_retry_txn({count => 2, on_completion => sub { $done++ }}, sub { $calls++ });
    is($calls, 1, "(\\\%params, sub) form ran the action once on success");
    is($done, 1, "(\\\%params, sub) form passed params through to txn()");
    ok($txn->committed, "(\\\%params, sub) form committed");

    $calls = 0;
    my $warnings = warns {
        $txn = $con->auto_retry_txn({count => 2}, sub { die "boom\n" unless ++$calls > 2 });
    };
    is($calls, 3, "(\\\%params, sub) form respected count from the params hashref");
    is($warnings, 2, "warned once per retry");
    ok($txn->committed, "retried transaction eventually committed");

    $calls = 0;
    $done  = 0;
    $txn = $con->auto_retry_txn(count => 2, on_completion => sub { $done++ }, action => sub { $calls++ });
    is($calls, 1, "(\%params with action) form ran the action once");
    is($done, 1, "(\%params with action) form passed params through to txn()");

    $calls = 0;
    $txn = $con->auto_retry_txn(2, sub { $calls++ });
    is($calls, 1, "(\$count, sub) form ran the action once");

    $calls = 0;
    $txn = $con->auto_retry_txn(2, {action => sub { $calls++ }});
    is($calls, 1, "(\$count, \\\%params) form ran the action once");

    my $err = dies { $con->auto_retry_txn(2, \"nope") };
    like($err, qr/Not sure what to do with second argument/, "bad second argument croaks");

    # Two-element flat form (action => sub): the first argument is not a count,
    # so it must be parsed as flat params and still retry, not be mistaken for
    # ($count='action', $cb) which numifies to 0 and never retries.
    $calls = 0;
    my $flat_warns = warns {
        $txn = $con->auto_retry_txn(action => sub { die "boom\n" unless ++$calls > 1 });
    };
    is($calls, 2, "(action => sub) flat form retried instead of running once");
    is($flat_warns, 1, "(action => sub) flat form warned once on the retry");
    ok($txn->committed, "(action => sub) flat form eventually committed");
};

{
    package My::Test::FakeAsync;
    sub new { my ($class, %p) = @_; return bless {%p}, $class }
    sub done { $_[0]->{done} }
    sub set_done { $_[0]->{done} = $_[1] }
}

subtest failed_commit_is_recoverable => sub {
    my $con = connect_orm();

    my $txn = $con->txn();
    $con->handle('things')->insert({name => 'wedge'});

    my $fake = My::Test::FakeAsync->new(done => 0);
    $con->{in_async} = $fake;

    my $err = dies { $txn->commit };
    like($err, qr/Cannot stop a transaction while there is an active async query/, "commit during an active async query throws");

    ok(!$txn->complete, "transaction is still open after the failed commit");
    is(scalar(@{$con->transactions}), 1, "transaction is still on the stack");

    $fake->set_done(1);

    ok(lives { $txn->rollback }, "rollback still works after the async query completes") or diag $@;
    ok($txn->complete, "transaction is complete after rollback");
    ok($txn->rolled_back, "transaction rolled back");
    is(scalar(@{$con->transactions}), 0, "transaction stack is clean");
    ok(!$con->dialect->in_txn, "no transaction left open on the database");

    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM things WHERE name = 'wedge'");
    $dbh->disconnect;
    is($count, 0, "the insert really was rolled back");
};

subtest failed_rollback_does_not_leak_a_silent_commit => sub {
    my $con = connect_orm();

    my $txn = $con->txn();
    $con->handle('things')->insert({name => 'sticky'});

    my $fake = My::Test::FakeAsync->new(done => 0);
    $con->{in_async} = $fake;

    my $err = dies { $txn->rollback };
    like($err, qr/Cannot stop a transaction while there is an active async query/, "rollback during an active async query throws");
    ok(!$txn->complete, "transaction is still open after the failed rollback");

    $fake->set_done(1);

    # The failed rollback left the transaction aborted-but-recoverable. A commit
    # must not silently issue a ROLLBACK and report success; it croaks so the
    # caller is not misled into thinking the data committed.
    my $cerr = dies { $txn->commit };
    like($cerr, qr/already been rolled back/, "commit after a failed rollback croaks instead of silently rolling back");
    ok(!$txn->complete, "transaction is still recoverable after the refused commit");

    ok(lives { $txn->rollback }, "an explicit rollback still resolves the transaction") or diag $@;
    ok($txn->rolled_back, "transaction rolled back");
    is(scalar(@{$con->transactions}), 0, "transaction stack is clean");
};

subtest on_parent_callbacks => sub {
    my $con = connect_orm();

    my %fired;
    my $ok = eval {
        $con->txn(
            on_parent_fail       => sub { $fired{parent_fail}++ },
            on_parent_completion => sub { $fired{parent_completion}++ },
            on_root_fail         => sub { $fired{root_fail}++ },
            on_root_completion   => sub { $fired{root_completion}++ },
            action               => sub { die "boom\n" },
        );
        1;
    };
    ok(!$ok, "root transaction failed");
    is(\%fired, {root_fail => 1, root_completion => 1}, "on_parent_* are no-ops without a parent, on_root_* fire on self");

    %fired = ();
    $con->txn(sub {
        $con->txn(
            on_parent_success    => sub { $fired{parent_success}++ },
            on_parent_completion => sub { $fired{parent_completion}++ },
            action               => sub { 1 },
        );
        is(\%fired, {}, "parent callbacks have not fired before the parent completes");
    });
    is(\%fired, {parent_success => 1, parent_completion => 1}, "on_parent_* attach to the real parent when nested");
};

subtest already_complete_croaks => sub {
    my $con = connect_orm();

    my $txn = $con->txn();
    $txn->commit;
    ok($txn->complete, "transaction completed");

    my $err = dies { $txn->commit };
    like($err, qr/Transaction is already complete/, "second commit croaks instead of 'Label not found'");

    $err = dies { $txn->rollback };
    like($err, qr/Transaction is already complete/, "rollback after completion croaks too");
};

subtest savepoint_metadata_survives_completion => sub {
    my $con = connect_orm();

    my $saw;
    $con->txn(sub {
        $con->txn(
            on_completion => sub { my $t = shift; $saw = $t->is_savepoint },
            action        => sub { 1 },
        );
    });

    is($saw, 1, "post-completion callbacks still see is_savepoint true for a savepoint txn");
};

subtest cannot_resolve_outer_txn_from_nested_action => sub {
    my $con = connect_orm();

    # Committing/rolling back an OUTER transaction object from inside a nested
    # action used to unwind (via last QORM_TRANSACTION) to the innermost label
    # and resolve the wrong (inner) transaction. It now croaks, and the whole
    # structure rolls back cleanly.
    my $err = dies {
        $con->txn(sub {
            my $outer = shift;
            $con->txn(sub { $outer->commit });
            $con->handle('things')->insert({name => 'should_not_persist'});
        });
    };
    like($err, qr/outer transaction from within a nested transaction/, "committing an outer txn from a nested action croaks");

    my $err2 = dies {
        $con->txn(sub {
            my $outer = shift;
            $con->txn(sub { $outer->rollback });
        });
    };
    like($err2, qr/outer transaction from within a nested transaction/, "rolling back an outer txn from a nested action croaks");

    ok(!$con->in_txn, "no lingering transaction after the refusals");

    ok(lives {
        $con->txn(sub {
            $con->txn(sub { $con->handle('things')->insert({name => 'nested_ok'}) });
        });
    }, "ordinary nested transactions still work");

    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($bad)  = $dbh->selectrow_array("SELECT COUNT(*) FROM things WHERE name = 'should_not_persist'");
    my ($good) = $dbh->selectrow_array("SELECT COUNT(*) FROM things WHERE name = 'nested_ok'");
    $dbh->disconnect;
    is($bad, 0, "the refused transaction did not persist anything");
    is($good, 1, "the ordinary nested transaction persisted");
};

done_testing;
