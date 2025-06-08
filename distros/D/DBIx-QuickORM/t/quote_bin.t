use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;
use Hash::Merge qw/merge/;
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill sub {
            autotype 'UUID';
        };
    };

    my $uuid = DBIx::QuickORM::Type::UUID->new;
    my $uuid_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($uuid, 'binary');

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    my $s = $orm->handle('example');
    ok(my $row = $s->insert({name => 'a', uuid => $uuid}), "Inserted a row");
    $row = undef; $row = $s->one(name => 'a');
    is($row->row_data->{stored}->{uuid}, $uuid_bin, "Stored as binary");
    isnt($row->row_data->{stored}->{uuid}, $uuid, "Sanity check that original uuid and binary do not match");
    is($row->field('uuid'), $uuid, "Round trip returned the original UUID, no loss");

    ref_is($s->one({uuid => $uuid}),   $row, "Found a by UUID string");
    ref_is($s->one({uuid => $uuid_bin}), $row, "Found a by UUID binary");

    my $uuid2 = DBIx::QuickORM::Type::UUID->new;
    my $uuid2_bin = DBIx::QuickORM::Type::UUID::qorm_deflate($uuid, 'binary');

    $row->update({uuid => $uuid2});
    $row->refresh;
    is($row->field('uuid'), $uuid2, "updated uuid from $uuid");
};

done_testing;

