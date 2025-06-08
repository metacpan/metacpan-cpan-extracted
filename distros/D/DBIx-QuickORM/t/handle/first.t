use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use lib 't/lib';
use DBIx::QuickORM::Test;

sub SCHEMA_DIR { 't/handle/schema' }

do_for_all_dbs {
    my $db = shift;

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
    my $h = $orm->handle('example');
    ok(my $row = $h->insert({name => 'a'}), "Inserted a row");
    is($row->field('id'), 1, "Got generated primary key");

    my $row_clone = $h->first({id => 1});
    ref_is($row_clone, $row, "Got the same ref using first({id => 1})");

    my $row_clone2 = $h->first(id => 1);
    ref_is($row_clone2, $row, "Got the same ref using first(id => 1)");

    my $ref = "$row";
    $row        = undef;
    $row_clone  = undef;
    $row_clone2 = undef;

    $row = $h->first({name => 'a'});
    ok("$row" ne $ref, "Got a new ref since all previous ones expired");
    is($row->field('id'), 1, "Got the right ID");

    my $data = $h->data_only->first({id => 1});
    ref_ok($data, 'HASH', "Got a hashref");
    like(
        $data,
        {id => 1, name => 'a'},
        "Got just the data",
    );

    # sqlite does not support async
    unless (curdialect() =~ m/sqlite/i) {
        subtest async => sub {
            my $h = $orm->handle('example');
            $h->insert({name => 'b'});

            $h = $h->async;
            my $row = $h->first({name => 'b'});
            isa_ok($row, ['DBIx::QuickORM::Row::Async'], "Got an async row");
            sleep 0.1 until $row->ready;
            is($row->field('name'), 'b', "Got field 'b' value");

            isa_ok($row, ['DBIx::QuickORM::Row'], "Row is 'normal'");
        };

        subtest aside => sub {
            my $h = $orm->handle('example');
            $h->insert({name => 'c'});

            $h = $h->aside;
            my $row = $h->first({name => 'c'});
            isa_ok($row, ['DBIx::QuickORM::Row::Async'], "Got an async row");
            sleep 0.1 until $row->ready;
            is($row->field('name'), 'c', "Got field 'c' value");

            isa_ok($row, ['DBIx::QuickORM::Row'], "Row is 'normal'");
        };

        subtest forked => sub {
            my $h = $orm->handle('example');
            $h->insert({name => 'd'});

            $h = $h->forked;
            my $row = $h->first({name => 'd'});
            isa_ok($row, ['DBIx::QuickORM::Row::Async'], "Got an async row");
            sleep 0.1 until $row->ready;
            is($row->field('name'), 'd', "Got field 'd' value");

            isa_ok($row, ['DBIx::QuickORM::Row'], "Row is 'normal'");
        };
    }
};

done_testing;

