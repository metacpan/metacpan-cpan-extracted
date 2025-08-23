use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift or die "Failed to get a db";

    my $is_bin = curdialect() =~ m/(percona|community)/i || curname() =~ m/system_mysql/;

    db my_db => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'my_db';

        schema my_schema => sub {
            table example => sub {
                column id => sub {
                    affinity 'numeric';
                    primary_key;
                    identity;
                };

                column name => sub {
                    affinity 'string';
                };

                column uuid => sub {
                    type 'UUID';
                    affinity 'binary' if $is_bin;
                };

                column data => sub {
                    type 'JSON';
                };
            };
        };
    };

    my $orm = orm('my_orm');
    my $con = $orm->connect;

    my $s = $con->handle('example');

    my $a_uuid = DBIx::QuickORM::Type::UUID->new;
    my $uuid_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($a_uuid, affinity => 'binary');

    my $x_row = $s->insert({name => 'x', uuid => DBIx::QuickORM::Type::UUID->new, data => {name => 'x'}});

    my $a_row = $s->insert({name => 'a', uuid => $a_uuid, data => {name => 'a'}});
    is(
        $a_row->stored_data,
        {
            id   => 2,
            name => 'a',
            uuid => $a_uuid,
            data => {name => 'a'},
        },
        "Got stored data with correct (orm) field names, and in uninflated forms"
    );

    $a_row = undef;
    $a_row = $s->one(name => 'a');
    is(
        $a_row->stored_data,
        {
            id   => 2,
            name => 'a',
            uuid => $is_bin ? $uuid_bin : $a_uuid,
            data => match qr/{"name":\s*"a"}/,
        },
        "Got stored data with correct (orm) field names, and in uninflated forms"
    );
    like(
        dies { $a_row->field('my_uuid') },
        qr/This row does not have a 'my_uuid' field/,
        "Cannot get field 'my_uuid', we have a 'uuid' field"
    );
    is($a_row->field('uuid'),      $a_uuid,       "Inflated UUID as string");
    is(ref($a_row->field('data')), 'HASH',        "Inflated JSON");
    is($a_row->field('data'),      {name => 'a'}, "deserialized json");

    $a_row->update({data => {name => 'a2'}});
    $a_row = undef; $a_row = $s->one(name => 'a');
    is($a_row->stored_data->{data}, match qr/{"name":\s*"a2"}/, "Updated in storage");
    is($a_row->field('data'),       {name => 'a2'},             "Updated json");

    $a_row->field(data => {name => 'a3'});
    is($a_row->pending_data->{data}, {name => "a3"}, "Updated in pending");
    is($a_row->stored_data->{data},  {name => 'a2'}, "Old data is still listed in stored");
    $a_row->save;
    $a_row = undef; $a_row = $s->one(name => 'a');
    is($a_row->stored_data->{data}, match qr/{"name":\s*"a3"}/, "Updated in storage");

    ref_is($s->one({uuid => $a_uuid}),   $a_row, "Found a by UUID string");
    ref_is($s->one({uuid => $uuid_bin}), $a_row, "Found a by UUID binary");

    isnt($a_uuid, $uuid_bin, "Binary and string forms are not the same");

    $a_row->field(name => 'aa');
    $con->dbh->do("UPDATE example SET name = 'ax' WHERE id = 2");
    $a_row->refresh;
    like(
        $a_row->row_data,
        {
            stored  => {name => 'ax'},
            pending => {name => 'aa'},
            desync  => {name => 1},
        },
        "Row is desynced, pending changes were made before a refresh showed changes",
    );

    {
        my $a_row2;
        {
            local $s->connection->{dbh} = 'oops'; # Make sure no sql can be executed
            like(dies { $s->one({id => 2}) }, qr/Can't locate object method "prepare" via package "oops"/, "Sanity check, db requests do not work");

            ok(lives { $a_row2 = $s->by_id(2) }, "Did not make a query, fetched from cache (single value id)");
            ref_is($a_row2, $a_row, "Got the row");

            ok(lives { $a_row2 = $s->by_id([2]) }, "Did not make a query, fetched from cache (array id)");
            ref_is($a_row2, $a_row, "Got the row");

            ok(lives { $a_row2 = $s->by_id({id => 2}) }, "Did not make a query, fetched from cache (hash id)");
            ref_is($a_row2, $a_row, "Got the row");
        }

        {
            local $s->connection->manager->{cache}->{$s->source->source_orm_name}->{2}; # Remove from cache
            ok($a_row2 = $s->by_id(2), "Fetched row");
            ref_is_not($a_row2, $a_row, "Not the previously cached copy, newly fetched (single id)");

            delete $s->connection->manager->{cache}->{$s->source->source_orm_name}->{2}; # Remove from cache
            ok($a_row2 = $s->by_id([2]), "Fetched row");
            ref_is_not($a_row2, $a_row, "Not the previously cached copy, newly fetched (array id)");

            delete $s->connection->manager->{cache}->{$s->source->source_orm_name}->{2}; # Remove from cache
            ok($a_row2 = $s->by_id({id => 2}), "Fetched row");
            ref_is_not($a_row2, $a_row, "Not the previously cached copy, newly fetched (hash id)");
        }
    }

    my $b_uuid = DBIx::QuickORM::Type::UUID->new;
    $uuid_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($b_uuid, affinity => 'binary');
    my $b_row  = $s->insert({name => 'b', uuid => DBIx::QuickORM::Type::UUID->qorm_deflate($b_uuid, affinity => 'binary'), data => {name => 'b'}});
    $b_row = undef; $b_row = $s->one(name => 'b');
    is(
        $b_row->stored_data,
        {
            id      => 3,
            name    => 'b',
            uuid => $is_bin ? $uuid_bin : $b_uuid,
            data => match qr/{"name":\s*"b"}/,
        },
        "Got stored data with correct (orm) field names, and in uninflated forms"
    );
    is($b_row->field('uuid'), $b_uuid, "uuid conversion from binary occured");

    like(
        dies { $s->insert({name => 'x', uuid => "NOT A UUID", data => {name => 'bx'}}) },
        qr/'NOT A UUID' does not look like a uuid/,
        "Invalid UUID"
    );

    my $y = $a_row->clone(name => 'y', uuid => DBIx::QuickORM::Type::UUID->new);
    is($y->field('name'), 'y', "Overrode name");
    isnt($y->field('uuid'), $a_row->field('uuid'), "Clones uuid is different");
    is($y->field('data'), $a_row->field('data'), "Clones data matches");
    ref_is_not($y->field('data'), $a_row->field('data'), "Deep clone of data, not the same reference");
    ok(!$y->is_stored, "Not stored yet");

    $y->insert;

    ok($y->in_storage, "Stored the row");
    ok($y->field('id'), "Got new primary key " . $y->field('id'));
};

done_testing;
