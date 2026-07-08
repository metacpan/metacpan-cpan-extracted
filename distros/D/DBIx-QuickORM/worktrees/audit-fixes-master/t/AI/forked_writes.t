use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# Reuse the forked-query schema (an 'example' table with id + name).
sub SCHEMA_DIR { 't/forked' }

# A forked write runs in a child process whose row cache is discarded, so the
# parent must maintain its own cache when the child finishes. These tests do a
# forked update and a forked delete on a bound row and check that the parent's
# row object, the parent's identity cache, and the database all agree once the
# forked handle is finalized.

do_for_all_dbs {
    my $db = shift;

    # DuckDB is an embedded single-writer engine; a forked child cannot open the
    # database the parent already holds (forked.t skips it for the same reason).
    if (curdialect() =~ m/duckdb/i) {
        skip_all "Skipping for duckdb (embedded single-writer; cross-process forked queries are unsupported)...";
        return;
    }

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';

        if (curdialect() =~ m/MySQL/) {
            socket $db->socket;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/PostgreSQL/) {
            socket $db->dir;
            user $db->username;
            pass $db->password;
        }
        elsif (curdialect() =~ m/SQLite/) {
            db_name $db->dir . '/quickdb';
        }
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    my $orm = orm('my_orm')->connect;

    subtest forked_update => sub {
        my $row = $orm->handle('example')->insert({name => 'start'});
        my $id  = $row->field('id');

        # Forked update on the bound row. The returned handle is finalized at the
        # end of this block (its destructor waits for the child, then runs the
        # parent-side cache maintenance).
        {
            my $sth = $orm->handle($row)->forked->update({name => 'updated'});
            ok($sth->DOES('DBIx::QuickORM::Role::Async'), "forked update returns an async handle");
        }

        is($row->field('name'), 'updated', "parent row object reflects the forked update");
        ok(!$row->is_desynced, "row is not left desynced");

        my $again = $orm->handle('example', where => {id => $id})->one;
        ref_is($again, $row, "still the single cached row object");
        is($again->field('name'), 'updated', "cached row reflects the forked update");

        my $fresh = $orm->handle('example', where => {id => $id})->data_only->one;
        is($fresh->{name}, 'updated', "database reflects the forked update");
    };

    subtest forked_delete => sub {
        my $row = $orm->handle('example')->insert({name => 'doomed'});
        my $id  = $row->field('id');

        {
            my $sth = $orm->handle($row)->forked->delete;
            ok($sth->DOES('DBIx::QuickORM::Role::Async'), "forked delete returns an async handle");
        }

        my $gone = $orm->handle('example', where => {id => $id})->one;
        is($gone, undef, "row is gone from the database after a forked delete");
    };

    subtest forked_bulk_write_requires_a_row => sub {
        $orm->handle('example')->insert({name => 'bulk1'});
        $orm->handle('example')->insert({name => 'bulk2'});

        like(
            dies { $orm->handle('example', where => {name => 'bulk1'})->forked->update({name => 'x'}) },
            qr/Cannot maintain the row cache for a bulk update without a specific row/,
            "a forked bulk update without a bound row croaks",
        );
    };
};

done_testing;
