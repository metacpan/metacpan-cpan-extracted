use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Time::HiRes();

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill sub { autotype 'JSON' };
        schema my_schema => sub {
            table example => sub {
                column data => sub {
                    affinity 'string';
                    type 'JSON';
                };
            };
        };
    };

    my $orm = orm('my_orm')->connect;
    my $h   = $orm->handle('example');

    ok($h->connection->cas_count_reliable, "cas count is reliable on this connection");

    subtest win_and_lose => sub {
        my $row = $h->insert({name => 'a', revision => 1, data => {n => 1}});

        # Proper CAS advances the guard column (revision) on every write.
        my $res = $h->row($row)->cas([qw/revision/], {revision => 2, data => {n => 2}});
        isa_ok($res, 'DBIx::QuickORM::CAS::Result');
        ok($res,           "won: boolean overload is true");
        is($res->count, 1, "won: count is 1");
        is($res->state, 'won', "won: state");
        ok($res->won && !$res->lost && !$res->unknown, "won: predicates");
        is($res->changes, {revision => 2, data => {n => 2}}, "result carries the changes");
        ref_is($res->row, $row, "result carries the row");
        is($row->field('data'), {n => 2}, "row object updated on win");
        is($row->field('revision'), 2, "guard column advanced on win");

        # A where guard that cannot match -> deterministic loss, no exception.
        my $lose;
        ok(lives { $lose = $h->row($row)->cas({revision => 999}, {revision => 3, data => {n => 3}}) }, "loss does not throw");
        ok(!$lose,           "lost: boolean overload is false");
        is($lose->count, 0,  "lost: count is 0 (not 0E0-true)");
        is($lose->state, 'lost', "lost: state");
        ok($lose->lost && !$lose->won, "lost: predicates");
        is($row->field('data'), {n => 2}, "row object unchanged on loss");
    };

    subtest guard_forms => sub {
        my $row = $h->insert({name => 'forms', revision => 7});

        # single field name (auto-wrapped to an arrayref); advance the guard.
        ok($h->row($row)->cas('revision', {revision => 8, name => 'forms2'}), "single-field-string guard wins");
        is($row->field('name'), 'forms2', "row updated");

        # where hashref guard
        ok($h->row($row)->cas({revision => 8}, {revision => 9, name => 'forms3'}), "where-hashref guard wins");

        # handle already has the where; input is the row
        ok($h->where({revision => 9})->cas($row, {revision => 10, name => 'forms4'}), "where-handle + row input wins");
        is($row->field('name'), 'forms4', "row updated via where-handle form");
    };

    subtest row_wrapper => sub {
        my $row = $h->insert({name => 'wrap', revision => 3});

        my $res = $row->cas([qw/revision/], {revision => 4, name => 'wrapped'});
        ok($res, "row->cas with field list wins");
        is($row->field('name'), 'wrapped', "row updated");

        ok($row->cas('revision', {revision => 5, name => 'wrap2'}), "row->cas with single field wins");
        ok($row->cas({revision => 5}, {revision => 6, name => 'wrap3'}), "row->cas with where hashref wins");

        ok(!$row->cas({revision => 999}, {revision => 7, name => 'never'}), "row->cas loses on bad guard");
        is($row->field('name'), 'wrap3', "row unchanged after loss");
    };

    subtest raw_guard_against_concurrent_change => sub {
        my $row = $h->insert({name => 'conc', revision => 1, data => {k => 'v'}});

        # Guarding on the unchanged JSON value must win: the raw stored value is
        # compared as-is, not deflated a second time (which would double-encode).
        # The write also advances the guarded column.
        ok($h->row($row)->cas([qw/data/], {data => {k => 'v2'}, revision => 2}), "JSON field guard wins when unchanged");

        # A concurrent writer changes the row out from under us. Go straight to
        # the dbh so the row object's stored value is left stale, as it would be
        # if another process had made the change.
        my $raw = $h->connection->dbh;
        $raw->do("UPDATE example SET data = ? WHERE name = ?", undef, '{"k":"other"}', 'conc');

        my $res = $h->row($row)->cas([qw/data/], {data => {k => 'v3'}, revision => 3});
        ok(!$res, "JSON field guard loses after a concurrent change");
        is($res->count, 0, "count 0");
    };

    subtest null_guard => sub {
        my $row = $h->insert({name => 'nullg', revision => 1, data => undef});

        # A field-list guard on a NULL stored value becomes an IS NULL test; the
        # write advances the guard column away from NULL.
        ok($h->row($row)->cas([qw/data/], {data => {y => 1}}), "guard on a NULL stored value wins");
        is($row->field('data'), {y => 1}, "NULL guard win sets the value");

        $h->connection->dbh->do("UPDATE example SET data = ? WHERE name = ?", undef, '{"x":1}', 'nullg');
        ok(!$h->row($row)->cas([qw/data/], {data => {z => 1}}), "guard loses once the value changes underneath");
    };

    subtest guard_must_change => sub {
        my $row = $h->insert({name => 'guardchg', revision => 1});

        # Omitting the guard column from the changes is a CAS anti-pattern (two
        # writers could both win), so cas() warns.
        my $warn = warnings { $h->row($row)->cas([qw/revision/], {name => 'changed'}) };
        like($warn->[0], qr/do not advance any guard column/, "warns when the guard column is not advanced");

        # Setting the guard column to the value it already holds is the same
        # anti-pattern: the guard never changes, so cas() still warns.
        my $same = warnings { $h->row($row)->cas([qw/revision/], {revision => 1, name => 'changed-same'}) };
        like($same->[0], qr/do not advance any guard column/, "warns when the guard column is set to its current value");

        # A where-hashref guard set to its own guard value warns too.
        my $same_where = warnings { $h->row($row)->cas({revision => 1}, {revision => 1, name => 'changed-same2'}) };
        like($same_where->[0], qr/do not advance any guard column/, "warns when a hashref guard is set to its own value");

        # Advancing the guard column is correct usage: no warning.
        my $clean = warnings { $h->row($row)->cas([qw/revision/], {revision => 2, name => 'changed2'}) };
        is(@$clean, 0, "no warning when the guard column advances");
    };

    subtest real_errors_propagate => sub {
        $h->insert({name => 'dupe_a'});
        my $b = $h->insert({name => 'dupe_b', revision => 0});

        # The unique-violation here is intentional; cas() still raises it (which
        # we assert below). Silence DBI's PrintError just for this scope so the
        # expected driver message does not clutter the test output. RaiseError
        # stays on, so the exception is unaffected.
        my $dbh = $h->connection->dbh;
        local $dbh->{PrintError} = 0;

        like(
            dies { $h->row($b)->cas([qw/revision/], {revision => 1, name => 'dupe_a'}) },
            qr/dupe_a|uniqu|constraint|duplicate/i,
            "a real database error is not swallowed by cas",
        );
    };

    subtest async => sub {
        my $row = $h->insert({name => 'async1', revision => 1});

        # Same result class as sync; using it blocks until the database answers.
        my $res = $h->row($row)->async->cas([qw/revision/], {revision => 2, name => 'async2'});
        isa_ok($res, 'DBIx::QuickORM::CAS::Result');
        ok($res, "async cas won (boolean blocks until ready)");
        ok($res->ready, "ready true once resolved");
        is($res->count, 1, "async win count 1");
        is($row->field('name'), 'async2', "row updated after async win");

        # Poll without blocking, then read the outcome.
        my $lose = $h->row($row)->async->cas({revision => 999}, {revision => 3, name => 'never'});
        Time::HiRes::sleep(0.001) until $lose->ready;
        ok(!$lose, "async cas lost");
        is($lose->count, 0, "async loss count 0");
        is($row->field('name'), 'async2', "row unchanged after async loss");
    } if $h->dialect->async_supported;

    subtest croaks => sub {
        my $row = $h->insert({name => 'croaker', revision => 1});

        like(dies { $h->row($row)->cas([qw/revision/], {}) }, qr/changes may not be empty/, "empty changes croaks");
        like(dies { $h->row($row)->cas($row, {revision => 2}) }, qr/where hashref|field-name|field name/, "row handle with a row input croaks");
        like(dies { $h->where({revision => 1})->cas({revision => 1}, {revision => 2}) }, qr/needs a row object/, "where handle without a row input croaks");
        like(dies { $h->cas([qw/revision/], {revision => 2}) }, qr/needs a handle with a row or a where/, "bare handle croaks");
        like(dies { $h->row($row)->cas([qw/nope/], {nope => 2}) }, qr/not a field/, "unknown guard field croaks");
    };
};

subtest cas_count_reliable_unit => sub {
    require DBIx::QuickORM::Dialect;
    ok(DBIx::QuickORM::Dialect->cas_count_reliable({}), "base dialect is always reliable");

    unless (eval { require DBIx::QuickORM::Dialect::MySQL; 1 }) {
        note "DBD::mysql / DBD::MariaDB not available, skipping MySQL dialect checks";
        return;
    }

    my $d = 'DBIx::QuickORM::Dialect::MySQL';
    ok($d->cas_count_reliable({mysql_client_found_rows => 1}), "reliable when on");
    ok($d->cas_count_reliable({}), "reliable when unset (driver defaults on)");
    ok(!$d->cas_count_reliable({mysql_client_found_rows => 0}), "unreliable when explicitly off");
    ok(!$d->cas_count_reliable({mariadb_found_rows => 0}), "unreliable when mariadb flag off");
};

done_testing;
