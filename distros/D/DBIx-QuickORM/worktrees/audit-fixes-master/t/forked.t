use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use Scalar::Util qw/blessed/;
use Time::HiRes qw/sleep/;

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    # DuckDB is an embedded, single-writer engine: a forked child cannot open
    # the database file the parent already holds, so a forked query deadlocks.
    if (curdialect() =~ m/duckdb/i) {
        skip_all "Skipping for duckdb (embedded single-writer; cross-process forked queries are unsupported)...";
        return;
    }

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';

        if (curdialect() =~ m/MySQL/) {
            socket $db->socket;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/PostgreSQL/) {
            socket $db->dir;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/SQLite/) {
            db_name $db->dir . '/quickdb';
        }
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    ok(my $row = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");
    ok(my $row2 = $orm->handle('example')->insert({name => 'b'}), "Inserted a row");
    ok(my $row3 = $orm->handle('example')->insert({name => 'c'}), "Inserted a row");

    my $sleep;
    if (curdialect() =~ m/PostgreSQL/i) { $sleep = \'pg_sleep(1)' }
    elsif (curdialect() =~ m/(MySQL|MariaDB)/i) { $sleep = \'SLEEP(1)' }

    my $forked = $orm->handle(
        example => (
            where  => {name => 'a'},
            fields => ['name', 'id', $sleep]
        )
    )->forked->first;

    my $forkedC = $orm->handle(
        example => (
            where  => {name => 'a'},
            fields => ['name', 'id', $sleep]
        )
    )->forked->first;

    my $start = Time::HiRes::time();
    my $ready;
    until($ready = $forked->ready) {
        sleep 0.1;
    }
    my $elapsed = Time::HiRes::time() - $start;

    my $startC = Time::HiRes::time();
    my $readyC;
    until($readyC = $forkedC->ready) {
        sleep 0.1;
    }
    my $elapsedC = Time::HiRes::time() - $startC;

    if ($sleep) {
        # Both forked queries carry a server-side one-second sleep and run in
        # separate child processes, so the first wait spans about a second and
        # the second, already in flight, resolves in no more time than the first.
        ok($elapsed >= 0.9, "The first forked query blocked for about a second (${elapsed}s)");
        ok($elapsedC <= $elapsed, "The second forked result resolved no slower than the first (${elapsedC}s)");
    }

    ok($forked->async->pid, "got a pid");

    isa_ok($ready, ['DBIx::QuickORM::Row'], "Row was returned from ready()");
    ref_is($ready, $row, "same ref");

    isa_ok($readyC, ['DBIx::QuickORM::Row'], "Row was returned from ready()");
    ref_is($readyC, $row, "same ref");

    is(blessed($forked), 'DBIx::QuickORM::Row::Async', "Still async");
    my $copy = $forked->row;
    is($forked->field('name'), 'a', "Can get value");
    is(blessed($forked), 'DBIx::QuickORM::Row', "Not async anymore!");
    ref_is($forked, $row, "Same ref");
    ref_is($copy, $row, "Same ref");

    my $forked2 = $orm->handle(example => (where => {name => 'b'}))->forked->one;
    is($forked2->field('name'), 'b', "Got b");

    my $forked3 = $orm->handle(example => (where => {}))->forked->one;

    like(
        dies { sleep 0.1 until $forked3->ready },
        qr/Expected only 1 row, but got more than one/,
        "used one() but got multiple rows"
    );

    my $forked4 = $orm->handle(example => (where => {}, order_by => ['name']))->forked->iterator;
    is($forked4->next->field('name'), 'a', "Got a");
    is($forked4->next->field('name'), 'b', "Got b");
    is($forked4->next->field('name'), 'c', "Got c");
    is($forked4->next, undef, "Out of rows");
    is($forked4->next, undef, "Out of rows");
};

done_testing;
