# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect;
use DBIx::QuickORM::Map;
use DBIx::QuickORM::Source::Table;

my $map = DBIx::QuickORM::Map->new(
    tables => {
        users => {fields => {id => {}, name => {}, bio => {}}, pk => ['id']},
        slim  => {fields => {id => {}, name => {}, bio => {}}, pk => ['id'], default_fields => ['id', 'name']},
        log   => {fields => {msg => {}}, pk => undef},
        'a"b' => {fields => {x => {}}, pk => ['x']},
    }
);

my $users = DBIx::QuickORM::Source::Table->new(table => 'users', db_map => $map);
is($users->table,                         'users',               "table");
is($users->pk,                            ['id'],                "pk comes from the map");
is($users->select_fields,                 ['bio', 'id', 'name'], "select_fields is every field, sorted, when the table sets none");
is($users->select_fields(['name', 'id']), ['name', 'id'],        "or the given fields");
is($users->select_fields(['name']),       ['name', 'id'],        "with the primary key added");
is($users->select_fields({n => 'name'}),  {n => 'name'},         "and computed fields as they are");
like(dies { $users->select_fields(['name', 'nope']) }, qr/^The table 'users' has no field 'nope'/, "An unknown field croaks, naming the table and field");
my $fields = $map->table('users')->{fields};
is($users->field_records, {%$fields, map { ("users.$_" => $fields->{$_}) } keys %$fields}, "field_records are the table's fields, by name and qualified");
is([$users->query_sql],   [],                                                              "A table is not a query");
ref_is($users->field_records, $users->field_records, "field_records is built once and shared");

is(DBIx::QuickORM::Source::Table->new(table => 'slim', db_map => $map)->select_fields, ['id', 'name'], "or the table's default_fields");
is(DBIx::QuickORM::Source::Table->new(table => 'log',  db_map => $map)->pk,            undef,          "pk is undef for a table without one");

is([DBIx::QuickORM::Source::Table->new(table => 'a"b', db_map => $map)->from_sql('DBIx::QuickORM::Dialect')], ['"a""b"', []], "from_sql quotes the name through the dialect");

subtest results => sub {
    require DBI;
    require DBIx::QuickORM;
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do($_) for "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)", "CREATE TABLE log (msg TEXT)";
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_classes => {log => undef});

    my $held   = $orm->connection->lookup->ingest(users => {id => 1, name => 'a'});
    my $source = DBIx::QuickORM::Source::Table->new(table => 'users', db_map => $orm->db_map);
    my ($rows, $build) = $source->results($orm, [{id => 1, name => 'a'}, {id => 2, name => 'b'}], 1);
    ref_is($rows->[0], $held, "Rows of a table with a primary key are ingested");
    ok($orm->is_canon(users => $rows->[1]), "every one of them");
    isa_ok($build->($rows->[0]), ['DBIx::QuickORM::Row'], "and built with the table's row class");
    is(($source->results($orm, $rows, 1, undef))[1], undef, "or the handle's: undef has no build, so the row data is handed out");

    my $fresh = [{id => 3, name => 'c'}];
    my ($kept) = $source->results($orm, $fresh, 0);
    ref_is($kept, $fresh, "Without ingest the rows are kept as fetched");
    ok(!$orm->is_canon(users => $fresh->[0]), "and never enter the lookup table");

    my $raw = [{msg => 'x'}];
    my ($log, $log_build) = DBIx::QuickORM::Source::Table->new(table => 'log', db_map => $orm->db_map)->results($orm, $raw, 1);
    ref_is($log, $raw, "Rows of a table without a primary key are kept as fetched");
    is($log_build, undef, "and handed out as they are, the table having no row class");

    ref_is($orm->handle('users')->source, $orm->handle('users')->source, "The ORM builds one source per table and its handles share it");
    like(dies { $orm->handle('nope') }, qr/^The table 'nope' is not in the database map/, "An unknown table still croaks");
};

like(dies { DBIx::QuickORM::Source::Table->new(table => 'nope', db_map => $map) }, qr/^The table 'nope' is not in the database map/, "An unknown table croaks");
like(dies { DBIx::QuickORM::Source::Table->new(table => '',     db_map => $map) }, qr/^A 'table' is required/,                       "A table is required");
like(dies { DBIx::QuickORM::Source::Table->new(table => 'users') }, qr/^A 'db_map' is required/, "and so is the map");

done_testing;
