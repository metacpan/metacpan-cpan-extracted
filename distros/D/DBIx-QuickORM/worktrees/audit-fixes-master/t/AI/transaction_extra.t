use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Extra transaction coverage on plain SQLite, exercising documented behavior in
# DBIx::QuickORM::Manual::Transactions that t/transactions.t does not assert on
# the SQLite path: real persistence (verified via an independent DBI handle),
# savepoint nesting/isolation, callback firing rules, the transaction object's
# state() transitions, DESTROY-time rollback of an abandoned transaction, and
# auto_retry's return value and in-transaction guard.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/txn.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE items (item_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

# Independent connection used to confirm what is actually committed to disk.
# The ORM connection's own dbh would see uncommitted in-transaction writes, so
# we read through a separate handle to verify true persistence.
my $probe = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});

sub disk_names {
    my $rows = $probe->selectcol_arrayref('SELECT name FROM items ORDER BY name');
    return [@$rows];
}

subtest commit_persists => sub {
    ok(!$con->in_txn, "not in a txn to start");

    my $txn = $con->txn(sub {
        my $t = shift;
        ok($con->in_txn,      "in_txn true inside the action");
        ok($con->current_txn, "current_txn set inside the action");
        # Identity assertion (not a deep compare): a transaction now holds a
        # (weak) back-reference to its connection, so a structural compare would
        # recurse through the connection's transaction stack.
        ref_is($con->current_txn, $t, "current_txn is the active txn object");
        ok(!$t->is_savepoint, "top-level txn is not a savepoint");
        is($t->state, 'active', "state is active inside the action");
        $con->handle('items')->insert({name => 'committed'});
    });

    ok(!$con->in_txn,      "in_txn false after commit");
    ok(!$con->current_txn, "current_txn cleared after commit");
    # state() is derived from result: success records 1, so it reports
    # 'committed' once the action returns normally.
    is($txn->state, 'committed', "state transitioned out of active to committed on implicit commit");
    ok($txn->committed, "committed is true");
    ok(!$txn->rolled_back, "rolled_back is false");
    is($txn->result, 1, "result is 1 after commit");

    is(disk_names(), ['committed'], "row persisted to disk after commit");
};

subtest rollback_on_die => sub {
    my $before = disk_names();

    my $err = dies {
        $con->txn(sub {
            $con->handle('items')->insert({name => 'doomed'});
            die "boom\n";
        });
    };

    like($err, qr/boom/, "exception propagated out of txn()");
    is(disk_names(), $before, "row gone from disk after rollback-on-die");
};

subtest savepoint_nesting => sub {
    my $before = disk_names();

    $con->txn(sub {
        my $outer = shift;
        ok(!$outer->is_savepoint, "outer txn is not a savepoint");

        $con->handle('items')->insert({name => 'outer_keep'});

        $con->txn(sub {
            my $inner = shift;
            ok($inner->is_savepoint, "nested txn is a savepoint");
            ref_is_not($inner, $outer, "inner txn is a distinct object");
            $con->handle('items')->insert({name => 'inner_drop'});
            $inner->rollback;
        });

        $con->handle('items')->insert({name => 'outer_keep2'});
    });

    is(
        disk_names(),
        [sort(@$before, 'outer_keep', 'outer_keep2')],
        "outer changes persisted, inner savepoint rollback discarded only its row",
    );
};

subtest callbacks_on_commit => sub {
    my %seen;
    $con->txn(
        action        => sub { $seen{action}++ },
        on_success    => sub { $seen{success}++ },
        on_fail       => sub { $seen{fail}++ },
        on_completion => sub { $seen{completion}++ },
    );
    is(\%seen, {action => 1, success => 1, completion => 1}, "commit fires success+completion, not fail");
};

subtest callbacks_on_rollback => sub {
    my %seen;
    $con->txn(
        action        => sub { $seen{action}++; $_[0]->rollback },
        on_success    => sub { $seen{success}++ },
        on_fail       => sub { $seen{fail}++ },
        on_completion => sub { $seen{completion}++ },
    );
    is(\%seen, {action => 1, fail => 1, completion => 1}, "rollback fires fail+completion, not success");
};

subtest callbacks_added_to_object => sub {
    my %seen;
    $con->txn(sub {
        my $t = shift;
        $t->add_success_callback(sub { $seen{success}++ });
        $t->add_fail_callback(sub { $seen{fail}++ });
        $t->add_completion_callback(sub { $seen{completion}++ });
    });
    is(\%seen, {success => 1, completion => 1}, "add_*_callback success path");
};

subtest callbacks_added_to_object_fail => sub {
    my %seen;
    $con->txn(sub {
        my $t = shift;
        $t->add_success_callback(sub    { $seen{success}++ });
        $t->add_fail_callback(sub       { $seen{fail}++ });
        $t->add_completion_callback(sub { $seen{completion}++ });
        $t->rollback;
    });
    is(\%seen, {fail => 1, completion => 1}, "add_fail_callback + add_completion_callback fire on rollback, success does not");
};

subtest state_rolled_back => sub {
    my $txn = $con->txn(sub { $_[0]->rollback("nope") });
    is($txn->state, 'rolled_back', "state transitioned to rolled_back");
    is($txn->result, 0, "result is 0 after rollback");
    ok($txn->complete, "complete is true after rollback");
};

subtest destroy_rolls_back => sub {
    my $before = disk_names();

    my $warns = warnings {
        my $txn = $con->txn;
        ok($txn->isa('DBIx::QuickORM::Connection::Transaction'), "txn() with no action returns a live txn object");
        is($txn->state, 'active', "long-lived txn starts active");
        $con->handle('items')->insert({name => 'abandoned'});
        # $txn falls out of scope here while still active.
        $txn = undef;
    };

    ok(!$con->in_txn, "connection no longer in a txn after abandoned txn destroyed");
    is(disk_names(), $before, "abandoned active txn was rolled back on DESTROY");

    # DESTROY-driven rollback is a documented safety net and surfaces a
    # diagnostic noting that the transaction fell out of scope.
    ok(
        (grep { $_ =~ /fell out of scope/i } @$warns),
        "DESTROY rollback warns that the dropped txn fell out of scope",
    ) or diag(explain($warns));
};

subtest auto_retry_returns_value => sub {
    my $calls = 0;
    my $out   = $con->auto_retry(sub { $calls++; return 'the-result' });
    is($out, 'the-result', "auto_retry returns the callback result on success");
    is($calls, 1, "auto_retry ran the callback once on immediate success");
};

subtest auto_retry_in_txn_croaks => sub {
    my $err = dies {
        $con->txn(sub {
            $con->auto_retry(sub { 1 });
        });
    };
    like($err, qr/Cannot use auto_retry inside a transaction/, "auto_retry croaks inside an open txn");
};

subtest auto_retry_txn_persists => sub {
    my $before = disk_names();
    my $txn    = $con->auto_retry_txn(sub {
        $con->handle('items')->insert({name => 'via_retry'});
    });
    isa_ok($txn, ['DBIx::QuickORM::Connection::Transaction'], "auto_retry_txn returns a txn object");
    is($txn->result, 1, "auto_retry_txn committed on success");
    is(disk_names(), [sort(@$before, 'via_retry')], "auto_retry_txn persisted the row");
};

subtest destroy_parent_before_child_savepoint_does_not_wedge => sub {
    # Perl does not guarantee the destruction order of lexicals, so a parent
    # transaction can be destroyed while a child savepoint is still live. That
    # must not leave the root BEGIN open and permanently wedge the connection.
    my $h = $con->handle('items');
    {
        local $SIG{__WARN__} = sub {};    # abandoned txns warn on rollback; expected here
        my $inner;
        { my $outer = $con->txn; $inner = $con->txn; }    # parent (root) destroyed first
        undef $inner;                                     # then the orphaned child
    }

    ok(!$con->in_txn, "no transaction is left open after out-of-order destruction");
    is(scalar(grep { defined } @{$con->transactions}), 0, "the transaction stack is empty");

    ok(lives { $con->txn(sub { $h->insert({name => 'after_wedge'}) }) }, "a later transaction still runs");
    ok(scalar(grep { $_ eq 'after_wedge' } @{disk_names()}), "and its work actually persists to disk");
    ok(lives { $con->reconnect }, "reconnect is not blocked by a phantom active transaction");
};

$probe->disconnect;

done_testing;
