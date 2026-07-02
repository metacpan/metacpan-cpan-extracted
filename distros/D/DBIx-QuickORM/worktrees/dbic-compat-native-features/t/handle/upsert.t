use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

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

    # Upsert is built on ON CONFLICT, which PostgreSQL gained in 9.5. Older
    # servers cannot run these statements at all.
    if (pg_older_than('9.5')) {
        note "Skipping upsert on " . curname() . " (ON CONFLICT requires PostgreSQL 9.5)";
        return;
    }

    my $row2 = $h->upsert({id => $row->field('id'), name => 'b'});
    ref_is($row, $row2, "Same row ref");
    is($row->field('name'), "b", "Upsert!");
    my $row3 = $h->upsert({id => $row->field('id'), name => 'x', xxx => 'c'});
    ref_is($row, $row3, "Same row ref");
    is($row->field('name'), "x", "Upsert name!");
    is($row->field('xxx'), "c", "Upsert xxx!");
};

done_testing;

