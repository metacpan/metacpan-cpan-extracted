# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Source::Table;

# Row classes are loaded at construction unless they already have a new().
{

    package My::Default;
    sub new { bless {}, shift }
}
{

    package My::Trimmed;
    sub new { bless {}, shift }
}

sub orm {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE things (id INTEGER PRIMARY KEY, name TEXT, other TEXT)");
    $dbh->do("CREATE TABLE trimmed (id INTEGER PRIMARY KEY, a TEXT, b TEXT)");
    return DBIx::QuickORM->new(dbh => $dbh, row_class => undef, default_fields => {trimmed => ['a']}, @_);
}

subtest where_sql => sub {
    my $conn = orm()->connection;
    my ($sql, $binds) = $conn->_where_sql({b => 2, a => undef, c => 'x'});
    is($sql,   '"a" IS NULL AND "b" = ? AND "c" = ?', "Fields in order; undef becomes IS NULL");
    is($binds, [[b => 2], [c => 'x']],                "Binds carry their field");
};

subtest statement_cache => sub {
    my $orm    = orm();
    my $conn   = $orm->connection;
    my $cached = sub { [sort grep { !m/^SELECT 1/ } map { (split m/!\001/)[0] } keys %{$conn->dbh->{CachedKids} // {}}] };

    $orm->insert(things => {id => 1, name => 'a'});
    $orm->insert(things => {id => 2, name => 'b'});
    $orm->update_row(things => {id => 1}, {name => 'c'}, enforce_canon => 0);
    $orm->refresh_row(things => {id => 2}, cache => 0);
    $orm->delete_row(things => {id => 2}, enforce_canon => 0);
    is(
        $cached->(),
        [
            'DELETE FROM "things" WHERE "id" = ?',
            'INSERT INTO "things" ("id", "name") VALUES (?, ?)',
            'SELECT "id", "name", "other" FROM "things" WHERE "id" = ?',
            'UPDATE "things" SET "name" = ? WHERE "id" = ? RETURNING "id", "name", "other"',
        ],
        "Each single-row primitive's statement is prepared once per shape and reused"
    );

    my %shapes = %{$conn->{statements}};
    $orm->insert(things => {id => 3, name => 'd'});
    is($conn->{statements}, \%shapes, "A shape seen before builds no new SQL");

    $orm->insert(things => {id => 4, name => DBIx::QuickORM::Value::sql("'e' || ?", 'f')});
    $orm->update_row(things => {id => 4}, {name => DBIx::QuickORM::Value::sql("'g'")}, enforce_canon => 0);
    $orm->insert_many(things => [{id => 5}, {id => 6}]);
    $orm->handle('things')->where({id => 5})->all;
    is(scalar(@{$cached->()}), 4,        "SQL holding sql() text, bulk inserts, and handle queries are not cached");
    is($conn->{statements},    \%shapes, "nor is their SQL kept");
};

subtest default_fields => sub {
    my $orm  = orm();
    my $conn = $orm->connection;
    is($conn->_default_fields('trimmed'), ['a', 'id'], "A table's default_fields");
    is($conn->_default_fields('things'), ['id', 'name', 'other'], "or every field");

    my $row = $orm->insert(trimmed => {id => 1, a => 'x', b => 'y'});
    is($row, {id => 1, a => 'x'}, "RETURNING lists the default fields");
    is($orm->refresh_row('trimmed', {id => 1}, fields => ['b'], cache => 0), {id => 1, a => 'x', b => 'y'}, "fields reads others, ingested into the canon hash");
};

subtest enforce_canon_defaults => sub {
    my $orm = orm(enforce_canon => 0);
    my $row = $orm->insert(things => {id => 1, name => 'a'});

    ok($orm->update_row('things', {id => 1}, {name => 'b'}), "With the ORM's enforce_canon off, stale row data is accepted outside a transaction");
    like(dies { $orm->update_row('things', {id => 1}, {name => 'c'}, enforce_canon => 1) }, qr/^The row data for 'things' is not canon/, "enforce_canon => 1 overrides it");

    my $txn = $orm->txn;
    like(dies { $orm->update_row('things', {id => 1}, {name => 'c'}) }, qr/^The row data for 'things' is not canon/, "Inside a transaction the default is to enforce");
    ok($orm->update_row('things', {id => 1}, {name => 'c'}, enforce_canon => 0), "enforce_canon => 0 still bypasses it");
    like(dies { $orm->delete_row('things', {id => 1}) }, qr/^The row data for 'things' is not canon/, "delete_row too");
    $txn->rollback;
};

subtest arguments => sub {
    my $orm = orm();
    like(dies { $orm->update_row(undef, {id => 1}, {name => 1}) },                                                                          qr/^A table name is required/,                               "A table is required");
    like(dies { $orm->update_row('things', 'x', {name => 1}) },                                                                             qr/^Expected row data \(a hashref\) or a row object, got x/, "row_data must be row data");
    like(dies { $orm->update_row('things', {id => 1}, {name => 1}, cas => 'name', enforce_canon => 0) },                                    qr/^'cas' must be an arrayref of field names/,               "cas must be an arrayref");
    like(dies { $orm->refresh_row('things', {id => 1}, fields => 'name') },                                                                 qr/^'fields' must be an arrayref of field names/,            "fields must be an arrayref");
    like(dies { $orm->connection->select(DBIx::QuickORM::Source::Table->new(table => 'things', db_map => $orm->db_map), 'SELECT 1', 'x') }, qr/^'binds' must be an arrayref/,                            "binds must be an arrayref");
};

subtest refresh_missing_row => sub {
    my $orm = orm();
    my $row = $orm->insert(things => {id => 1, name => 'a'});
    $orm->connection->dbh->do('DELETE FROM things');
    is($orm->refresh_row('things', {id => 1}, cache => 0), undef, "A row the database no longer has is undef");
    is($orm->refresh_row('things', {id => 1}, db    => 0), undef, "and is dropped from the lookup table");
};

subtest row_class_resolution => sub {
    my $orm = orm(row_class => 'My::Default', row_classes => {trimmed => 'My::Trimmed'});
    is($orm->_row_class('things'),  'My::Default', "The ORM's row class by default");
    is($orm->_row_class('trimmed'), 'My::Trimmed', "A table's row class wins");

    $orm = orm(row_class => 'My::Default', row_classes => {trimmed => undef});
    is($orm->_row_class('trimmed'),  undef, "A table's undef means hashrefs");
    is($orm->_row('trimmed', undef), undef, "No row data, no row");
};

done_testing;
