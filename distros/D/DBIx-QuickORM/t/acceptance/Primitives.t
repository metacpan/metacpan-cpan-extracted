# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs on_execute/;
use DBIx::QuickORM::AggregateRow;
use DBIx::QuickORM::Source::Query;
use DBIx::QuickORM::Source::Table;
use DBIx::QuickORM::Value qw/sql/;

my %AUTO_PK = (
    PostgreSQL => 'SERIAL PRIMARY KEY',
    MySQL      => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    MariaDB    => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    SQLite     => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    DuckDB     => "INTEGER PRIMARY KEY DEFAULT nextval('widgets_seq')",
);

my %BLOB = (PostgreSQL => 'BYTEA', MySQL => 'VARBINARY(20)', MariaDB => 'VARBINARY(20)', SQLite => 'BLOB', DuckDB => 'BLOB');

sub build_schema {
    my ($dbh, $family) = @_;
    $dbh->do("CREATE SEQUENCE widgets_seq") if $family eq 'DuckDB';
    $dbh->do("CREATE TABLE widgets (id $AUTO_PK{$family}, name VARCHAR(50) NOT NULL UNIQUE, note VARCHAR(50), qty INTEGER DEFAULT 7)");
    $dbh->do("CREATE TABLE pairs (a INTEGER NOT NULL, b VARCHAR(10) NOT NULL, val VARCHAR(20), PRIMARY KEY (a, b))");
    $dbh->do("CREATE TABLE plain (id INTEGER NOT NULL PRIMARY KEY, val VARCHAR(20))");
    $dbh->do("CREATE TABLE nopk (msg VARCHAR(20))");
    $dbh->do("CREATE TABLE bin (id INTEGER NOT NULL PRIMARY KEY, data $BLOB{$family})");
}

{

    package My::ReadOnlyRow;
    sub row_data { $_[0]->{data} }
}

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh = $db->connect;
    build_schema($dbh, $family);

    my $orm     = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $conn    = $orm->connection;
    my $dialect = $conn->dialect;
    my $ret_ins = $dialect->supports_returning_insert;
    my $ret_upd = $dialect->supports_returning_update;
    my %all     = (id => T(), name => T(), note => E(), qty => T());

    subtest insert => sub {
        my $w = $orm->insert(widgets => {name => 'a'});
        if ($ret_ins) {
            is($w, {id => T(), name => 'a', note => undef, qty => 7}, "RETURNING gives the whole row, defaults included");
        }
        else {
            is($w, {id => T()}, "Without RETURNING the row data holds only the primary key, from last_insert_id");
        }
        ok($orm->is_canon(widgets => $w), "The inserted row is canon");

        my $given = $orm->insert(widgets => {id => 100, name => 'given'});
        is($given->{id},        100,                                        "A given primary key is used");
        is([sort keys %$given], $ret_ins ? [qw/id name note qty/] : ['id'], "with the whole row only through RETURNING");

        my $pair = $orm->insert(pairs => {a => 1, b => 'x', val => 'v'});
        is($pair, $ret_ins ? {a => 1, b => 'x', val => 'v'} : {a => 1, b => 'x'}, "A compound primary key");
        ok($orm->is_canon(pairs => $pair), "is canon");

        if ($ret_ins) {
            is($orm->insert(nopk => {msg => 'hi'}), {msg => 'hi'}, "A table without a primary key returns what RETURNING gives");
        }
        else {
            like(dies { my $r = $orm->insert(nopk => {msg => 'hi'}) }, qr/^insert\(\) into 'nopk' has nothing to return/, "A table without a primary key croaks without RETURNING");
            is($dbh->selectrow_array('SELECT COUNT(*) FROM nopk'), 0, "before anything is sent");
            $orm->insert(nopk => {msg => 'hi'});
        }

        my $err = dies { $orm->insert(widgets => {name => 'a'}) };
        is($err->kind, 'unique_violation', "Database errors are classified");

        like(dies { $orm->insert(widgets => {nope => 1}) },           qr/^The table 'widgets' has no field 'nope'/,            "An unknown field croaks");
        like(dies { $orm->insert(widgets => {name => 'z'}, x => 1) }, qr/^Unknown argument\(s\) to insert\(\): x/,             "An unknown argument croaks");
        like(dies { $orm->insert(widgets => {}) },                    qr/^insert\(\) into 'widgets' needs at least one field/, "No fields croaks");
        like(dies { my $r = $orm->insert(nopk => {}) },               qr/^insert\(\) into 'nopk' needs at least one field/,    "on every table, in any context");
        like(dies { $orm->insert(nope => {a => 1}) },                 qr/^The table 'nope' is not in the database map/,        "An unknown table croaks");

        if (!$ret_ins) {
            like(dies { my $r = $orm->insert(pairs => {a => 2, val => 'v'}) }, qr/^insert\(\) into 'pairs' needs every primary key field/, "A compound key the database cannot return croaks");
            is($dbh->selectrow_array('SELECT COUNT(*) FROM pairs WHERE a = 2'), 0, "before anything is sent");
        }
    };

    subtest void_insert => sub {
        my $sent;
        my $watch = on_execute { $sent = $_[0] };
        $orm->insert(plain => {id => 50, val => 'v'});
        unlike($sent, qr/RETURNING/i, "In void context insert asks for nothing back");
        is($orm->refresh_row('plain', {id => 50}, db => 0),              undef, "and holds nothing as current");
        is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 50'), 'v',   "but inserts the row");

        $orm->insert(nopk => {msg => 'void'});
        is($dbh->selectrow_array("SELECT COUNT(*) FROM nopk WHERE msg = 'void'"), 1, "A table without a primary key never croaks in void context");
        $orm->insert(pairs => {a => 3, b => 'z'});
        is($dbh->selectrow_array('SELECT COUNT(*) FROM pairs WHERE a = 3'), 1, "nor does a compound key");

        my $h = $orm->handle('plain');
        $h->insert({id => 51, val => 'h'});
        unlike($sent, qr/RETURNING/i, "A table handle's insert in void context asks for nothing back");
        is($orm->refresh_row('plain', {id => 51}, db => 0), undef, "and holds nothing");
        my $row = $h->insert({id => 52, val => 'h'});
        is($row->{id}, 52, "In scalar context it returns the row");
    };

    subtest update_row => sub {
        my $w   = $orm->insert(widgets => {name => 'upd'});
        my $new = $orm->update_row('widgets', $w, {note => 'n1'});
        is($new, $ret_upd ? {%all, id => $w->{id}, name => 'upd', note => 'n1', qty => 7} : {id => $w->{id}}, "The new row data: whole through RETURNING, else the primary key");
        ok($orm->is_canon(widgets  => $new), "The new row data is canon");
        ok(!$orm->is_canon(widgets => $w),   "The old is not");

        like(
            dies { $orm->update_row('widgets', $w, {note => 'n2'}) },
            qr/^The row data for 'widgets' is not canon/,
            "Stale row data croaks by default"
        );
        my $again = $orm->update_row('widgets', {id => $w->{id}}, {note => 'n2'}, enforce_canon => 0);
        ok($orm->is_canon(widgets => $again), "enforce_canon => 0 updates by primary key alone");

        my $same = $orm->update_row('widgets', $again, {note => 'n2'});
        ok($same && $same != $again, "A write replaces the canon hash even when nothing changed");

        is($orm->update_row('widgets', {id => 99999}, {note => 'x'}, enforce_canon => 0), undef, "No matching row returns undef");

        like(dies { $orm->update_row('widgets', $same, {}) },                  qr/^update_row\(\) needs a hashref of at least one change/,                     "Empty changes croak");
        like(dies { $orm->update_row('widgets', $same, {x => 1}) },            qr/^The table 'widgets' has no field 'x'/,                                      "Unknown changed fields croak");
        like(dies { $orm->update_row('widgets', $same, {note => 1}, y => 1) }, qr/^Unknown argument\(s\) to update_row\(\): y/,                                "Unknown arguments croak");
        like(dies { $orm->update_row('nopk', {msg => 'hi'}, {msg => 1}) },     qr/^The table 'nopk' has no primary key/,                                       "A table without a primary key croaks");
        like(dies { $orm->update_row('widgets', {name => 'x'}, {note => 1}) }, qr/^The primary key field 'id' of the table 'widgets' is missing or undefined/, "Row data without the primary key croaks");
    };

    subtest cas => sub {
        my $w = $orm->refresh_row('widgets', $orm->insert(widgets => {name => 'cas', note => 'n1'}), cache => 0);

        my $hit = $orm->update_row('widgets', $w, {note => 'n2'}, cas => ['note']);
        ok($hit, "A compare-and-swap that matches updates");
        $hit = $orm->refresh_row('widgets', $hit);
        is($hit->{note}, 'n2', "and the change is made");

        my $stale = {%$w};
        is($orm->update_row('widgets', $stale, {note => 'n3'}, cas => ['note'], enforce_canon => 0), undef, "A compare-and-swap that misses returns undef");
        ok($orm->is_canon(widgets => $hit), "and leaves the lookup table alone");
        is($dbh->selectrow_array('SELECT note FROM widgets WHERE id = ?', undef, $w->{id}), 'n2', "and the row alone");

        my $null = $orm->refresh_row('widgets', $orm->insert(widgets => {name => 'null'}), cache => 0);
        is($null->{note}, undef, "A NULL field");
        my $null_hit = $orm->update_row('widgets', $null, {note => 'set'}, cas => ['note']);
        ok($null_hit, "An undef compare-and-swap value matches NULL");
        is($orm->update_row('widgets', {id => $null->{id}, note => undef}, {note => 'x'}, cas => ['note'], enforce_canon => 0), undef, "and misses a value");

        $hit = $orm->refresh_row('widgets', $hit);
        ok($orm->update_row('widgets', $hit, {note => 'n4'}, auto_cas => 1), "auto_cas compares the changed fields the row data holds");
        is($orm->update_row('widgets', {%$hit}, {note => 'n5'}, auto_cas => 1, enforce_canon => 0), undef, "and misses on a stale value");

        like(dies { $orm->update_row('widgets', {id => $w->{id}}, {note => 1}, cas => ['note'], enforce_canon => 0) }, qr/^The 'cas' field 'note' is not in the row data/, "A cas field missing from the row data croaks");
    };

    subtest pk_change => sub {
        my $p   = $orm->insert(plain => {id => 1, val => 'v'});
        my $new = $orm->update_row('plain', $p, {id => 2});
        is($new->{id},                                     2,     "The new row data has the new key");
        is($orm->refresh_row('plain', {id => 1}, db => 0), undef, "The old key is gone from the lookup table");
        ref_is($orm->refresh_row('plain', {id => 2}, db => 0), $new, "and the new key holds the new row data");

        my $pair  = $orm->refresh_row('pairs', {a => 1, b => 'x'});
        my $moved = $orm->update_row('pairs', $pair, {b => 'y'});
        is([@{$moved}{qw/a b/}],                                    [1, 'y'], "A compound key changes too");
        is($orm->refresh_row('pairs', {a => 1, b => 'x'}, db => 0), undef,    "and is re-keyed");
    };

    subtest delete_row => sub {
        my $p = $orm->insert(plain => {id => 10, val => 'v'});
        like(dies { $orm->delete_row('plain', {id => 10}) }, qr/^The row data for 'plain' is not canon/, "Deleting with stale row data croaks");
        is($orm->delete_row('plain', $p),                             1,     "Deletes one row");
        is($orm->refresh_row('plain', {id => 10}, db => 0),           undef, "and removes it from the lookup table");
        is($orm->refresh_row('plain', {id => 10}),                    undef, "and from the database");
        is($orm->delete_row('plain', {id => 10}, enforce_canon => 0), 0,     "Deleting a missing row deletes nothing");
        like(dies { $orm->delete_row('plain', {id => 10}, cas => []) }, qr/^Unknown argument\(s\) to delete_row\(\): cas/, "Unknown arguments croak");
    };

    subtest refresh_row => sub {
        my $p = $orm->insert(plain => {id => 20, val => 'v'});
        ref_is($orm->refresh_row('plain', {id => 20}), $p, "The cache comes first");

        my $kept = $orm->refresh_row('plain', {id => 20}, cache => 0);
        ref_is($kept, $p, "A database read that finds nothing changed keeps the canon hash");
        is($kept, {id => 20, val => 'v'}, "and adds newly fetched fields to it in place");

        $dbh->do("UPDATE plain SET val = 'changed' WHERE id = 20");
        ref_is($orm->refresh_row('plain', {id => 20}), $p, "The cache does not see changes made behind the ORM");
        my $fresh = $orm->refresh_row('plain', {id => 20}, cache => 0);
        ok($fresh != $p, "A database read that finds a difference replaces the canon hash");
        is($fresh, {id => 20, val => 'changed'}, "with the new data");
        ok(!$orm->is_canon(plain => $p), "and the old hash is no longer canon");

        $orm->clear_cache;
        my $part = $orm->refresh_row('widgets', {id => 100}, fields => ['name']);
        is($part, {id => 100, name => 'given'}, "fields reads only those fields and the primary key");
        my $more = $orm->refresh_row('widgets', {id => 100}, fields => ['qty']);
        ref_is($more, $part, "Asking for a field the cache lacks reads it, and an unchanged row keeps its hash");
        is($more, {id => 100, name => 'given', qty => 7}, "with the field added");

        is($orm->refresh_row('widgets', {id => 99999}, db => 0), undef, "db => 0 with nothing cached returns undef");
        like(dies { $orm->refresh_row('plain', {id => 20}, cache => 0, db => 0) }, qr/^refresh_row\(\) needs 'cache' or 'db' to be true/, "Both false croaks");
        like(dies { $orm->refresh_row('plain', {id => 20}, fields => ['nope']) }, qr/^The table 'plain' has no field 'nope'/, "Unknown fields croak");
    };

    subtest select => sub {
        $orm->clear_cache;
        my $plain = DBIx::QuickORM::Source::Table->new(table => 'plain', db_map => $orm->db_map);
        my $raw   = $conn->select($plain, "SELECT id, val FROM plain WHERE id = ?", [[id => 20]]);
        is($raw, [{id => 20, val => 'changed'}], "select returns the rows");
        ok(!$orm->is_canon(plain => $raw->[0]), "as fetched, not ingested");
        my ($first) = @{($plain->results($orm, $raw, 1))[0]};
        ok($orm->is_canon(plain => $first), "The table source's results ingests them");
        my ($second) = @{($plain->results($orm, $conn->select($plain, "SELECT id FROM plain WHERE id = ?", [[id => 20]]), 1))[0]};
        ref_is($second, $first, "An unchanged row keeps its canon hash");

        my $query = DBIx::QuickORM::Source::Query->new(sql => 'SELECT id FROM plain WHERE id = ?', binds => [20]);
        my $rows  = $conn->select($query, $query->query_sql);
        is($rows, [{id => 20}], "A query source's SQL runs as written");

        like(dies { $conn->select(plain                     => 'SELECT 1') }, qr/^select\(\) needs a source/,              "The source must be a source object");
        like(dies { $conn->select($plain, 'SELECT 1', [], x => 1) },          qr/^Unknown argument\(s\) to select\(\): x/, "Unknown arguments croak");
    };

    subtest binary => sub {
        my $bytes = "\x00\xff\xe9 \x01";
        my $row   = $orm->insert(bin => {id => 1, data => $bytes});
        $orm->clear_cache;
        is($orm->refresh_row('bin', {id => 1})->{data}, $bytes, "Binary fields are bound as binary and round-trip");
        my $new = $orm->update_row('bin', {id => 1, data => $bytes}, {data => "\x00\x00"}, cas => ['data'], enforce_canon => 0);
        ok($new, "and compare as binary");
    };

    subtest deflation => sub {
        my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {plain => {val => '+DBIx::QuickORM::Test::Type::Box'}});
        my $row = $orm->insert(plain => {id => 40, val => ['a', 'b']});
        is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 40'), 'a,b', "Inserted values are deflated");
        ok($orm->update_row('plain', {id => 40, val => 'box:a,b'}, {val => ['c']}, cas => ['val'], enforce_canon => 0), "Compare-and-swap values and changes are deflated");
        is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 40'), 'c', "and the change is stored");
        like(dies { $orm->insert(plain => {id => 41, val => 'x', nope => 1}) }, qr/has no field 'nope'/, "Fields are checked first");
    };

    subtest row_objects => sub {
        my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => 'DBIx::QuickORM::Test::Row', row_classes => {pairs => undef});
        require DBIx::QuickORM::Test::Row;

        my $row = $orm->insert(plain => {id => 30, val => 'r'});
        isa_ok($row, ['DBIx::QuickORM::Test::Row'], "Rows come back as the ORM's row class");
        ref_is($row->orm, $orm, "built with the ORM");
        is($row->table, 'plain', "and the table");
        ok($orm->is_canon(plain => $row), "A row object is accepted as row data");

        my $old = $row->row_data;
        my $new = $orm->update_row('plain', $row, {val => 's'});
        ref_is($new, $row, "update_row returns the row object it was given");
        ok(!$orm->is_canon(plain => $old), "the old row data is no longer canon");
        ok($orm->is_canon(plain  => $row), "and the row holds the new canon data");

        my $pair = $orm->refresh_row('pairs', {a => 1, b => 'y'});
        is(ref($pair), 'HASH', "A table's row_class of undef means hashrefs");

        is($orm->delete_row('plain', $new), 1, "delete_row takes a row object");
    };

    subtest return_rule => sub {
        my $orm = DBIx::QuickORM->new(dbh => $dbh);

        my $row = $orm->insert(plain => {id => 60, val => 'a'});
        isa_ok($row, ['DBIx::QuickORM::Row'], "insert returns a row");
        my $data = $orm->insert(plain => {id => 61, val => 'b'}, data => 1);
        is(ref($data), 'HASH', "and the row data with data => 1");
        ok($orm->is_canon(plain => $data), "held as current");

        my $rows = $orm->insert_many(plain => [{id => 62}, {id => 63}]);
        is([map { ref } @$rows], [('DBIx::QuickORM::Row') x 2], "insert_many returns an arrayref of rows");
        my $many = $orm->insert_many(plain => [{id => 64}, {id => 65}], data => 1);
        is([map { ref } @$many], ['HASH', 'HASH'], "and of the row data with data => 1");

        my $old = $row->row_data;
        ref_is($orm->update_row(plain => $row, {val => 'a2'}), $row, "update_row returns the row object it was given");
        ref_is_not($row->row_data, $old, "holding the new row data");
        my $new = $orm->update_row(plain => $row->row_data, {val => 'a3'});
        isa_ok($new, ['DBIx::QuickORM::Row'], "Given row data it returns a new row");
        ref_is_not($new, $row, "not the earlier one");

        is(ref($orm->update_row(plain => $new, {val => 'a4'}, data => 1)), 'HASH', "data => 1 returns the row data");
        ok($orm->is_canon(plain => $new), "and a given row still takes it");
        $orm->update_row(plain => $new, {val => 'a5'});
        ok($orm->is_canon(plain => $new), "In void context a given row takes the new row data too");
        is($new->raw_field('val'), 'a5', "after the update");

        my $r = $orm->insert(plain => {id => 67, val => 'r'});
        ref_is($orm->refresh_row(plain => $r), $r, "refresh_row returns the row object it was given");
        isa_ok($orm->refresh_row(plain => {id => 67}), ['DBIx::QuickORM::Row'], "a new row for row data");
        is(ref($orm->refresh_row(plain => {id => 67}, data => 1)), 'HASH', "and the row data with data => 1");
        $dbh->do("UPDATE plain SET val = 'r2' WHERE id = 67");
        $orm->refresh_row(plain => $r, cache => 0);
        is($r->raw_field('val'), 'r2', "In void context a given row takes the new row data too");

        my $gone      = $orm->insert(plain => {id => 66, val => 'g'});
        my $gone_data = $gone->row_data;
        $dbh->do('DELETE FROM plain WHERE id = 66');
        is($orm->update_row(plain => $gone, {val => 'h'}), undef, "update_row returns undef when no row matched");
        ref_is($gone->row_data, $gone_data, "leaving the given row alone");
        is($orm->refresh_row(plain => $gone, cache => 0), undef, "and so does refresh_row");
        ref_is($gone->row_data, $gone_data, "leaving it alone too");

        my $h = $orm->handle('plain');
        ref_is($h->update_row($r, {val => 'r3'}), $r, "A handle's update_row returns the row it was given");
        ref_is($h->refresh_row($r),               $r, "and so does its refresh_row");
        is(ref($h->find(67, data => 1)), 'HASH', "find takes data => 1");

        my $bare = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
        is(ref($bare->update_row(plain => {id => 67}, {val => 'r4'}, enforce_canon => 0)), 'HASH', "With no row class it returns the row data");
    };

    subtest row_takes_new_data => sub {
        my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
        $orm->insert(plain => {id => 68, val => 'keep'});

        my $ro  = bless {data => {id => 68, val => 'keep'}}, 'My::ReadOnlyRow';
        my $agg = DBIx::QuickORM::AggregateRow->new(orm => $orm, columns => {}, row_data => {id => 68, val => 'keep'});

        for my $case ([read_only => $ro], [aggregate => $agg]) {
            my ($name, $row) = @$case;
            my $data = $row->row_data;
            my $want = qr/^A row object passed to update_row\(\) must take new data with set_row_data; pass its row_data instead/;

            like(dies { my $x = $orm->update_row(plain => $row, {val => 'gone'}, enforce_canon => 0) }, $want,                                       "$name: update_row croaks in scalar context");
            like(dies { $orm->update_row(plain => $row, {val => 'gone'}, enforce_canon => 0) },         $want,                                       "$name: and in void context");
            like(dies { $orm->refresh_row(plain => $row) },                                             qr/^A row object passed to refresh_row\(\)/, "$name: so does refresh_row");
            is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 68'), 'keep', "$name: before anything is written");
            ref_is($row->row_data, $data, "$name: the row is left alone");
        }

        ok($orm->update_row(plain => $ro->row_data, {val => 'new'}, enforce_canon => 0), "Its row_data can be passed instead");
        is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 68'), 'new', "and is written");
    };

    subtest as_given => sub {
        my $sent;
        my $watch = on_execute { $sent = $_[0] };
        my $orm   = DBIx::QuickORM->new(dbh => $dbh, types => {plain => {val => '+DBIx::QuickORM::Test::Type::Box'}});

        my %fields = (id => 70, val => ['a', 'b']);
        my $row    = $orm->insert(plain => \%fields, as_given => 1);
        isa_ok($row, ['DBIx::QuickORM::Row'], "as_given returns a row");
        ref_is_not($row->row_data, \%fields, "over a copy of the fields");
        is($row->row_data, {id => 70, val => 'a,b'},      "deflated to database form, with the given key");
        is(\%fields,       {id => 70, val => ['a', 'b']}, "leaving the caller's hash alone");
        ok(!$row->is_canon, "The copy is not canon");
        is($orm->refresh_row(plain => {id => 70}, db => 0), undef, "and nothing is held as current");

        my $w = $orm->insert(widgets => {name => 'ag', note => sql('?', 'n')}, as_given => 1, data => 1);
        like($sent, qr/RETURNING\s+\W?id\W?\s*$/i, "RETURNING names only the primary key") if $ret_ins;
        is($w, {id => T(), name => 'ag'}, "data => 1 returns the copy, with a generated key merged in");
        ok(!exists $w->{note}, "A field given as sql() is left out, not undef");
        is($dbh->selectrow_array('SELECT note FROM widgets WHERE id = ?', undef, $w->{id}), 'n', "but inserted");

        my $wr = $orm->insert(widgets => {name => 'ag2'}, as_given => 1);
        is($wr->field('qty'), 7, "A missing field is fetched by primary key");
        ok(!$wr->is_canon, "and the row stays not canon: the fetch skips the row cache");

        like(dies { $row->update({val => ['c']}) }, qr/^The row data for 'plain' is not canon/, "A copy follows enforce_canon on update");
        ok($row->update({val => ['c']}, enforce_canon => 0), "and updates with enforce_canon => 0");

        my $n = $orm->insert(nopk => {msg => 'ag'}, as_given => 1);
        is($n->row_data, {msg => 'ag'}, "A table without a primary key returns the copy");
        like(dies { $n->update({msg => 'x'}, enforce_canon => 0) },                   qr/^Cannot update a row without a primary key/,  "which cannot be updated, even with enforce_canon => 0");
        like(dies { $orm->update_row(nopk => $n, {msg => 'x'}, enforce_canon => 0) }, qr/^The table 'nopk' has no primary key/,        "nor through update_row");
        like(dies { $n->delete },                                                     qr/^Cannot delete a row without a primary key/,  "deleted");
        like(dies { $n->refresh },                                                    qr/^Cannot refresh a row without a primary key/, "or refreshed");

        my %raw  = (id => 73, val => 'r,s');
        my $copy = $orm->insert(plain => \%raw, as_given => 1, raw => 1, data => 1);
        ref_is_not($copy, \%raw, "With raw => 1 the caller's hash is still not the row data");
        is($copy, {id => 73, val => 'r,s'}, "but a copy of it, as sent");

        $orm->insert(plain => {id => 71, val => ['v']}, as_given => 1);
        unlike($sent, qr/RETURNING/i, "In void context as_given changes nothing");
        is($dbh->selectrow_array('SELECT val FROM plain WHERE id = 71'), 'v', "the row is inserted");

        like(dies { $orm->insert_many(plain => [{id => 72}], as_given => 1) }, qr/^Unknown argument\(s\) to insert_many\(\): as_given/, "insert_many has no as_given");
    };

    subtest find_or_insert => sub {
        my $new = $orm->find_or_insert(widgets => {name => 'foi', note => 'n1'}, by => ['name']);
        ok($new->{id}, "A missing row is inserted");
        is($dbh->selectrow_array("SELECT COUNT(*) FROM widgets WHERE name = 'foi'"), 1, "once");

        my $found = $orm->find_or_insert(widgets => {name => 'foi', note => 'n2'}, by => ['name']);
        is($found->{id},   $new->{id}, "An existing row is found by the 'by' fields");
        is($found->{note}, 'n1',       "and returned as it is, not changed");
        ok($orm->is_canon(widgets => $found), "The found row is held as current");

        my $plain = $orm->find_or_insert(plain => {id => 80, val => 'a'});
        is($plain->{id},                                                 80,  "'by' defaults to the primary key");
        is($orm->find_or_insert(plain => {id => 80, val => 'b'})->{val}, 'a', "and finds by it");

        like(dies { $orm->find_or_insert(widgets => {name => 'x'}) },                                qr/^find_or_insert\(\) finds by \(id\), which the fields do not give/,   "A 'by' field missing from the fields croaks");
        like(dies { $orm->find_or_insert(widgets => {name => 'x'}, by => 'name') },                  qr/^'by' must be a non-empty arrayref of field names/,                   "'by' must be an arrayref");
        like(dies { $orm->find_or_insert(widgets => {name => 'x'}, by => ['name'], x => 1) },        qr/^Unknown argument\(s\) to find_or_insert\(\): x/,                     "Unknown arguments croak");
        like(dies { $orm->find_or_insert(nopk => {msg => 'x'}) },                                    qr/^find_or_insert\(\) needs 'by': the table 'nopk' has no primary key/, "A table without a primary key needs 'by'");
        like(dies { $orm->find_or_insert(widgets => {name => 'foi', bogus => 1}, by => ['name']) },  qr/^The table 'widgets' has no field 'bogus'/,                           "An unknown field croaks when the row exists");
        like(dies { $orm->find_or_insert(widgets => {name => 'nope', bogus => 1}, by => ['name']) }, qr/^The table 'widgets' has no field 'bogus'/,                           "and when it does not");
        is($dbh->selectrow_array("SELECT COUNT(*) FROM widgets WHERE name = 'nope'"), 0, "before anything is inserted");

        like(dies { $orm->find_or_insert(widgets => {name => 'nullnote', note => undef}, by => ['note']) },                 qr/^find_or_insert\(\) cannot find by an undef value: \(note\)/, "An undef 'by' value croaks");
        like(dies { $orm->handle('widgets')->find_or_insert({name => 'nullnote', note => undef}, by => ['name', 'note']) }, qr/^find_or_insert\(\) cannot find by an undef value: \(note\)/, "and from a handle");
        is($dbh->selectrow_array("SELECT COUNT(*) FROM widgets WHERE name = 'nullnote'"), 0, "and nothing is inserted");

        $orm->insert(widgets => {name => "dup$_", note => 'dup'}) for 1, 2;
        like(dies { $orm->find_or_insert(widgets => {name => 'dup3', note => 'dup'}, by => ['note']) }, qr/^find_or_insert\(\) found more than one row in 'widgets' by \(note\)/, "More than one match croaks");

        # Another process inserting the row between the find and the insert: the insert fails, the row is found.
        my $race;
        my $mock = mock 'DBIx::QuickORM' => (
            around => [
                txn => sub {
                    my $orig = shift;
                    $orm->insert(widgets => {name => $race, note => 'racer'}) if defined $race;
                    $race = undef;
                    return $orig->(@_);
                },
            ],
        );

        $race = 'raced';
        my $raced = $orm->find_or_insert(widgets => {name => 'raced', note => 'mine'}, by => ['name']);
        is($raced->{note}, 'racer', "A row inserted first elsewhere is returned without an error");

        $race = 'other';
        isa_ok(dies { $orm->find_or_insert(widgets => {id => $new->{id}, name => 'other2'}, by => ['name']) }, ['DBIx::QuickORM::Exception::DB'], "An insert that fails with nothing to find rethrows its error");

        my $in_txn = $orm->txn(sub {
            my $row = $orm->find_or_insert(widgets => {name => 'in_txn'}, by => ['name']);
            $orm->find_or_insert(widgets => {name => 'in_txn'}, by => ['name'])->{id} == $row->{id} or die "not found again\n";
            return $row;
        });
        ok($in_txn->{id}, "It works inside an open transaction");

        if ($family eq 'DuckDB') {
            ok(!$dialect->supports_savepoints, "DuckDB has no savepoints, so a raced insert inside a transaction cannot be recovered");
            return;
        }

        my $after = $orm->txn(sub {
            $race = 'txn_race';
            my $row = $orm->find_or_insert(widgets => {name => 'txn_race', note => 'mine'}, by => ['name']);
            die "the race was not recovered\n" unless $row->{note} eq 'racer';
            return $orm->insert(widgets => {name => 'after_race'});
        });
        ok($after->{id}, "A failed insert inside an open transaction leaves it usable");
    };
};

done_testing;
