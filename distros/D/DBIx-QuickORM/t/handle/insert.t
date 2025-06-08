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
    ok(!$row->stored_data->{xxx}, "Did not fetch 'xxx'");

    ok(my $row2 = $h->insert({name => 'b'}), "Inserted a row");
    is($row2->field('id'), 2, "Got generated primary key");
    ok(!$row2->stored_data->{xxx}, "Did not fetch 'xxx'");

    $h = $h->auto_refresh;

    my $row3 = $h->insert(name => 'c');
    is($row3->field('id'), 3, "Got generated primary key");
    is($row3->stored_data->{xxx}, 'booger', "Fetched 'xxx' database set value");

    # sqlite does not support async
    unless (curdialect() =~ m/sqlite/i) {
        subtest async => sub {
            my $h = $orm->handle('example')->async->auto_refresh;
            my $row4 = $h->insert({name => 'd'});
            isa_ok($row4->async, ['DBIx::QuickORM::STH', 'DBIx::QuickORM::STH::Async'], "Stored async STH");
            isa_ok($row4, ['DBIx::QuickORM::Row::Async', 'DBIx::QuickORM::Row'], "got async row");
            is($row4->stored_data->{xxx}, 'booger', "Fetched auto-populated value");
            isa_ok($row4, ['DBIx::QuickORM::Row'], "Still a row");
            ok(!$row4->isa('DBIx::QuickORM::Row::Async'), "Not an async row ref anymore");
        };

        subtest aside => sub {
            my $h = $orm->handle('example')->aside->auto_refresh;
            my $row5 = $h->insert({name => 'e'});
            isa_ok($row5->async, ['DBIx::QuickORM::STH', 'DBIx::QuickORM::STH::Async', 'DBIx::QuickORM::STH::Aside'], "Stored aside STH");
            isa_ok($row5, ['DBIx::QuickORM::Row::Async', 'DBIx::QuickORM::Row'], "got async row");
            is($row5->stored_data->{xxx}, 'booger', "Fetched auto-populated value");
            isa_ok($row5, ['DBIx::QuickORM::Row'], "Still a row");
            ok(!$row5->isa('DBIx::QuickORM::Row::Async'), "Not an async row ref anymore");
        };

        subtest forked => sub {
            my $h = $orm->handle('example')->forked->auto_refresh;
            my $row6 = $h->insert({name => 'f'});
            isa_ok($row6->async, ['DBIx::QuickORM::STH::Fork'], "Stored forked STH");
            isa_ok($row6, ['DBIx::QuickORM::Row::Async', 'DBIx::QuickORM::Row'], "got async row");
            is($row6->stored_data->{xxx}, 'booger', "Fetched auto-populated value");
            isa_ok($row6, ['DBIx::QuickORM::Row'], "Still a row");
            ok(!$row6->isa('DBIx::QuickORM::Row::Async'), "Not an async row ref anymore");
        };
    }
};

done_testing;

