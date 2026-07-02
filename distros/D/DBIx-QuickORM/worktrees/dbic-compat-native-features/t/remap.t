use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

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
    my $uuid_bin = DBIx::QuickORM::Type::UUID->qorm_deflate(value => $uuid, affinity => 'binary');

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    my $s = $orm->handle('example');
    ok(my $row = $s->insert({my_name => 'a', my_uuid => $uuid, my_json => {name => 'a'}}), "Inserted a row");
    $row = undef; $row = $s->one(my_name => 'a');

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

        # PostgreSQL's plain `json` type has no equality operator, so searching
        # by a JSON value needs `jsonb`, which arrived in 9.4. Older servers
        # store the column as `json` and would die on the comparison.
        if (pg_older_than('9.4')) {
            note "Skipping JSON-value search on " . curname() . " (json has no = operator before jsonb in 9.4)";
        }
        else {
            ok(lives { $s->one({my_json => bless({name => 'a'}, 'DBIx::QuickORM::Type::JSON')}) }, "JSON object in the search does not die (but is also not useful)");
        }
    };

    my $uuid2 = DBIx::QuickORM::Type::UUID->new;
    my $uuid2_bin = DBIx::QuickORM::Type::UUID->qorm_deflate(value => $uuid2, affinity => 'binary');

    $row->update({my_uuid => $uuid2, my_json => {name => 'a2'}});
    $row->refresh;
    is($row->field('my_uuid'), $uuid2, "updated uuid");
    is($row->field('my_json'), {name => 'a2'}, "updated json");

    subtest rowless_pk_update_cache => sub {
        my $oldid = $row->field('my_id');
        my $newid = $oldid + 1000;

        ref_is($orm->state_cache_lookup($s->source, [$oldid]), $row, "row is cached under its current (aliased) primary key");

        $s->where({my_id => $oldid})->update({my_id => $newid});

        ok(!$orm->state_cache_lookup($s->source, [$oldid]), "old primary key is no longer cached after a rowless pk change");
        ref_is($orm->state_cache_lookup($s->source, [$newid]), $row, "the same row moved to the new primary key in the cache");
        is($row->field('my_id'), $newid, "row identity reflects the new primary key");
    };
};

done_testing;

