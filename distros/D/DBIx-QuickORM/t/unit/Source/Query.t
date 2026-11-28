# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Source::Query;

my $q = DBIx::QuickORM::Source::Query->new(sql => 'SELECT a FROM t WHERE b = ?', binds => [1]);
is($q->table,                undef, "A query has no table");
is($q->pk,                   undef, "no primary key");
is($q->select_fields,        undef, "and selects every column");
is($q->select_fields(['a']), ['a'], "or what the handle gives");
is($q->field_records,        {},    "It has no field records");

is([$q->query_sql],       ['SELECT a FROM t WHERE b = ?',              [[undef, 1]]], "query_sql is the query, its binds untyped");
is([$q->from_sql(undef)], ['(SELECT a FROM t WHERE b = ?) qorm_query', [[undef, 1]]], "from_sql wraps it as a subquery");

is(DBIx::QuickORM::Source::Query->new(sql => 'SELECT 1')->binds, [], "binds default to none");

subtest results => sub {
    require DBI;
    require DBIx::QuickORM;
    my $orm = DBIx::QuickORM->new(dbh => DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1}));
    my $raw = [{a => 1}];

    my ($rows, $build) = $q->results($orm, $raw, 1);
    ref_is($rows, $raw, "The rows are kept as fetched");
    isa_ok($build->($raw->[0]), ['DBIx::QuickORM::Row'], "and built with the ORM's row class");
    is(($q->results($orm, $raw, 1, undef))[1], undef, "or the handle's, here undef: no build, the row data is handed out");
};

like(dies { DBIx::QuickORM::Source::Query->new(sql => ' ') },                    qr/^A query source needs its SQL as a string/, "Blank SQL croaks");
like(dies { DBIx::QuickORM::Source::Query->new(sql => \'x') },                   qr/^A query source needs its SQL as a string/, "and so does a reference");
like(dies { DBIx::QuickORM::Source::Query->new(sql => 'SELECT 1', binds => 1) }, qr/^'binds' must be an arrayref/,              "binds must be an arrayref");

done_testing;
