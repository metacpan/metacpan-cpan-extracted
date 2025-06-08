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

    $row->delete;
    ok(!$row->in_storage, "Not stored anymore");
    ok(!$h->one({id => 1}), "Cannot fetch row, it does not exist");

    subtest mass_delete => sub {
        my @rows = map { [$_, $h->insert({name => $_})] } 'b' .. 'e';
        ok($_->[1]->in_storage, "$_->[0] is stored") for @rows;
        $h->delete;
        ok(!$_->[1]->in_storage, "$_->[0] is deleted") for @rows;
        ok(!$h->one({name => $_->[0]}), "Cannot fetch deleted row $_->[0]") for @rows;
    };

    subtest selective_delete => sub {
        my @rows = map { [$_, $h->insert({name => $_})] } 'b' .. 'e';
        ok($_->[1]->in_storage, "$_->[0] is stored") for @rows;
        $h->delete({name => {-in => ['c', 'd']}});
        ok(!$_->[1]->in_storage, "$_->[0] is deleted") for @rows[1,2];
        ok(!$h->one({name => $_->[0]}), "Cannot fetch deleted row $_->[0]") for @rows[1,2];
        ok($_->[1]->in_storage, "$_->[0] is still stored") for @rows[0,3];
        ok($h->one({name => $_->[0]}), "fetched row $_->[0]") for @rows[0,3];
    };

    my $dialect = $h->dialect;
    return unless $dialect->async_supported;

    # Clear out the db
    $h->delete();

    subtest async => sub {
        if ($dialect->supports_returning_delete) {
            my @rows = map { [$_, $h->insert({name => $_})] } 'b' .. 'e';
            ok($_->[1]->in_storage, "$_->[0] is stored") for @rows;

            my $async = $h->async->delete(name => {-in => ['c', 'd']});

            # Block
            $async->result;
            ok($async->ready, "async is ready");

            ok(!$_->[1]->in_storage, "$_->[0] is deleted") for @rows[1,2];
            ok(!$h->one({name => $_->[0]}), "Cannot fetch deleted row $_->[0]") for @rows[1,2];
            ok($_->[1]->in_storage, "$_->[0] is still stored") for @rows[0,3];
            ok($h->one({name => $_->[0]}), "fetched row $_->[0]") for @rows[0,3];
        }
        else {
            like(
                dies { $h->async->delete },
                qr/Cannot do an async delete without a specific row to delete on a database that does not support 'returning on delete'/,
                "cannot do bulk async delete without returning on delete"
            );
        }
    };
};

done_testing;

