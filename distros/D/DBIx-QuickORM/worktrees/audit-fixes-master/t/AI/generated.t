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
        autofill;
    };

    my $orm    = orm('my_orm')->connect;
    my $schema = $orm->schema;
    my $col    = $schema->{tables}->{widgets}->{columns}->{derived};

    # PostgreSQL gained GENERATED ALWAYS AS ... STORED in 12.0; the per-version
    # SQL files for PG 10 / 11 load a schema without it. Detect that and skip.
    unless ($col) {
        ok(1, "generated columns not supported by " . curname() . " - skipping");
        return;
    }

    ok($col, "introspected the generated column");
    ok($col->generated, "generated column flagged as generated");

    ok(my $row = $orm->handle('widgets')->insert({name => 'Foo'}), "insert succeeds without providing derived");
    is($row->field('derived'), 'foo', "derived column populated by the database and visible on the row");

    my $row2 = $orm->handle('widgets')->insert({name => 'Bar', derived => 'override'});
    is($row2->field('derived'), 'bar', "generated value passed in via insert() is silently dropped");

    like(
        dies { $orm->handle('widgets')->insert({derived => 'only'}) },
        qr/Refusing to insert an empty row/,
        "insert with only a generated field collapses to empty and croaks"
    );

    like(
        dies { $row->field(derived => 'x') },
        qr/Cannot set field 'derived'.*generated/,
        "setting a generated field via row->field croaks"
    );

    like(
        dies { $row->update({derived => 'x'}) },
        qr/Cannot set field 'derived'.*generated/,
        "row->update with only a generated field croaks"
    );

    # Handle::update silently drops generated keys; with only generated keys
    # the resulting empty change set should croak with the empty-changes msg.
    like(
        dies { $orm->handle('widgets', where => {id => $row->field('id')})->update({derived => 'x'}) },
        qr/Changes may not be empty/,
        "handle->update with only a generated field collapses to empty and croaks"
    );

    # When mixed with a writable field, the generated key is dropped and the
    # writable change applies.
    ok(
        lives { $orm->handle('widgets', where => {id => $row->field('id')})->update({name => 'Baz', derived => 'override'}) },
        "handle->update silently drops a generated key while applying writable ones"
    );

    $row->refresh;
    is($row->field('name'),    'Baz', "non-generated update landed");
    is($row->field('derived'), 'baz', "generated column re-derived from the new value");

    # upsert path
    my $upsert = $orm->handle('widgets')->upsert_and_refresh({id => $row->field('id'), name => 'Qux', derived => 'ignored'});
    is($upsert->field('name'),    'Qux', "upsert applied writable change");
    is($upsert->field('derived'), 'qux', "upsert re-derived generated column and ignored passed-in value");
};

done_testing;
