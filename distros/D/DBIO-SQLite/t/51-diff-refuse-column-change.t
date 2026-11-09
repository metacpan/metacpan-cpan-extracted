use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Schema::ModelCompiler ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Diff::Column ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k73 -- a column change the diff cannot carry out is refused, loudly.
#
# SQLite has no ALTER COLUMN. Where the target model holds the table's CREATE
# TABLE statement, DBIO::SQLite::Diff rebuilds the table (ADR 0003). Where it
# does not -- target_from_compiled, a model built by hand -- the column op used
# to answer with an SQL comment:
#
#   -- ALTER COLUMN not supported by SQLite ALTER TABLE; rebuild required for t.c
#
# Core splits a script at every semicolon, the one in that comment included, so
# `rebuild required for t.c` reached SQLite as a statement: syntax error near
# "rebuild", after every statement before it had already run. Without the
# semicolon the comment would have been dropped, and an upgrade that reports
# changes would have applied none of this one and said nothing.
#
# Neither is acceptable. The op now throws, naming the table, the column, what
# changed and why it cannot be done -- and since a diff is rendered before its
# first statement runs, nothing has been applied when it does.

# --- the alter op -----------------------------------------------------------

my $no_statement = { t => { table_name => 't' } };

{
  my ($op) = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'INTEGER', not_null => 0 } ] },
    { t => [ { column_name => 'a', data_type => 'TEXT',    not_null => 1 } ] },
    $no_statement, $no_statement,
  );
  is($op->action, 'alter', 'a changed type and nullability is an alter op');

  throws_ok { $op->as_sql }
    qr/\ACannot change column t\.a \(type INTEGER -> TEXT, NOT NULL no -> yes\): SQLite has no ALTER COLUMN, and the target model holds no CREATE TABLE statement to rebuild table t from at /,
    'as_sql refuses: table, column, both changes old -> new, and the reason';

  my $error = $@;
  is(scalar(() = $error =~ /\n/g), 1, 'the refusal is one line');
  unlike($error, qr/;/, 'with nothing in it a statement splitter would cut at');

  is($op->summary, '  ~column: t.a (TEXT)', 'summary still names the op');
}

{
  my ($op) = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'TEXT', default_value => undef } ] },
    { t => [ { column_name => 'a', data_type => 'TEXT', default_value => q{'x'} } ] },
    $no_statement, $no_statement,
  );
  throws_ok { $op->as_sql }
    qr/\ACannot change column t\.a \(default none -> 'x'\): SQLite has no ALTER COLUMN/,
    'a changed default alone is named as that, and only that';
}

# --- an add op that needs the rebuild, rendered on its own -------------------
#
# DBIO::SQLite::Diff never renders this op: it is only marked where the model
# has the statement, and there the table is rebuilt. Rendered alone it used to
# be a comment without a semicolon -- the form that IS dropped silently.

{
  my $tables = { item => {
    table_name => 'item',
    sql        => 'CREATE TABLE item (id INTEGER PRIMARY KEY, tag TEXT UNIQUE)',
  } };
  my ($op) = DBIO::SQLite::Diff::Column->diff(
    { item => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    { item => [
      { column_name => 'id',  data_type => 'INTEGER' },
      { column_name => 'tag', data_type => 'TEXT' },
    ] },
    $tables, $tables,
  );
  ok($op->action eq 'add' && $op->needs_rebuild, 'an added UNIQUE column needs the rebuild');

  throws_ok { $op->as_sql }
    qr/\ACannot add column item\.tag by ALTER TABLE: ADD COLUMN cannot carry its declaration \(UNIQUE, PRIMARY KEY, a table constraint naming the column or a non-constant DEFAULT\), table item has to be rebuilt from its CREATE TABLE statement at /,
    'as_sql refuses: table, column and the reason';
  unlike($@, qr/;/, 'with nothing in it a statement splitter would cut at');

  is($op->summary, '  +column: item.tag (TEXT)', 'summary still names the op');
}

# The same refusal for the fourth cause, a DEFAULT SQLite refuses on a
# populated table (karr k65): the message must name it, not leave the reader
# looking for a UNIQUE that is not there.

{
  my $tables = { item => {
    table_name => 'item',
    sql        => q{CREATE TABLE item (id INTEGER PRIMARY KEY, seen TEXT DEFAULT (datetime('now')))},
  } };
  my ($op) = DBIO::SQLite::Diff::Column->diff(
    { item => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    { item => [
      { column_name => 'id',   data_type => 'INTEGER' },
      { column_name => 'seen', data_type => 'TEXT' },
    ] },
    $tables, $tables,
  );
  ok($op->action eq 'add' && $op->needs_rebuild, 'an added non-constant DEFAULT column needs the rebuild');

  throws_ok { $op->as_sql }
    qr/\ACannot add column item\.seen by ALTER TABLE: .*a non-constant DEFAULT\), table item has to be rebuilt/,
    'as_sql names the non-constant DEFAULT among the reasons';
}

# --- the whole diff, and Deploy->apply ---------------------------------------
#
# The refused change sits beside one that could run: a table new in the target.
# The diff reports both, renders neither, and apply leaves the database as it
# found it.

{
  package RefuseTest::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package RefuseTest::V1::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_nullable => 0 },
    val => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
RefuseTest::V1->register_class(Item => 'RefuseTest::V1::Result::Item');

{
  package RefuseTest::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package RefuseTest::V2::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_nullable => 0 },
    val => { data_type => 'integer', is_nullable => 0 },   # now NOT NULL
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package RefuseTest::V2::Result::Added;
  use base 'DBIO::Core';
  __PACKAGE__->table('added');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
RefuseTest::V2->register_class(Item  => 'RefuseTest::V2::Result::Item');
RefuseTest::V2->register_class(Added => 'RefuseTest::V2::Result::Added');

{
  my $schema = RefuseTest::V1->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  my $deploy = DBIO::SQLite::Deploy->new(schema => $schema);
  $deploy->install;
  $schema->resultset('Item')->create({ id => 1, val => undef });

  my $dbh    = $schema->storage->dbh;
  my $tables = sub {
    $dbh->selectcol_arrayref(
      q{SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name},
    );
  };
  my $before = $tables->();
  my $item   = $dbh->selectrow_array(
    q{SELECT sql FROM sqlite_master WHERE name = 'item'},
  );

  my $diff = DBIO::SQLite::Diff->new(
    source => DBIO::SQLite::Introspect->new(dbh => $dbh)->model,
    target => DBIO::SQLite::Diff->target_from_compiled(
      DBIO::Schema::ModelCompiler->new(adapter => DBIO::SQLite::Adapter->new)
        ->compile('RefuseTest::V2'),
    ),
  );

  # What is in the diff -- so that the refusal below is known to come with a
  # statement that could have run, and to be about the one column.
  is_deeply(
    [ map { join ' ', ref $_, $_->action, $_->table_name } @{ $diff->operations } ],
    [
      'DBIO::SQLite::Diff::Table create added',
      'DBIO::SQLite::Diff::Column alter item',
    ],
    'the diff holds a table it can create and a column change it cannot make',
  );

  ok($diff->has_changes, 'has_changes is true');

  my $summary;
  lives_ok { $summary = $diff->summary } 'summary lives';
  like($summary, qr/^\+ table: added$/m,  'and lists the new table');
  like($summary, qr/^\s*~column: item\.val \(/m,     'and the column it cannot change');

  my $refusal = qr/Cannot change column item\.val \(NOT NULL no -> yes\): SQLite has no ALTER COLUMN, and the target model holds no CREATE TABLE statement to rebuild table item from/;

  throws_ok { $diff->as_sql } $refusal, 'as_sql of the diff dies with the refusal';

  throws_ok { $deploy->apply($diff) } $refusal,
    'apply dies with the refusal -- table, column, change, reason';

  is_deeply($tables->(), $before,
    'and nothing was applied: the table the diff could have created is not there');
  is(
    scalar $dbh->selectrow_array(q{SELECT sql FROM sqlite_master WHERE name = 'item'}),
    $item,
    'the table with the refused change is as it was',
  );
}

done_testing;
