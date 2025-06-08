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
    ref_is($h->one({id => 1}), $row, "Can fetch row");
    is($row->field('id'), 1, "Got generated primary key");
    ok($row->in_storage, "stored");

    $row->update({name => 'b'});
    is($row->field('name'), 'b', "Got new value");

    my $addr = "$row";
    $row = undef;
    $row = $h->one({id => 1});
    ok("$row" ne $addr, "Got a new ref");
    is($row->field('name'), 'b', "Got new value");

    $row = undef;

    $h->handle(where => {name => 'b'})->update({name => 'c'});
    $row = $h->one({id => 1});
    is($row->field('name'), 'c', "Got new value");

    ok(my $row2 = $h->insert({name => 'ax'}), "Inserted a row");
    is($row2->field('id'), 2, "Generated id 2");
    $row2->delete;

    $h->handle(where => {id => 1})->update(id => 2);
    my $rowx = $h->one({id => 2});
    for ($row, $rowx) {
        is($_->field('id'), 2, "New id");
        is($_->field('name'), 'c', "Name is c");
    }
    ref_is($rowx, $row, "Same ref (Cache was updated)");

    $row->update(name => 'xyz');
    is($row->field('name'), 'xyz', "Updated via row method");

    $row->field(name => 'foo');
    is($row->field('name'), 'foo', "Asking row for field gives the pending value");
    is($row->pending_data->{name}, 'foo', "Value is pending");
    $row->save;
    is($row->field('name'), 'foo', "Got new value");
    ok(!($row->pending_data && $row->pending_data->{name}), "No pending value");
    is($row->stored_data->{name}, 'foo', "Value is stored");

    my $dialect = $h->dialect;
    return unless $dialect->async_supported;

    subtest async => sub {
        like(
            dies { $h->handle(where => {id => 2})->async->update({name => 'a'}) },
            qr/Cannot do an async update without a specific row to update/,
            "cannot do bulk async update"
        );

        my $async = $h->handle(row => $row)->async->update({name => 'a'});
        $async->result;
        is($row->field('name'), 'a', "Changed value using async");
    };
};

done_testing;

