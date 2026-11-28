# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Value qw/sql/;

my %JSON = (PostgreSQL => 'JSONB', SQLite => 'JSON', DuckDB => 'JSON', MariaDB => 'JSON', MySQL => 'JSON');

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh  = $db->connect;
    my $json = $family eq 'PostgreSQL' && $dbh->{pg_server_version} < 90400 ? 'JSON' : $JSON{$family};
    $dbh->do("CREATE TABLE people (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), bio VARCHAR(100), prefs $json)");
    $dbh->do("CREATE TABLE notes (msg VARCHAR(20))");

    # MariaDB reports JSON columns as longtext, so prefs is given its type.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, omit => {people => ['bio']}, types => {people => {prefs => 'JSON'}});

    my $stored = sub { $dbh->selectrow_array("SELECT $_[0] FROM people WHERE id = ?", undef, $_[1]) };

    subtest read => sub {
        my $row = $orm->insert(people => {id => 1, name => 'bob', bio => 'likes cats', prefs => {color => 'red'}});
        isa_ok($row, ['DBIx::QuickORM::Row'], "Rows are DBIx::QuickORM::Row by default");
        is($row->table, 'people',  "with their table");
        is($row->pk,    {id => 1}, "and primary key");

        is($row->field('name'), 'bob', "field reads a value, fetching it when the write did not return it");
        my $prefs = $row->field('prefs');
        is($prefs, {color => 'red'}, "and inflates it through the field's type");
        ref_is_not($row->field('prefs'), $prefs, "JSON data is handed out as a copy of the cached value");
        $prefs->{color} = 'green';
        is($row->field('prefs'), {color => 'red'}, "so changing it changes neither the row nor the next read");
        like($row->raw_field('prefs'), qr/"color":\s*"red"/, "raw_field gives the JSON text");
        is([$row->fields(['name', 'prefs'])], ['bob', {color => 'red'}], "fields reads several");
        is([$row->fields(qw/name prefs/)],    ['bob', {color => 'red'}], "given as a list too");

        ok(!exists $row->row_data->{bio}, "An omitted field is not fetched");
        my $data = $row->row_data;
        is($row->raw_field('bio'), 'likes cats', "Reading it, in either form, fetches it");
        ref_is($row->row_data, $data, "into the same row data when the row has not changed");

        like(dies { $row->field('nope') }, qr/^The table 'people' has no field 'nope'/, "An unknown field croaks");
    };

    subtest adopt_changed_row => sub {
        my $row = $orm->refresh_row('people', {id => 1}, cache => 0);
        ok(!exists $row->row_data->{bio}, "Refreshed with the default fields, bio omitted");
        is($row->field('name'), 'bob', "name read and cached");

        $dbh->do("UPDATE people SET name = 'robert', bio = 'likes dogs' WHERE id = 1");
        my $data = $row->row_data;
        is([$row->fields(qw/name bio/)], ['robert', 'likes dogs'], "Fetching a missing field alongside a present one sees the change");
        ok($row->row_data != $data, "and the row took the new row data");
        ok($row->is_canon,          "which is canon");
        is($row->field('name'), 'robert', "and reads the new values");
    };

    subtest fetch_keeps_present_fields => sub {
        my $row = $orm->handle('people')->no_cache->fields(['name', 'prefs'])->where({id => 1})->only;
        ok(!$row->is_canon, "A no_cache row is not canon");
        is($row->field('bio'),            'likes dogs',            "A missing field is fetched");
        is([sort keys %{$row->row_data}], [qw/bio id name prefs/], "and the fields already present are kept");
        is($row->field('name'),           'robert',                "with their values");
    };

    subtest non_canon_fetch_skips_cache => sub {
        $orm->clear_cache;
        my $row  = $orm->handle('people')->no_cache->fields(['name'])->where({id => 1})->only;
        my $data = $row->row_data;
        is($row->field('bio'), 'likes dogs', "A no_cache row fetches a missing field");
        ref_is($row->row_data, $data, "into its own row data");
        is([sort keys %$data], [qw/bio id name/], "adding just that field");
        ok(!$row->is_canon, "The row stays not canon");
        is($orm->connection->lookup->lookup(people => {id => 1}), undef, "and the lookup table is unchanged");

        my $canon = $orm->refresh_row('people', {id => 1});
        $dbh->do("UPDATE people SET name = 'bobby' WHERE id = 1");
        my $other = $orm->handle('people')->no_cache->fields(['prefs'])->where({id => 1})->only;
        is($other->field('name'), 'bobby', "A non-canon row reads the current value");
        ref_is($orm->connection->lookup->lookup(people => {id => 1}), $canon->row_data, "leaving the canon entry alone");
        is($canon->raw_field('name'), 'robert', "and the canon row's data with it");
        $dbh->do("UPDATE people SET name = 'robert' WHERE id = 1");
    };

    subtest update => sub {
        my $row   = $orm->refresh_row('people', {id => 1});
        my $prefs = $row->field('prefs');

        ref_is($row->update({prefs => {color => 'blue'}, name => 'bert'}), $row, "update returns the row");
        like($stored->('prefs', 1), qr/"color":\s*"blue"/, "The change was deflated through the type");
        is($stored->('name', 1), 'bert', "and plain values sent as given");
        ok($row->is_canon, "The row holds the new canon row data");
        is($row->field('prefs'), {color => 'blue'}, "and reads the new value, not the cached one");

        my $copy = $orm->refresh_row('people', {id => 1});
        $orm->update_row('people', $copy, {name => 'other'});
        ok(!$row->is_canon, "A write elsewhere leaves the row stale");
        for my $err (dies { $row->update({name => 'x'}) }, dies { $row->delete }, dies { $orm->update_row(people => {%{$row->row_data}}, {name => 'x'}) }) {
            like(
                $err,
                qr/is not canon .*; refresh the row, or pass enforce_canon => 0; for an update, a row's cas_update\(\) writes only while the database still holds what the row read/,
                "Updating it, deleting it, or update_row with its row data croaks with the one message naming the ways out",
            );
        }
        ok($row->update({name => 'x'}, enforce_canon => 0), "unless told otherwise");

        $row->refresh;
        is($row->update({name => 'y'}, cas => ['name'], enforce_canon => 0) && 1, 1, "A compare-and-swap that matches updates");
        my $stale = DBIx::QuickORM::Row->new(orm => $orm, table => 'people', row_data => {id => 1, name => 'nope'});
        is($stale->update({name => 'z'}, cas => ['name'], enforce_canon => 0), undef,                     "one that misses returns undef");
        is($stale->row_data,                                                   {id => 1, name => 'nope'}, "and leaves the row alone");
    };

    subtest cas_update => sub {
        my $row = $orm->insert(people => {id => 3, name => 'cas', prefs => {n => 1}});
        $row->refresh;
        ref_is($row->cas_update({name => 'cas2'}), $row, "cas_update returns the row when the database still holds the changed fields' values");
        is($stored->('name', 3), 'cas2', "and the change is written");
        $row->refresh;                                             # without RETURNING for UPDATE the row holds only its key now
        $row->cas_update({prefs => {n => 2}}, cas => ['name']);    # JSON does not compare as text everywhere
        is($row->field('prefs'), {n => 2}, "Changes are deflated through the type");
        ok($row->is_canon, "The row holds the new canon row data");

        $row->refresh;
        $dbh->do("UPDATE people SET name = 'elsewhere' WHERE id = 3");
        my $data = $row->row_data;
        is($row->cas_update({name => 'mine'}), undef, "A changed field changed elsewhere: undef");
        ref_is($row->row_data, $data, "and the row is unchanged");
        is($stored->('name', 3), 'elsewhere', "and so is the database");

        is($row->cas_update({prefs => {n => 3}}, cas => ['name']), undef, "cas compares the given fields instead of the changed ones");
        $row->refresh;
        is($row->cas_update({prefs => {n => 3}}, cas => ['name']) && 1, 1, "and writes while they match");

        my $before = $orm->refresh_row('people', {id => 3}, cache => 0);
        $orm->txn(sub {
            ok(!$before->is_canon, "A row read before a transaction is not canon inside it");
            like(dies { $before->update({name => 'txn'}) }, qr/cas_update\(\) writes only while the database still holds what the row read/, "so update croaks, pointing at cas_update");
            ref_is($before->cas_update({name => 'txn'}), $before, "but cas_update writes it while the database matches");
            ok($before->is_canon, "and it is canon now");
        });
        is($stored->('name', 3), 'txn', "The write committed");

        my $stale = $orm->refresh_row('people', {id => 3}, cache => 0);
        $dbh->do("UPDATE people SET name = 'again' WHERE id = 3");
        $orm->txn(sub { is($stale->cas_update({name => 'lost'}), undef, "Inside a transaction a conflict is undef too") });
        is($stale->field('name'), 'txn', "leaving the row unchanged");

        my $slim = DBIx::QuickORM::Row->new(orm => $orm, table => 'people', row_data => {id => 3});
        like(dies { $slim->cas_update({name => 'x'}) },               qr/^The 'cas' field 'name' is not in the row data/,         "A compared field the row does not hold croaks");
        like(dies { $row->cas_update('x') },                          qr/^cas_update\(\) needs a hashref of changes/,             "Changes must be a hashref");
        like(dies { $row->cas_update({name => 'x'}, auto_cas => 1) }, qr/^cas_update\(\) takes only the 'cas' option/,            "and only cas is taken");
        like(dies { $row->cas_update({name => 'x'}, cas => []) },     qr/^cas_update\(\) needs a field to compare/,               "An empty cas list croaks");
        like(dies { $row->cas_update({}) },                           qr/^update_row\(\) needs a hashref of at least one change/, "Empty changes croak as empty changes");
        $stale->delete(enforce_canon => 0);
    };

    subtest refresh => sub {
        my $row = $orm->refresh_row('people', {id => 1});
        $dbh->do("UPDATE people SET name = 'fresh' WHERE id = 1");
        is($row->field('name'), 'y', "A row does not see changes made behind the ORM");
        ref_is($row->refresh, $row, "refresh returns the row");
        is($row->field('name'), 'fresh', "and reads the database");
    };

    subtest delete => sub {
        my $row = $orm->insert(people => {id => 2, name => 'gone'});
        is($row->delete,         1,     "delete deletes the row");
        is($stored->('name', 2), undef, "from the database");
        like(dies { $row->refresh },      qr/^Cannot refresh a row that is not in the database; insert it first/,                 "Refreshing a deleted row croaks");
        like(dies { $row->field('bio') }, qr/^Cannot fetch missing fields of a row that is not in the database; insert it first/, "and so does fetching a field");

        my $viv = $orm->vivify(people => {id => 5, name => 'viv'});
        is($viv->field('bio'),                 undef,                 "A vivified row gives undef for a field it was not given");
        is([$viv->raw_fields(qw/name bio/)],   ['viv', undef],        "raw_fields too, beside the fields it was given");
        is([$viv->fields(qw/name bio prefs/)], ['viv', undef, undef], "and fields");

        my $behind = $orm->insert(people => {id => 3, name => 'behind'});
        $dbh->do("DELETE FROM people WHERE id = 3");
        like(dies { $behind->field('bio') }, qr/^Cannot fetch missing fields: the row is no longer in the table 'people'/, "Fetching a field of a row deleted behind the ORM croaks");
        ok($behind->was_deleted, "and marks it deleted");

        my $data = $orm->insert(people => {id => 4, name => 'data'}, data => 1);
        is($orm->delete_row(people => $data),             1,         "delete_row on row data");
        is(DBIx::QuickORM::LookupTable->row_state($data), 'deleted', "marks the row data deleted");
    };

    subtest no_primary_key => sub {
        my $row = DBIx::QuickORM::Row->new(orm => $orm, table => 'notes', row_data => {msg => 'hi'});
        is($row->field('msg'), 'hi',  "A row without a primary key reads what it has");
        is($row->pk,           undef, "and has no pk");
        for my $action (qw/update cas_update delete refresh is_canon/) {
            my @args = $action =~ m/update/ ? ({msg => 'x'}) : ();
            like(dies { $row->$action(@args) }, qr/^Cannot $action a row without a primary key \(table 'notes'\)/, "$action croaks");
        }

        my $partial = DBIx::QuickORM::Row->new(orm => $orm, table => 'people', row_data => {name => 'x'});
        like(dies { $partial->field('bio') }, qr/^Cannot fetch missing fields of a row without a primary key/, "A missing field cannot be fetched without the primary key");
    };

    subtest no_table => sub {
        my $row = $orm->handle(\"SELECT id, name AS who FROM people WHERE id = 1")->first;
        isa_ok($row, ['DBIx::QuickORM::Row'], "A query's rows use the default row class");
        is($row->table,                undef,        "with no table");
        is($row->field('who'),         'fresh',      "field reads any selected name as it is");
        is([$row->fields(qw/id who/)], [1, 'fresh'], "and so does fields");
        is($row->field('nope'),        undef,        "a name not selected is undef, not fetched");
        is($row->pk,                   undef,        "and there is no pk");
        like(dies { $row->refresh },             qr/^Cannot refresh a row without a primary key at /,           "writes croak, naming no table");
        like(dies { $row->follow_fk('people') }, qr/^Cannot follow a foreign key from a row with no table at /, "and so does follow_fk");

        my $computed = $orm->handle('people')->fields({n => sql('COUNT(*)')})->row_class('DBIx::QuickORM::Row')->first;
        is($computed->field('n'), 1,     "A computed row given a row class reads its computed field");
        is($computed->pk,         undef, "and has no pk");
    };

    subtest hashrefs => sub {
        my $plain = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
        is(ref($plain->refresh_row('people', {id => 1})), 'HASH', "row_class => undef gives hashrefs");
        my $mixed = DBIx::QuickORM->new(dbh => $dbh, row_classes => {people => undef});
        is(ref($mixed->refresh_row('people', {id => 1})), 'HASH', "and so does a table's row class of undef");
    };
};

done_testing;
