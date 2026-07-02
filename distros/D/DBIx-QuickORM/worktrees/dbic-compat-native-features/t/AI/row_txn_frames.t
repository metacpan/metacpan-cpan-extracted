use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises the row-state frame model in
# DBIx::QuickORM::Connection::RowData: a frame committed by a savepoint must
# merge only into the frame immediately below it, so it is still discarded
# when an enclosing transaction rolls back. Also covers carrier-frame fill
# (the stack mirrors transaction nesting) and row invalidation when a row
# inserted inside a savepoint loses its enclosing transaction.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/frames.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE widgets (widget_id INTEGER PRIMARY KEY, name TEXT NOT NULL, size INTEGER)');
    $dbh->disconnect;
}

sub db_value {
    my ($col, $pk) = @_;
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($val) = $dbh->selectrow_array("SELECT $col FROM widgets WHERE widget_id = ?", undef, $pk);
    $dbh->disconnect;
    return $val;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('widgets');

subtest committed_savepoint_discarded_by_outer_rollback => sub {
    my $row = $h->insert({name => 'original', size => 1});
    my $pk  = $row->field('widget_id');

    my $outer = $con->txn;
    $row->refresh;

    my $sp = $con->txn;
    $row->field(name => 'savepoint_edit');
    $row->save;
    $sp->commit;

    # No row access between the savepoint commit and the outer rollback, so
    # frame resolution happens only after the rollback.
    $outer->rollback;

    is($row->field('name'), 'original', "in-memory row reverted to pre-transaction data");
    is(db_value(name => $pk), 'original', "database reverted to pre-transaction data");
    ok(!$row->has_pending, "no pending data leaked through the rollback");
};

subtest committed_savepoint_discarded_after_early_resolution => sub {
    my $row = $h->insert({name => 'original', size => 2});
    my $pk  = $row->field('widget_id');

    my $outer = $con->txn;
    $row->refresh;

    my $sp = $con->txn;
    $row->field(name => 'savepoint_edit');
    $row->save;
    $sp->commit;

    # Touch the row before the outer rollback so the committed savepoint
    # frame is merged down while the outer transaction is still open.
    is($row->field('name'), 'savepoint_edit', "saved savepoint data visible inside the outer transaction");

    $outer->rollback;

    is($row->field('name'), 'original', "in-memory row reverted to pre-transaction data");
    is(db_value(name => $pk), 'original', "database reverted to pre-transaction data");
};

subtest insert_during_savepoint_outer_rollback_invalidates => sub {
    for my $touch (0, 1) {
        my $label = $touch ? "early resolution" : "late resolution";

        my $outer = $con->txn;
        my $sp    = $con->txn;
        my $row   = $h->insert({name => 'doomed', size => 3});
        $sp->commit;

        is($row->field('name'), 'doomed', "row usable after savepoint commit ($label)") if $touch;

        $outer->rollback;

        ok(!$row->is_valid, "row invalid after outer rollback ($label)");
        like(dies { $row->field('name') }, qr/This row is invalid/, "row access dies ($label)");
    }
};

subtest insert_during_savepoint_savepoint_rollback_invalidates => sub {
    my $outer = $con->txn;
    my $sp    = $con->txn;
    my $row   = $h->insert({name => 'doomed', size => 4});
    $sp->rollback;

    ok(!$row->is_valid, "row invalid after the savepoint that inserted it rolled back");

    $outer->rollback;
    ok(!$row->is_valid, "row still invalid after the outer rollback");
};

subtest fetch_during_savepoint_fill_protects_base => sub {
    my $row = $h->insert({name => 'fillme', size => 5});
    my $pk  = $row->field('widget_id');

    # Two levels of nesting with no access to OUR row in the outer txn: the
    # refresh inside the inner savepoint must get a carrier frame for the
    # outer txn, so the inner commit cannot leapfrog into the base frame.
    my $outer = $con->txn;

    # Unrelated query so DBD::SQLite issues its deferred BEGIN before the
    # savepoint is created (a savepoint issued first would itself become the
    # outermost transaction and RELEASE would commit it).
    $h->count;

    my $sp = $con->txn;
    $row->refresh;
    $row->update({name => 'inner_edit'});
    $sp->commit;
    $outer->rollback;

    is($row->field('name'), 'fillme', "base data intact after outer rollback");
    is(db_value(name => $pk), 'fillme', "database matches");
};

subtest commit_chain_merges_step_by_step => sub {
    my $row = $h->insert({name => 'stepwise', size => 6});
    my $pk  = $row->field('widget_id');

    my $outer = $con->txn;
    $row->refresh;
    my $sp = $con->txn;
    $row->update({name => 'stepwise_2'});
    $sp->commit;
    $outer->commit;

    is($row->field('name'), 'stepwise_2', "data survives when every transaction commits");
    is(db_value(name => $pk), 'stepwise_2', "database matches");
    ok($row->is_valid, "row still valid");
};

subtest pending_edit_during_savepoint_rolls_back => sub {
    my $row = $h->insert({name => 'pending_sp', size => 7});

    my $outer = $con->txn;
    $row->refresh;

    my $sp = $con->txn;
    $row->field(name => 'staged');
    ok($row->has_pending, "edit staged inside the savepoint");
    is($row->field('name'), 'staged', "staged value visible");
    $sp->rollback;

    ok(!$row->has_pending, "savepoint rollback discarded the staged edit");
    is($row->field('name'), 'pending_sp', "field reads the stored value again");

    $outer->rollback;
};

subtest pending_edit_in_outer_txn_survives_savepoint_rollback => sub {
    my $row = $h->insert({name => 'pending_outer', size => 8});

    my $outer = $con->txn;
    $row->refresh;
    $row->field(name => 'outer_edit');

    my $sp = $con->txn;
    $sp->rollback;

    ok($row->has_pending, "outer-transaction edit survived the savepoint rollback");
    is($row->field('name'), 'outer_edit', "staged value still visible");

    $outer->rollback;
    ok(!$row->has_pending, "outer rollback discarded the edit");
    is($row->field('name'), 'pending_outer', "back to the stored value");
};

subtest pending_edit_no_txn_unchanged => sub {
    my $row = $h->insert({name => 'no_txn', size => 9});

    $row->field(name => 'edited');
    ok($row->has_pending, "edit staged with no transaction open");
    is($row->field('name'), 'edited', "staged value visible");
    is($row->stored_field('name'), 'no_txn', "stored value unchanged");

    $row->discard;
    ok(!$row->has_pending, "discard removed the staged edit");
};

subtest update_during_savepoint_rolls_back => sub {
    my $row = $h->insert({name => 'upd_sp', size => 10});
    my $pk  = $row->field('widget_id');

    my $outer = $con->txn;
    $row->refresh;

    my $sp = $con->txn;
    $row->update({name => 'upd_inner'});
    is($row->field('name'), 'upd_inner', "update applied inside savepoint");
    $sp->rollback;

    is($row->field('name'), 'upd_sp', "savepoint rollback reverted the update in memory");

    $outer->rollback;
    is(db_value(name => $pk), 'upd_sp', "database reverted as well");
};

done_testing;
