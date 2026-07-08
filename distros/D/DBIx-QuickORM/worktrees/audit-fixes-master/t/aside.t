use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use Scalar::Util qw/blessed/;
use Time::HiRes qw/sleep/;

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    if (curdialect() =~ m/sqlite|duckdb/i) {
        skip_all "Skipping for sqlite/duckdb (no async aside support)...";
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
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    ok(my $row = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");
    ok(my $row2 = $orm->handle('example')->insert({name => 'b'}), "Inserted a row");
    ok(my $row3 = $orm->handle('example')->insert({name => 'c'}), "Inserted a row");

    my $aside = $orm->aside(
        example => (
            where  => {name => 'a'},
            fields => ['name', 'id', curdialect() =~ m/PostgreSQL/ ? \'pg_sleep(1)' : \'SLEEP(1)']
        )
    )->first;

    my $asideC = $orm->aside(
        example => (
            where  => {name => 'a'},
            fields => ['name', 'id', curdialect() =~ m/PostgreSQL/ ? \'pg_sleep(1)' : \'SLEEP(1)']
        )
    )->first;

    my $start = Time::HiRes::time();
    my $ready;
    until($ready = $aside->ready) {
        sleep 0.1;
    }
    my $elapsed = Time::HiRes::time() - $start;

    my $startC = Time::HiRes::time();
    my $readyC;
    until($readyC = $asideC->ready) {
        sleep 0.1;
    }
    my $elapsedC = Time::HiRes::time() - $startC;

    # Both queries carry a server-side one-second sleep and run concurrently, so
    # the first wait must span about a second and the second, already in flight,
    # must resolve in no more time than the first did.
    ok($elapsed >= 0.9, "The first async query blocked for about a second (${elapsed}s)");
    ok($elapsedC <= $elapsed, "The second async result resolved no slower than the first (${elapsedC}s)");

    isa_ok($ready, ['DBIx::QuickORM::Row'], "Row was returned from ready()");
    ref_is($ready, $row, "same ref");

    isa_ok($readyC, ['DBIx::QuickORM::Row'], "Row was returned from ready()");
    ref_is($readyC, $row, "same ref");

    is(blessed($aside), 'DBIx::QuickORM::Row::Async', "Still async");
    my $copy = $aside->row;
    is($aside->field('name'), 'a', "Can get value");
    is(blessed($aside), 'DBIx::QuickORM::Row', "Not async anymore!");
    ref_is($aside, $row, "Same ref");
    ref_is($copy, $row, "Same ref");

    my $aside2 = $orm->aside(example => (where => {name => 'b'}))->one;
    is($aside2->field('name'), 'b', "Got b");

    my $aside3 = $orm->aside(example => (where => {}))->one;

    like(
        dies { sleep 0.1 until $aside3->ready },
        qr/Expected only 1 row, but got more than one/,
        "used one() but got multiple rows"
    );

    my $aside4 = $orm->aside(example => (where => {}, order_by => ['name']))->iterator;
    is($aside4->next->field('name'), 'a', "Got a");
    is($aside4->next->field('name'), 'b', "Got b");
    is($aside4->next->field('name'), 'c', "Got c");
    is($aside4->next, undef, "Out of rows");
    is($aside4->next, undef, "Out of rows");
};

done_testing;
