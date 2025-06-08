use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use lib 't/lib';
use DBIx::QuickORM::Test;

skip_all "ORM column names being different from DB names not yet supported";

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';

        schema my_schema => sub {
            table example => sub {
                primary_key 'my_id';
                column my_id   => sub { db_name 'id';   affinity 'numeric' };
                column my_name => sub { db_name 'name'; affinity 'string' };
                column my_uuid => sub { db_name 'uuid'; affinity 'binary'; type 'UUID' };
                column my_json => sub { db_name 'data'; affinity 'string'; type 'JSON' };
            };
        };
    };

    my $uuid = DBIx::QuickORM::Type::UUID->new;
    my $uuid_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($uuid, 'binary');

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    my $s = $orm->source('example');
    ok(my $row = $s->insert({my_name => 'a', my_uuid => $uuid, my_json => {name => 'a'}}), "Inserted a row");

    subtest uuid => sub {
        is($row->row_data->{stored}->{my_uuid}, $uuid_bin, "Stored as binary");
        isnt($row->row_data->{stored}->{my_uuid}, $uuid, "Sanity check that original uuid and binary do not match");
        is($row->field('my_uuid'), $uuid, "Round trip returned the original UUID, no loss");
        ref_is($s->one({my_uuid => $uuid}),   $row, "Found a by UUID string");
        ref_is($s->one({my_uuid => $uuid_bin}), $row, "Found a by UUID binary");
    };

    subtest json => sub {
        like($row->row_data->{stored}->{my_json}, qr/{"name":\s*"a"}/, "Stored the json as json");
        is($row->field('my_json'), {name => 'a'}, "Round trip returned the correct data structure");
        ok(lives { $s->one({my_json => bless({name => 'a'}, 'DBIx::QuickORM::Type::JSON')}) }, "JSON object in the search does not die (but is also not useful)");
    };

    my $uuid2 = DBIx::QuickORM::Type::UUID->new;
    my $uuid2_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($uuid, 'binary');

    $row->update({my_uuid => $uuid2, my_json => {name => 'a2'}});
    $row->refresh;
    is($row->field('my_uuid'), $uuid2, "updated uuid");
    is($row->field('my_json'), {name => 'a2'}, "updated json");
};

done_testing;

