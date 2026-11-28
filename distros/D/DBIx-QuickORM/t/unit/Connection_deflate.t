# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Test::Type::Box;
use DBIx::QuickORM::Value qw/raw inflated binary sql/;

my $BOX = '+DBIx::QuickORM::Test::Type::Box';

sub orm {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE things (id INTEGER PRIMARY KEY, tags TEXT, plain TEXT)");
    $dbh->do("CREATE TABLE boxed (k TEXT PRIMARY KEY, v TEXT)");
    return DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {things => {tags => $BOX}, boxed => {k => $BOX}});
}

sub stored {
    my ($orm, $sql, @binds) = @_;
    return $orm->connection->dbh->selectrow_array($sql, undef, @binds);
}

subtest insert => sub {
    my $orm = orm();
    @DBIx::QuickORM::Test::Type::Box::CALLS = ();

    $orm->insert(things => {id => 1, tags => ['a', 'b']});
    is(stored($orm, 'SELECT tags FROM things WHERE id = 1'), 'a,b', "A reference on a typed field is deflated");
    my ($call) = @DBIx::QuickORM::Test::Type::Box::CALLS;
    ref_is($call->[1], $orm->db_map->field(things => 'tags'), "The type gets the map's field record");
    ref_is($call->[2], $orm->connection,                      "and the Connection");

    $orm->insert(things => {id => 2, tags => 'box:c'});
    is(stored($orm, 'SELECT tags FROM things WHERE id = 2'), 'c', "A plain value the type calls inflated is deflated");

    $orm->insert(things => {id => 3, tags => 'd', plain => 'box:e'});
    is([stored($orm, 'SELECT tags, plain FROM things WHERE id = 3')], ['d', 'box:e'], "Other plain values are sent as given, typed or not");

    like(dies { $orm->insert(things => {id => 4, plain => ['x']}) }, qr/^The field 'plain' of 'things' has no type to deflate a reference with/, "A reference on a field without a type croaks");

    $orm->insert(things => {id => 5, tags => 'box:f'}, raw => 1);
    is(stored($orm, 'SELECT tags FROM things WHERE id = 5'), 'box:f', "raw => 1 sends values as given");
};

subtest update_and_cas => sub {
    my $orm = orm();
    my $row = $orm->insert(things => {id => 1, tags => ['a']});

    my $new = $orm->update_row('things', $row, {tags => ['b', 'c']});
    is(stored($orm, 'SELECT tags FROM things WHERE id = 1'), 'b,c', "Changes are deflated");

    ok($orm->update_row('things', {id => 1, tags => ['b', 'c']}, {tags => 'z'}, cas => ['tags'], enforce_canon => 0), "Compare-and-swap values are deflated");
    is($orm->update_row('things', {id => 1, tags => 'box:z'}, {tags => 'y'}, cas => ['tags'], enforce_canon => 0, raw => 1), undef, "but not with raw");

    $orm->update_row('things', {id => 1}, {tags => 'box:w'}, enforce_canon => 0, raw => 1);
    is(stored($orm, 'SELECT tags FROM things WHERE id = 1'), 'box:w', "raw changes are sent as given");
};

subtest primary_keys => sub {
    my $orm = orm();
    my $row = $orm->insert(boxed => {k => ['p', 'q'], v => 1});
    is($row->{k}, 'p,q', "A typed primary key is deflated on insert, and the row data holds the database form");

    ref_is($orm->refresh_row('boxed', {k => ['p', 'q']}), $row, "Primary key values are deflated for lookups");
    my $moved = $orm->update_row('boxed', {k => 'box:p,q'}, {k => ['r']}, enforce_canon => 0);
    is($moved->{k},                                                 'r',   "and for updates, including the new key");
    is($orm->refresh_row('boxed', {k => 'p,q'}, db => 0),           undef, "which re-keys the lookup table under database forms");
    is($orm->delete_row('boxed', {k => ['r']}, enforce_canon => 0), 1,     "and for deletes");
};

subtest markers => sub {
    my $orm  = orm();
    my $conn = $orm->connection;

    $orm->insert(things => {id => 1, tags => raw('box:x'), plain => sql('upper(?)', 'abc')});
    is([stored($orm, 'SELECT tags, plain FROM things WHERE id = 1')], ['box:x', 'ABC'], "raw() is never deflated; sql() is inlined with its binds");

    $orm->insert(things => {id => 2, tags => inflated(['m', 'n']), plain => inflated('p')}, raw => 1);
    is([stored($orm, 'SELECT tags, plain FROM things WHERE id = 2')], ['m,n', 'p'], "inflated() is deflated even under raw => 1; on an untyped field it is sent as given");
    like(dies { $orm->insert(things => {id => 3, plain => inflated(['x'])}) }, qr/has no type to deflate a reference with/, "an inflated reference without a type croaks");

    $orm->insert(things => {id => 4, plain => binary("\x00\xff")});
    is(stored($orm, 'SELECT typeof(plain) FROM things WHERE id = 4'), 'blob', "binary() is bound as binary on any field");

    $orm->update_row('things', {id => 1}, {plain => sql('plain || ?', '!')}, enforce_canon => 0);
    is(stored($orm, 'SELECT plain FROM things WHERE id = 1'), 'ABC!', "sql() in changes is inlined");

    like(dies { $orm->update_row('things', {id => 1, plain => sql('x')}, {plain => 'y'}, cas => ['plain'], enforce_canon => 0) }, qr/^sql\(\) cannot be used in a primary key or compare-and-swap value \(the field 'plain'\)/, "sql() in a cas value croaks");
    like(dies { $orm->refresh_row('things', {id => sql('1')}) },                                                                  qr/^sql\(\) cannot be used in a primary key/,                                                 "and in a primary key lookup");

    my $boxed = $orm->insert(boxed => {k => 'p,q', v => 1});
    ref_is($orm->refresh_row('boxed', {k => raw('p,q')}),      $boxed, "A raw() primary key is looked up as given");
    ref_is($orm->refresh_row('boxed', {k => inflated('p,q')}), $boxed, "and an inflated() one deflated first");
    is($orm->refresh_row('boxed', {k => binary('p,q')}, cache => 0), undef, "a binary() key is bound as binary, which SQLite does not match to text");

    my $plain = {id => 9};
    ref_is($conn->deflate(things => $plain, raw => 1), $plain, "Under raw, values without a marker are returned as they are");
    like(dies { $conn->deflate(nope   => {id   => 1}) }, qr/^The table 'nope' is not in the database map/, "A table not in the map croaks");
    like(dies { $conn->deflate(things => {nope => 1}) }, qr/^The table 'things' has no field 'nope'/,      "and so does a field the table does not have");

    subtest without_returning => sub {
        my $mock = mock 'DBIx::QuickORM::Dialect::SQLite' => (override => [supports_returning_insert => sub { 0 }, supports_returning_update => sub { 0 }]);
        is($orm->insert(things => {id => sql('?', 7), plain => 'x'}), {id => 7}, "A primary key from sql() is not taken as given");
        like(dies { $orm->update_row('things', {id => 7}, {id => sql('8')}, enforce_canon => 0) }, qr/^update_row\(\) cannot set the primary key of 'things' with sql\(\)/, "and cannot be set without RETURNING");
        is($orm->update_row('boxed', {k => 'p,q'}, {k => binary('z')}, enforce_canon => 0), {k => 'z'}, "a binary() key is unwrapped in the new row data");
    };
};

subtest format => sub {
    my $U   = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE tokens (id CHAR(36) PRIMARY KEY, owner_uuid CHAR(36), bin_uuid BLOB)");
    my $orm = DBIx::QuickORM->new(
        dbh          => $dbh,
        row_class    => undef,
        type_options => {UUID   => {format => sub { "{$_[0]}" }}},
        types        => {tokens => {id     => {class => 'UUID', format => sub { uc $_[0] }}}},
    );

    my $row = $orm->insert(tokens => {id => $U, owner_uuid => $U, bin_uuid => $U});
    is([stored($orm, 'SELECT id, owner_uuid, length(bin_uuid) FROM tokens')], [uc($U), "{$U}", 16], "format runs on what the type deflated: the field's own, else type_options'; binary fields never");
    ref_is($orm->refresh_row(tokens => {id => $U}, db => 0), $row, "The row cache still keys the canonical value");

    $orm->clear_cache;
    is($orm->handle('tokens')->find($U)->{id}, uc($U), "A key value is formatted before it is sent");
    my $U2 = '0190a6e8-1d2c-7c3b-9f00-cba987654321';
    ok($orm->update_row(tokens => {id => $U, owner_uuid => $U}, {owner_uuid => $U2}, cas => ['owner_uuid'], enforce_canon => 0), "Compare-and-swap values are formatted, so they match");
    is(stored($orm, 'SELECT owner_uuid FROM tokens'), "{$U2}", "and so are changes");
    $orm->insert(tokens => {id => raw('raw-id'), owner_uuid => 'not a uuid'});
    is([stored($orm, "SELECT id, owner_uuid FROM tokens WHERE id = 'raw-id'")], ['raw-id', 'not a uuid'], "Values the type does not deflate are sent as given");
};

subtest type_loading => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
    ok(!DBIx::QuickORM::Test::Type::Upper->can('deflate'), "The type is not loaded yet");
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {t => {v => '+DBIx::QuickORM::Test::Type::Upper'}});
    ok(DBIx::QuickORM::Test::Type::Upper->can('deflate'), "A type named by 'types' is loaded at construction");
    $orm->insert(t => {id => 1, v => \'abc'});
    is(stored($orm, 'SELECT v FROM t'), 'ABC', "and used");

    like(
        dies { DBIx::QuickORM->new(dbh => $dbh, types => {t => {v => '+No::Such::Type'}}) },
        qr{^'types' names the type '\+No::Such::Type', which could not be loaded: Can't locate No/Such/Type\.pm},
        "A type that cannot be loaded croaks in new()",
    );
    like(
        dies { DBIx::QuickORM->new(dbh => $dbh, db_map => {t => {fields => {v => {affinity => 'string', db_type => 'text', type => 'text', orm_type => 'No::Such::Type'}}, pk => undef, unique => [], fk => {}}}) },
        qr{^'db_map' names the type '\+No::Such::Type', which could not be loaded},
        "and so does a type a given map names",
    );
};

done_testing;
