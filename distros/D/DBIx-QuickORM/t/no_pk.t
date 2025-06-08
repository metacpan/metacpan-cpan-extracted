use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

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
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");

    ok(my $row1 = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");
    ok(my $row2 = $orm->handle('example')->insert({name => 'a'}), "Inserted an identical row");
    ref_is_not($row1, $row2, "Not the same ref, no caching");

    ok($row1->in_storage, "Is in storage");

    like(dies { $row1->delete },              qr/Operation not allowed: the table this row is from does not have a primary key/, "Cannot delete without a pk");
    like(dies { $row1->update },              qr/Operation not allowed: the table this row is from does not have a primary key/, "Cannot update without a pk");
    like(dies { $row1->field(name => 'b') },  qr/Operation not allowed: the table this row is from does not have a primary key/, "Cannot alter without a pk");
    like(dies { $row1->save },                qr/Operation not allowed: the table this row is from does not have a primary key/, "Cannot save without a pk");
    like(dies { $row1->primary_key_hashref }, qr/Operation not allowed: the table this row is from does not have a primary key/, "No primary key");

    is($orm->count('example'), 2, "both rows are in the db");

    my $row3 = $row1->clone;
    ok(!$row3->in_storage, "Clone is not in storage");
    is($row3->field('name'), "a", "Clone has the same name");
    $row3->insert;
    ok($row3->in_storage, "Inserted the clone");
    is($orm->count('example'), 3, "new row is in the db");
};

done_testing;
