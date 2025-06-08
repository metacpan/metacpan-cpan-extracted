use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use Scalar::Util qw/blessed/;
use Time::HiRes qw/sleep/;

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    if (curdialect() =~ m/sqlite/i) {
        skip_all "Skipping for sqlite...";
        return;
    }

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    ok(my $row = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");
    ok(my $row2 = $orm->handle('example')->insert({name => 'b'}), "Inserted a row");
    ok(my $row3 = $orm->handle('example')->insert({name => 'c'}), "Inserted a row");

    my $async = $orm->async(
        example => (
            where  => {name => 'a'},
            fields => ['name', 'id', curdialect() =~ m/PostgreSQL/ ? \'pg_sleep(1)' : \'SLEEP(1)']
        )
    )->first;
    my $other_ref = $async;

    my $nasync = $orm->in_async;

    my $counter = 0;
    my $ready;
    until($ready = $async->ready) {
        $counter++;
        sleep 0.1 if $counter > 1;
    }

    ok($nasync, "We were in a sync query back when we stashed the value");
    ok(!$orm->in_async, "Async query is over");

    ok($counter > 1, "We waited at least once ($counter)");

    ok(blessed($ready), 'DBIx::QuickORM::Row', "Row was returned from ready()");
    ref_is($ready, $row, "same ref");

    is(blessed($async), 'DBIx::QuickORM::Row::Async', "Still async");
    my $copy = $async->row;
    is($async->field('name'), 'a', "Can get value");
    is(blessed($async), 'DBIx::QuickORM::Row', "Not async anymore!");
    ref_is($async, $row, "Same ref");
    ref_is($copy, $row, "Same ref");

    is(blessed($other_ref), 'DBIx::QuickORM::Row::Async', "Other ref is unchanged");

    my $async2 = $orm->async(example => (where => {name => 'b'}))->one;
    is($async2->field('name'), 'b', "Got b");

    my $async3 = $orm->async(example => (where => {}))->one;

    like(
        dies { sleep 0.1 until $async3->ready },
        qr/Expected only 1 row, but got more than one/,
        "used one() but got multiple rows"
    );

    my $async4 = $orm->async(example => (where => {}, order_by => ['name']))->iterator;
    is($async4->next->field('name'), 'a', "Got a");
    is($async4->next->field('name'), 'b', "Got b");
    is($async4->next->field('name'), 'c', "Got c");
    is($async4->next, undef, "Out of rows");
    is($async4->next, undef, "Out of rows");
};

done_testing;
