use strict;
use warnings;
use Test::More;
use Test::Exception;

# Every identifier in the generated DDL is quoted (karr k57).
#
# A reserved word has the shape of any other name, so a quoter that looks at
# the shape writes it bare, and CREATE TABLE order (...) is a syntax error.
# This file deploys a schema whose every name is a reserved word, by
# execution: it installs, reads back, takes rows through the ORM and upgrades,
# once by ALTER TABLE ... ADD COLUMN and once by a table rebuild.
#
# The ORM's own statements are quoted by the SQL maker, which this is not
# about; the connection sets quote_names so that it does not depend on what a
# driver does without it.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::Deploy;
use DBIO::SQLite::DDL;
use DBIO::SQLite::Introspect;

# ---------------------------------------------------------------------------
# v1: the table "table", the table "order" pointing at it, a view "view".
# ---------------------------------------------------------------------------
{
  package ReservedV1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package ReservedV1::Result::Table;
  use base 'DBIO::Core';
  __PACKAGE__->table('table');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    key => { data_type => 'varchar', size => 20, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package ReservedV1::Result::Order;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    group      => { data_type => 'varchar', size => 20, is_nullable => 0 },
    select     => { data_type => 'integer', is_nullable => 1 },
    values     => { data_type => 'text',    is_nullable => 1 },
    references => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(unique => ['group']);
  __PACKAGE__->belongs_to(from => 'ReservedV1::Result::Table', 'references');

  # An index named "index", one named "where" that is not partial, and one
  # that is: its WHERE is SQL from the schema and quotes its own column.
  __PACKAGE__->sqlite_index(index   => { columns => ['select'] });
  __PACKAGE__->sqlite_index(where   => { columns => [ 'values', 'select' ] });
  __PACKAGE__->sqlite_index(partial => {
    columns => ['select'],
    where   => '"select" IS NOT NULL',
  });
}
{
  package ReservedV1::Result::View;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('view');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer' },
    key => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->result_source_instance->view_definition(
    'SELECT "id", "key" FROM "table"');
}
ReservedV1->register_class(Table => 'ReservedV1::Result::Table');
ReservedV1->register_class(Order => 'ReservedV1::Result::Order');
ReservedV1->register_class(View  => 'ReservedV1::Result::View');

# ---------------------------------------------------------------------------
# v2: "table" gains the column "limit" (an ADD COLUMN), and "order"."values"
# becomes NOT NULL (no ALTER for that: the table is rebuilt).
# ---------------------------------------------------------------------------
{
  package ReservedV2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package ReservedV2::Result::Table;
  use base 'DBIO::Core';
  __PACKAGE__->table('table');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    key   => { data_type => 'varchar', size => 20, is_nullable => 0 },
    limit => { data_type => 'integer', is_nullable => 1, default_value => 7 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package ReservedV2::Result::Order;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    group      => { data_type => 'varchar', size => 20, is_nullable => 0 },
    select     => { data_type => 'integer', is_nullable => 1 },
    values     => { data_type => 'text',    is_nullable => 0 },   # now NOT NULL
    references => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(unique => ['group']);
  __PACKAGE__->belongs_to(from => 'ReservedV2::Result::Table', 'references');
  __PACKAGE__->sqlite_index(index   => { columns => ['select'] });
  __PACKAGE__->sqlite_index(where   => { columns => [ 'values', 'select' ] });
  __PACKAGE__->sqlite_index(partial => {
    columns => ['select'],
    where   => '"select" IS NOT NULL',
  });
}
{
  package ReservedV2::Result::View;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('view');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer' },
    key => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->result_source_instance->view_definition(
    'SELECT "id", "key" FROM "table"');
}
ReservedV2->register_class(Table => 'ReservedV2::Result::Table');
ReservedV2->register_class(Order => 'ReservedV2::Result::Order');
ReservedV2->register_class(View  => 'ReservedV2::Result::View');

my @CONNECT = ('dbi:SQLite::memory:', '', '', {
  AutoCommit      => 1,
  quote_names     => 1,
  on_connect_call => 'use_foreign_keys',
});

my $schema = ReservedV1->connect(@CONNECT);
my $dbh    = $schema->storage->dbh;

# ---------------------------------------------------------------------------
# Install.
# ---------------------------------------------------------------------------
lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
  'a schema of reserved words installs'
  or diag(DBIO::SQLite::DDL->install_ddl($schema));

# The statement, once, so that a failure above shows what was written. What
# counts is that it ran; the rest of this file asks the database.
my $ddl = DBIO::SQLite::DDL->install_ddl($schema);
like($ddl, qr/^CREATE TABLE "order" \($/m, 'the table name is quoted');
like($ddl, qr/^  "group" VARCHAR\(20\) NOT NULL,$/m, 'a column name is quoted');
like($ddl, qr/^  UNIQUE \("group"\),$/m, 'the column of a unique constraint is quoted');
like($ddl, qr/^  FOREIGN KEY \("references"\) REFERENCES "table"\("id"\)$/m,
  'a foreign key quotes its column, its target and the target column');
like($ddl, qr/^CREATE INDEX "index" ON "order" \("select"\);$/m,
  'an index quotes its name, its table and its column');
like($ddl, qr/^CREATE INDEX "partial" ON "order" \("select"\) WHERE "select" IS NOT NULL;$/m,
  'the WHERE of a partial index is the SQL the schema gave');
like($ddl, qr/^CREATE VIEW "view" AS SELECT "id", "key" FROM "table";$/m,
  'a view quotes its name, and its definition is the SQL the schema gave');

# ---------------------------------------------------------------------------
# The introspected model has every name back, exactly.
# ---------------------------------------------------------------------------
sub model { DBIO::SQLite::Introspect->new(dbh => $dbh)->model }

my $model = model();

is_deeply([ sort keys %{ $model->{tables} } ], [qw(order table view)],
  'tables and the view read back by name');
is($model->{tables}{view}{kind}, 'view', '"view" is a view');

is_deeply(
  [ map { $_->{column_name} } @{ $model->{columns}{order} } ],
  [qw(id group select values references)],
  'the columns of "order" read back, in order',
);
is_deeply(
  [ map { $_->{column_name} } @{ $model->{columns}{table} } ],
  [qw(id key)],
  'the columns of "table" read back',
);

my $indexes = $model->{indexes}{order};
is_deeply(
  { map { $_ => $indexes->{$_}{columns} } grep { ($indexes->{$_}{origin} // '') eq 'c' } keys %$indexes },
  { index => ['select'], where => [ 'values', 'select' ], partial => ['select'] },
  'the explicit indexes read back by name, with their columns',
);
my ($unique) = grep { ($_->{origin} // '') eq 'u' } values %$indexes;
is_deeply($unique->{columns}, ['group'], 'the unique constraint is over "group"');

# Only the index that has a WHERE clause is partial. An index that is merely
# named "where" has the word in its statement too, between quotes.
is($indexes->{partial}{partial}, 1, 'the index with a WHERE clause is partial');
is($indexes->{where}{partial},   0, 'an index named "where" is not');
is($indexes->{index}{partial},   0, 'nor is the plain one');

is_deeply(
  [ map { +{ from => $_->{from_columns}, table => $_->{to_table}, to => $_->{to_columns} } }
      @{ $model->{foreign_keys}{order} } ],
  [ { from => ['references'], table => 'table', to => ['id'] } ],
  'the foreign key reads back: "references" -> "table"("id")',
);

# ---------------------------------------------------------------------------
# Rows go in and come out through the ORM.
# ---------------------------------------------------------------------------
my $parent = $schema->resultset('Table')->create({ key => 'k1' });
ok($parent->id, 'a row in "table"');

my $row;
lives_ok {
  $row = $schema->resultset('Order')->create({
    group      => 'g1',
    select     => 3,
    values     => 'v1',
    references => $parent->id,
  });
} 'a row in "order", every column a reserved word';
$schema->resultset('Order')->create({
  group => 'g2', select => undef, values => 'v2', references => $parent->id,
});

my $read = $schema->resultset('Order')->search({ group => 'g1' })->single;
is_deeply(
  { $read->get_columns },
  { id => $row->id, group => 'g1', select => 3, values => 'v1', references => $parent->id },
  'and it reads back, searched by a reserved-word column',
);
is($read->from->key, 'k1', 'the belongs_to resolves');
is_deeply(
  [ map { $_->key } $schema->resultset('View')->all ],
  ['k1'],
  'the view "view" is selectable',
);

throws_ok {
  $schema->resultset('Order')->create({
    group => 'g1', values => 'dup', references => $parent->id,
  });
} qr/UNIQUE constraint failed: order\.group/, 'the unique constraint is in force';
throws_ok {
  $schema->resultset('Order')->create({
    group => 'g3', values => 'orphan', references => 999,
  });
} qr/FOREIGN KEY constraint failed/, 'and so is the foreign key';

# The same schema again: nothing to do.
{
  my $diff = DBIO::SQLite::Deploy->new(schema => $schema)->diff;
  ok(!$diff->has_changes, 'a diff against the schema it was installed from is empty')
    or diag($diff->summary);
}

# ---------------------------------------------------------------------------
# v2: one ADD COLUMN, one rebuild.
# ---------------------------------------------------------------------------
my $v2 = ReservedV2->connect(sub { $dbh }, { quote_names => 1 });
my $upgrade = DBIO::SQLite::Deploy->new(schema => $v2);

my $diff = $upgrade->diff;
ok($diff->has_changes, 'v2 differs');

my @ops = @{ $diff->operations };
is_deeply(
  [ map { [ ref $_, $_->table_name ] } grep { !$_->isa('DBIO::SQLite::Diff::Index') } @ops ],
  [
    [ 'DBIO::SQLite::Diff::Column',  'table' ],
    [ 'DBIO::SQLite::Diff::Rebuild', 'order' ],
  ],
  'one column op on "table", one rebuild of "order"',
);
is_deeply(
  [ sort map { $_->index_name } grep { $_->isa('DBIO::SQLite::Diff::Index') } @ops ],
  [qw(index partial where)],
  'and the three explicit indexes of the rebuilt table, to be created again',
);

my $sql;
lives_ok { $sql = $diff->as_sql } 'the diff renders';
like($sql, qr/^ALTER TABLE "table" ADD COLUMN "limit" INTEGER DEFAULT 7;$/m,
  'the added column: table and column quoted');
like($sql, qr/^ALTER TABLE "order__dbio_rebuild" RENAME TO "order";$/m,
  'the rebuild: temporary and final name quoted');

lives_ok { $upgrade->apply($diff) } 'the upgrade applies' or diag($sql);

is_deeply(
  $dbh->selectall_arrayref(
    'SELECT "id", "group", "select", "values", "references" FROM "order" ORDER BY "id"'),
  [ [ 1, 'g1', 3, 'v1', 1 ], [ 2, 'g2', undef, 'v2', 1 ] ],
  'the rows of the rebuilt table survived',
);
is_deeply(
  $dbh->selectall_arrayref('SELECT "id", "key", "limit" FROM "table"'),
  [ [ 1, 'k1', 7 ] ],
  'the row of the other table has the new column, with its default',
);

throws_ok {
  $dbh->do(q{INSERT INTO "order" ("group", "references") VALUES ('g9', 1)});
} qr/NOT NULL constraint failed: order\.values/, '"values" is NOT NULL now';

my $after = model();
is_deeply(
  [ sort grep { ($after->{indexes}{order}{$_}{origin} // '') eq 'c' }
      keys %{ $after->{indexes}{order} } ],
  [qw(index partial where)],
  'the explicit indexes are back on the rebuilt table',
);
is_deeply(
  [ map { $_->{to_table} } @{ $after->{foreign_keys}{order} } ],
  ['table'],
  'and so is its foreign key',
);

my $settled = $upgrade->diff;
ok(!$settled->has_changes, 'a second diff is empty') or diag($settled->summary);

my $added = $v2->resultset('Order')->create({
  group => 'g4', select => 1, values => 'v4', references => $parent->id,
});
ok($added->id, 'the ORM writes to the upgraded tables');
is($v2->resultset('Table')->find($parent->id)->limit, 7, 'and reads the new column');

done_testing;
