# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my %JSON = (PostgreSQL => 'JSONB', SQLite => 'JSON', DuckDB => 'JSON', MariaDB => 'JSON', MySQL => 'JSON');

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh  = $db->connect;
    my $json = $family eq 'PostgreSQL' && $dbh->{pg_server_version} < 90400 ? 'JSON' : $JSON{$family};
    $dbh->do("CREATE TABLE people (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), prefs $json)");
    $dbh->do("CREATE TABLE tagged (u CHAR(36) NOT NULL, n INTEGER NOT NULL, val VARCHAR(20), PRIMARY KEY (u, n))");

    my $orm = DBIx::QuickORM->new(
        dbh   => $dbh,
        types => {
            people => {prefs => 'JSON'},
            tagged => {u     => 'UUID'},
        },
    );

    my $savepoints = $orm->connection->dialect->supports_savepoints;
    my $name_of    = sub { scalar $dbh->selectrow_array("SELECT name FROM people WHERE id = ?", undef, $_[0]) };

    subtest vivify => sub {
        my $row = $orm->vivify(people => {id => 1, name => 'viv', prefs => {theme => 'dark'}});
        isa_ok($row, ['DBIx::QuickORM::Row'], "vivify builds a row of the table's row class");
        ok(!$row->is_in_db,    "that is not in the database");
        ok(!$row->was_deleted, "and was not deleted");
        ok(!$row->is_canon,    "and is not current");
        is($row->field('prefs'), {theme => 'dark'}, "Its fields read as stored ones do");
        is($name_of->(1),        undef,             "Nothing was written");

        like(dies { $orm->vivify(people => {nope => 1}) }, qr/has no field 'nope'/, "An unknown field croaks");

        like(dies { $row->update({name => 'x'}) },     qr/^Cannot update a row that is not in the database; insert it first/,     "update croaks");
        like(dies { $row->cas_update({name => 'x'}) }, qr/^Cannot cas_update a row that is not in the database; insert it first/, "cas_update croaks");
        like(dies { $row->delete },                    qr/^Cannot delete a row that is not in the database; insert it first/,     "delete croaks");
        like(dies { $row->refresh },                   qr/^Cannot refresh a row that is not in the database; insert it first/,    "refresh croaks");

        my $data = $row->row_data;
        ref_is($row->modify({name => 'changed'}), $row, "modify returns the row");
        ref_is_not($row->row_data, $data, "with new row data, a copy");
        is($data->{name},       'viv',     "leaving the old hash alone");
        is($row->field('name'), 'changed', "The row reads the change");
        ok(!$row->is_in_db, "and is still not in the database");
        like(dies { $row->modify({nope => 1}) }, qr/has no field 'nope'/, "modify croaks for an unknown field");

        ref_is($row->insert, $row, "insert returns the row");
        ok($row->is_in_db, "which is now in the database");
        ok($row->is_canon, "and current");
        is($name_of->(1),        'changed',         "with the row data written");
        is($row->field('prefs'), {theme => 'dark'}, "and reads it back");
        like(dies { $row->insert },                qr/^Cannot insert a row that is already in the database/,     "Inserting it again croaks");
        like(dies { $row->modify({name => 'x'}) }, qr/^Cannot modify a row that is in the database; use update/, "modify croaks on a stored row");
    };

    subtest delete_marks => sub {
        my $one = $orm->insert(people => {id => 2, name => 'two'});
        my $two = $orm->find(people => 2);
        ref_is($two->row_data, $one->row_data, "Two row objects hold the same current hash");

        is($one->delete, 1, "Deleting one");
        ok($one->was_deleted && $two->was_deleted, "marks every holder of the hash deleted");
        ok(!$one->is_in_db   && !$two->is_in_db,   "so neither is in the database");
        ok(!$one->is_canon, "nor current");
        like(dies { $two->refresh }, qr/^Cannot refresh a row that is not in the database; insert it first/, "Refreshing a deleted row croaks");

        $two->modify({name => 'back'});
        ok($two->was_deleted, "modify keeps the deleted mark on the copy");
        $two->insert;
        ok($two->is_in_db && !$two->was_deleted, "A deleted row inserted again is in the database");
        is($name_of->(2), 'back', "with its changes");
        ok($one->was_deleted, "The other holder still holds the deleted hash");
    };

    subtest refresh_finds_nothing => sub {
        my $row = $orm->insert(people => {id => 3, name => 'three'});
        $dbh->do("DELETE FROM people WHERE id = 3");
        like(dies { $row->refresh }, qr/no longer in the table 'people'/, "A refresh that finds nothing croaks");
        ok($row->was_deleted, "and marks the row deleted");

        my $other = $orm->insert(people => {id => 4, name => 'four'});
        $dbh->do("DELETE FROM people WHERE id = 4");
        is($orm->find(people => 4, cache => 0), undef, "A find that misses");
        ok($other->was_deleted, "marks the hash it held deleted too");
    };

    subtest rollback => sub {
        $orm->insert(people => {id => 5, name => 'five'});

        my $row;
        $orm->txn(sub {
            $row = $orm->find(people => 5);
            $row->delete;
            ok($row->was_deleted, "Deleted inside a transaction");
            $_[0]->rollback;
        });
        ok(!$row->was_deleted && $row->is_in_db, "A root rollback clears the deleted mark");

        return pass("No savepoints on $set->{name}") unless $savepoints;

        $orm->txn(sub {
            $row = $orm->find(people => 5);
            $orm->txn(sub {
                $row->delete;
                $_[0]->rollback;
            });
            ok(!$row->was_deleted, "A savepoint rollback clears it");
            ok($row->is_canon,     "and the row is current again");

            $orm->txn(sub { $row->delete });
            ok($row->was_deleted, "A savepoint commit keeps it");
            $_[0]->rollback;
        });
        ok(!$row->was_deleted, "until the root rolls back");

        $row->refresh;
        $orm->txn(sub {
            $row = $orm->find(people => 5);
            $row->delete;
            $row->modify({name => 'copy'});
            ok($row->was_deleted, "A deleted row's modified copy is deleted");
            $_[0]->rollback;
        });
        ok(!$row->was_deleted && $row->is_in_db, "and a rollback of the delete clears the copy's mark too");
        ok(!$row->is_canon,                      "though the copy is not current");

        $row->refresh;
        $orm->txn(sub { $orm->find(people => 5)->delete });
        ok($row->was_deleted, "A root commit keeps it, for every holder of the hash");

        $orm->txn(sub {
            $row->modify({name => 'later'});
            $_[0]->rollback;
        });
        ok($row->was_deleted, "A copy of a row deleted before a transaction stays deleted when it rolls back");
    };

    subtest insert_rollback => sub {
        my $row;
        $orm->txn(sub {
            $row = $orm->insert(people => {id => 20, name => 'twenty'});
            ok($row->is_in_db, "Inserted inside a transaction");
            $_[0]->rollback;
        });
        ok(!$row->is_in_db && !$row->was_deleted, "A root rollback takes it out of the database");
        $row->insert;
        ok($row->is_in_db && $row->is_canon, "so it can be inserted again");

        my ($viv, $data, @many, $found);
        $orm->txn(sub {
            $viv   = $orm->vivify(people => {id => 21, name => 'v'})->insert;
            $data  = $orm->insert(people => {id => 22, name => 'd'}, data => 1);
            @many  = @{$orm->insert_many(people => [{id => 23, name => 'm'}, {id => 24, name => 'n'}])};
            $found = $orm->find_or_insert(people => {id => 25, name => 'f'});
            $_[0]->rollback;
        });
        my $state = sub { DBIx::QuickORM::LookupTable->row_state($_[0]) // 'in db' };
        is([map { $_->is_in_db } $viv, @many, $found], [0, 0, 0, 0], "A row insert, insert_many, and find_or_insert are undone too");
        is($state->($data),                            'vivified',   "and so is a plain insert's row data");

        $orm->txn(sub { $row = $orm->insert(people => {id => 26, name => 'kept'}) });
        ok($row->is_in_db, "A root commit keeps the insert");

        $orm->txn(sub {
            $row = $orm->insert(people => {id => 27, name => 'gone'});
            $row->delete;
            $_[0]->rollback;
        });
        ok(!$row->is_in_db && !$row->was_deleted, "A row inserted then deleted is not in the database after a rollback");

        my ($upd, $cas, $ref);
        $orm->txn(sub {
            $upd = $orm->insert(people => {id => 30, name => 'a'})->update({name => 'b'});
            $cas = $orm->insert(people => {id => 31, name => 'a'})->cas_update({name => 'b'}, cas => ['id']);    # MySQL's insert gives only the key
            $ref = $orm->insert(people => {id => 32, name => 'a'})->refresh;
            $_[0]->rollback;
        });
        is([map { $_->is_in_db } $upd, $cas, $ref], [0, 0, 0], "A row inserted then updated, cas_updated, or refreshed is not in the database after a rollback");

        $orm->txn(sub { $upd = $orm->insert(people => {id => 33, name => 'a'})->update({name => 'b'})->refresh });
        ok($upd->is_in_db, "A root commit keeps it");

        return pass("No savepoints on $set->{name}") unless $savepoints;

        my $outer;
        $orm->txn(sub {
            $outer = $orm->insert(people => {id => 28, name => 'outer'});
            $orm->txn(sub {
                $row = $orm->insert(people => {id => 29, name => 'inner'});
                $_[0]->rollback;
            });
            ok(!$row->is_in_db,  "A savepoint rollback undoes its insert");
            ok($outer->is_in_db, "but not its parent's");

            $orm->txn(sub { $row = $orm->insert(people => {id => 29, name => 'inner'}) });
            ok($row->is_in_db, "A savepoint commit keeps it");
            $_[0]->rollback;
        });
        ok(!$row->is_in_db && !$outer->is_in_db, "until the root rolls back");

        $orm->txn(sub {
            $outer = $orm->insert(people => {id => 34, name => 'a'});
            $orm->txn(sub {
                $row = $orm->insert(people => {id => 35, name => 'a'})->update({name => 'b'});
                $outer->update({name => 'b'})->refresh;
                $_[0]->rollback;
            });
            ok(!$row->is_in_db,  "A savepoint rollback undoes an insert updated inside it");
            ok($outer->is_in_db, "but not its parent's insert updated inside it");
            $orm->txn(sub { $outer->refresh->update({name => 'c'}) });
            $_[0]->rollback;
        });
        ok(!$outer->is_in_db, "which the root rollback undoes, after a savepoint commit");
    };

    subtest copy_after_rollback => sub {
        my $copy = sub {
            my ($id) = @_;
            $orm->insert(people => {id => $id, name => "n$id"});
            my $row;
            $orm->txn(sub {
                $row = $orm->find(people => $id);
                $row->delete;
                $row->modify({name => 'copy'});
                $_[0]->rollback;
            });
            ok($row->is_in_db, "A modified copy whose delete rolled back is in the database");
            return $row;
        };

        my $row = $copy->(6);
        $dbh->do("DELETE FROM people WHERE id = 6");
        like(dies { $row->refresh }, qr/no longer in the table 'people'/, "A refresh of it that finds nothing croaks");
        ok($row->was_deleted, "and marks the copy deleted");

        $row = $copy->(7);
        is($orm->delete_row(people => $row->row_data, enforce_canon => 0), 1, "delete_row of the copy's data");
        ok($row->was_deleted, "marks the copy deleted");
    };

    subtest txn_marks_outside => sub {
        my $held = $orm->insert(people => {id => 8, name => 'eight'});
        $orm->txn(sub {
            $orm->delete_row(people => {id => 8}, enforce_canon => 0);
            ok($held->was_deleted, "delete_row by key in a transaction marks a row held from before it");
            $_[0]->rollback;
        });
        ok(!$held->was_deleted && $held->is_in_db, "and a rollback unmarks it");

        $held->refresh;
        $orm->txn(sub { $orm->delete_row(people => {id => 8}, enforce_canon => 0) });
        ok($held->was_deleted, "A commit keeps the mark");

        my $gone = $orm->insert(people => {id => 9, name => 'nine'});
        $dbh->do("DELETE FROM people WHERE id = 9");
        $orm->txn(sub {
            is($orm->find(people => 9), undef, "A find in a transaction misses a row deleted elsewhere");
            ok($gone->was_deleted, "and marks a row held from before it");
        });

        my $stale = $orm->insert(people => {id => 10, name => 'ten'});
        $dbh->do("DELETE FROM people WHERE id = 10");
        $orm->txn(sub {
            like(dies { $stale->refresh }, qr/no longer in the table 'people'/, "A refresh in a transaction that finds nothing croaks");
        });
        ok($stale->was_deleted, "and marks the row deleted");
    };

    subtest typed_compound_key => sub {
        my $uuid = '0190f0a4-7d6c-7e5b-9c1a-3f2e4d5c6b7a';

        my $row = $orm->insert(tagged => {u => $uuid, n => 1, val => 'a'});
        ok($row->is_canon, "A row with a typed compound key is current");
        ref_is($orm->find(tagged => [uc($uuid), 1])->row_data, $row->row_data, "found in another form of the key");
        ok($row->is_canon, "and still current");

        my $viv = $orm->vivify(tagged => {u => $uuid, n => 2, val => 'b'});
        ok(!$viv->is_canon, "A vivified row with such a key is not current");
        $viv->insert;
        ok($viv->is_canon, "until inserted");
        ref_is($orm->find(tagged => [$uuid, 2])->row_data, $viv->row_data, "and then found");

        $row->delete;
        ok($row->was_deleted, "Deleting marks it");
        is($orm->find(tagged => [$uuid, 1]), undef, "and the row is gone");
    };
};

done_testing;
