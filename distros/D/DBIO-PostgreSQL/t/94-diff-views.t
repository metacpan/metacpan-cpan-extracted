use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Table;
use DBIO::PostgreSQL::Diff::View;

# karr k100 -- a relation is created and dropped as what it is.
#
# WHY it exists: the model files every relation under "tables" -- the table,
# the view, the materialized view, the foreign table, the partitioned table --
# and the diff read all of them as tables. A view the target has came out as
# CREATE TABLE v (id integer, a integer): a table of that name, empty, where
# the application reads a view. A view that went came out as DROP TABLE v
# CASCADE, which the server refuses ('"v" is not a table'). A view whose
# definition changed was not noticed at all as long as its columns stayed, and
# got ALTER TABLE v ADD COLUMN when they did not. A foreign table and a
# partitioned table were created as ordinary tables as well -- no server, no
# partitioning, and nothing that said so.
#
# What is held here, without a database (t/96 holds it against a server):
#
#  1. a view is created as a view from the definition the catalog gives, and
#     dropped as a view; a materialized view likewise;
#  2. a view has no column operations;
#  3. a changed definition is a DROP VIEW and a CREATE VIEW, together and ahead
#     of the removals, and so is every view that stands on the changed one;
#  4. views come after the tables and columns they stand on and go before
#     them, and among themselves in the order of the dependency the model
#     carries, not of their names;
#  5. what the diff cannot do without loss or without guessing it refuses:
#     a changed materialized view, a relation that changes its kind, a foreign
#     or partitioned table or a partition to create.

sub relation {
  my ($kind, $schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, table_name => $name, kind => $kind, %more });
}
sub table { relation(r => @_) }
sub view {
  my ($schema, $name, $definition, @depends_on) = @_;
  return relation(v => $schema, $name,
    view_definition => $definition, depends_on => [@depends_on]);
}
sub matview {
  my ($schema, $name, $definition, @depends_on) = @_;
  return relation(m => $schema, $name,
    view_definition => $definition, depends_on => [@depends_on]);
}
sub columns { [ map { { column_name => $_, data_type => 'integer' } } @_ ] }

sub statements {
  my ($diff) = @_;
  return [ map { $_->as_sql } @{ $diff->operations } ];
}
sub op_kinds {
  my ($diff) = @_;
  return [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ $diff->operations } ];
}
sub diff_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}

# pg_get_viewdef hands the definition back with a leading blank, over several
# lines and with a closing semicolon.
my $V_DEF = " SELECT id,\n    a\n   FROM t\n  WHERE (a > 0);";

my %base = (
  tables  => { table(public => 't') },
  columns => { 'public.t' => columns(qw( id a )) },
);

# ---------------------------------------------------------------------------
# 1. Created and dropped as what it is
# ---------------------------------------------------------------------------
{
  my %with_view = (
    tables  => { table(public => 't'), view(public => 'v', $V_DEF, 'public.t') },
    columns => { 'public.t' => columns(qw( id a )), 'public.v' => columns(qw( id a )) },
  );

  my $create = diff_of(\%base, \%with_view);
  is_deeply(statements($create),
    [ "CREATE VIEW public.v AS SELECT id,\n    a\n   FROM t\n  WHERE (a > 0);" ],
    'a view the target has is created as a view, from the definition of the catalog');
  unlike($create->as_sql, qr/CREATE TABLE/, 'and not as a table');
  like($create->summary, qr/^\s*\+view: public\.v\z/, 'the summary calls it a view');

  my $drop = diff_of(\%with_view, \%base);
  is_deeply(statements($drop), [ 'DROP VIEW public.v;' ],
    'a view the target does not have is dropped as a view');
  like($drop->summary, qr/^\s*-view: public\.v\z/, 'and the summary says so');

  ok(!diff_of(\%with_view, \%with_view)->has_changes,
    'a view that is the same on both sides is no change');
}

{
  my %with_mv = (
    tables  => { table(public => 't'), matview(public => 'mv', ' SELECT id FROM t;', 'public.t') },
    columns => { 'public.t' => columns(qw( id a )), 'public.mv' => columns(qw( id )) },
    indexes => { 'public.mv' => { mv_idx => {
      schema_name => 'public', table_name => 'mv', index_name => 'mv_idx',
      definition  => 'CREATE INDEX mv_idx ON public.mv USING btree (id)',
    } } },
  );

  my $create = diff_of(\%base, \%with_mv);
  is_deeply(statements($create), [
    'CREATE MATERIALIZED VIEW public.mv AS SELECT id FROM t;',
    'CREATE INDEX mv_idx ON public.mv USING btree (id);',
  ], 'a materialized view is created as one, and its index after it');
  like($create->summary, qr/^\s*\+materialized view: public\.mv$/m, 'the summary calls it a materialized view');

  my $drop = diff_of(\%with_mv, \%base);
  is_deeply(statements($drop), [ 'DROP MATERIALIZED VIEW public.mv;' ],
    'and dropped as one -- its index goes with it and gets no statement of its own');
}

# A name that needs quotes, in a schema that needs them (karr k110).
{
  my $diff = diff_of(
    { tables => {} },
    { tables => { view('App.Data' => 'Order', ' SELECT 1 AS one;') } },
  );
  is_deeply(statements($diff), [ 'CREATE VIEW "App.Data"."Order" AS SELECT 1 AS one;' ],
    'schema and view are identifiers by the rule of the server');
  is_deeply(statements(diff_of({ tables => { view('App.Data' => 'Order', ' SELECT 1 AS one;') } }, { tables => {} })),
    [ 'DROP VIEW "App.Data"."Order";' ], 'in the DROP as well');
}

# ---------------------------------------------------------------------------
# 2. A view has no column operations
# ---------------------------------------------------------------------------
{
  my %before = (
    tables  => { table(public => 't'), view(public => 'v', ' SELECT id FROM t;', 'public.t') },
    columns => { 'public.t' => columns(qw( id a )), 'public.v' => columns(qw( id )) },
  );
  my %after = (
    tables  => { table(public => 't'), view(public => 'v', ' SELECT id, a FROM t;', 'public.t') },
    columns => { 'public.t' => columns(qw( id a )), 'public.v' => columns(qw( id a )) },
  );
  my $diff = diff_of(\%before, \%after);
  unlike($diff->as_sql, qr/ALTER TABLE/,
    'a view with another column gets no ALTER TABLE ... ADD COLUMN');
  is_deeply(op_kinds($diff), [ 'View drop', 'View create' ],
    'it is a changed view: dropped and created again');
}

# ---------------------------------------------------------------------------
# 3. A changed definition
# ---------------------------------------------------------------------------
{
  my $model = sub {
    my ($definition) = @_;
    return {
      tables  => { table(public => 't'), view(public => 'v', $definition, 'public.t') },
      # the columns of the view are the same on both sides: only the
      # definition says that anything changed
      columns => { 'public.t' => columns(qw( id a )), 'public.v' => columns(qw( id a )) },
    };
  };
  my $diff = diff_of($model->(' SELECT id, a FROM t;'), $model->(' SELECT id, a FROM t WHERE (a > 0);'));

  is_deeply(statements($diff), [
    'DROP VIEW public.v;',
    'CREATE VIEW public.v AS SELECT id, a FROM t WHERE (a > 0);',
  ], 'a changed definition under unchanged columns is a DROP VIEW and a CREATE VIEW');
  ok(eval { $diff->operations->[0]->replaced },
    'the drop says the view is replaced, so it stays ahead of its create')
    or diag $@;

  ok(!diff_of($model->(" SELECT id, a FROM t;"), $model->("SELECT id, a FROM t"))->has_changes,
    'the blank ahead of a definition and the semicolon after it are no change');
}

# The pair stays ahead of the removals: the column the old definition used is
# dropped once the view no longer stands on it.
{
  my $diff = diff_of(
    {
      tables  => { table(public => 't'), view(public => 'v', ' SELECT id, old FROM t;', 'public.t') },
      columns => { 'public.t' => columns(qw( id old )), 'public.v' => columns(qw( id old )) },
    },
    {
      tables  => { table(public => 't'), view(public => 'v', ' SELECT id, fresh FROM t;', 'public.t') },
      columns => { 'public.t' => columns(qw( id fresh )), 'public.v' => columns(qw( id fresh )) },
    },
  );
  # The drop of a view that is created again stands ahead of every change to
  # a table (karr k120): it is what lets a column change its type under it.
  is_deeply(statements($diff), [
    'DROP VIEW public.v;',
    'ALTER TABLE public.t ADD COLUMN fresh integer;',
    'CREATE VIEW public.v AS SELECT id, fresh FROM t;',
    'ALTER TABLE public.t DROP COLUMN old;',
  ], 'the old view goes, the new column comes, the view on it, then the column the old view stood on');
}

# What stands on a changed view goes and comes with it. PostgreSQL does not
# drop a view another one depends on, so "top" -- the same on both sides --
# has to be out of the way, and "gone" -- which the target does not have --
# cannot wait for the removals.
{
  my %tables = ( table(public => 't') );
  my $source = { tables => {
    %tables,
    view(public => 'mid',  ' SELECT id FROM t;',          'public.t'),
    view(public => 'a_top', ' SELECT id FROM mid;',       'public.mid'),
    view(public => 'gone', ' SELECT id FROM a_top;',      'public.a_top'),
    view(public => 'aside', ' SELECT a FROM t;',          'public.t'),
  } };
  my $target = { tables => {
    %tables,
    view(public => 'mid',  ' SELECT id FROM t WHERE (id > 0);', 'public.t'),
    view(public => 'a_top', ' SELECT id FROM mid;',             'public.mid'),
    view(public => 'aside', ' SELECT a FROM t;',                'public.t'),
  } };
  my $diff = diff_of($source, $target);

  is_deeply(statements($diff), [
    'DROP VIEW public.gone;',
    'DROP VIEW public.a_top;',
    'DROP VIEW public.mid;',
    'CREATE VIEW public.mid AS SELECT id FROM t WHERE (id > 0);',
    'CREATE VIEW public.a_top AS SELECT id FROM mid;',
  ], 'the views on a changed view are dropped ahead of it and created again after it; one that is on neither is left alone');

  is_deeply(
    [ sort keys %{ DBIO::PostgreSQL::Diff::View->rebuilt($source->{tables}, $target->{tables}) } ],
    [ 'public.a_top', 'public.gone', 'public.mid' ],
    'rebuilt names the changed view and everything that stands on it');
}

# A trigger on a view that is dropped and created again goes with the DROP
# VIEW. It is the same on both sides, and has to be created again all the
# same; one the target no longer has needs no DROP of its own.
{
  my $trigger = sub {
    my ($name) = @_;
    return ($name => {
      schema_name => 'public', table_name => 'v', trigger_name => $name,
      definition  => "CREATE TRIGGER $name INSTEAD OF INSERT ON public.v FOR EACH ROW EXECUTE FUNCTION f()",
    });
  };
  my $diff = diff_of(
    {
      tables   => { table(public => 't'), view(public => 'v', ' SELECT id FROM t;', 'public.t') },
      triggers => { 'public.v' => { $trigger->('stays'), $trigger->('goes') } },
    },
    {
      tables   => { table(public => 't'), view(public => 'v', ' SELECT id, a FROM t;', 'public.t') },
      triggers => { 'public.v' => { $trigger->('stays') } },
    },
  );
  is_deeply(statements($diff), [
    'DROP VIEW public.v;',
    'CREATE VIEW public.v AS SELECT id, a FROM t;',
    'CREATE TRIGGER stays INSTEAD OF INSERT ON public.v FOR EACH ROW EXECUTE FUNCTION f();',
  ], 'the trigger of a view that is created again is created again with it');
}

# ---------------------------------------------------------------------------
# 4. Order
# ---------------------------------------------------------------------------

# By name, "a_last" would be created first and dropped last. It stands on
# "z_first".
{
  my %views = (
    tables  => {
      table(public => 't'),
      view(public => 'a_last',  ' SELECT id FROM z_first;', 'public.z_first'),
      view(public => 'z_first', ' SELECT id FROM t;',       'public.t'),
    },
    columns => { 'public.t' => columns(qw( id )) },
  );
  my %nothing = ( tables => {}, columns => {} );

  is_deeply(statements(diff_of(\%nothing, \%views)), [
    'CREATE TABLE public.t (id integer);',
    'CREATE VIEW public.z_first AS SELECT id FROM t;',
    'CREATE VIEW public.a_last AS SELECT id FROM z_first;',
  ], 'the table, then the view on it, then the view on that view');

  is_deeply(statements(diff_of(\%views, \%nothing)), [
    'DROP VIEW public.a_last;',
    'DROP VIEW public.z_first;',
    'DROP TABLE public.t;',
  ], 'and back in the reverse order: a view is dropped before what it stands on');
}

# A view on a column that is new on a table that is not.
{
  my $diff = diff_of(
    { %base },
    {
      tables  => { table(public => 't'), view(public => 'v', ' SELECT b FROM t;', 'public.t') },
      columns => { 'public.t' => columns(qw( id a b )), 'public.v' => columns(qw( b )) },
    },
  );
  is_deeply(statements($diff), [
    'ALTER TABLE public.t ADD COLUMN b integer;',
    'CREATE VIEW public.v AS SELECT b FROM t;',
  ], 'a view is created after the new column of an existing table it reads');
}

# ---------------------------------------------------------------------------
# 5. Refused
# ---------------------------------------------------------------------------

# A changed materialized view. Dropping and creating it again builds its data
# anew and takes its indexes.
{
  my $model = sub { { tables => { table(public => 't'), matview(public => 'mv', $_[0], 'public.t') } } };
  my $diff = diff_of($model->(' SELECT id FROM t;'), $model->(' SELECT id, a FROM t;'));
  throws_ok { $diff->operations }
    qr/\Arefusing to diff: materialized view public\.mv has another definition in the target/,
    'a changed materialized view is refused, by name';
  like($@, qr/DROP MATERIALIZED VIEW public\.mv;/, 'the refusal says what the user can do');
  like($@, qr/No statement was generated/, 'and that nothing was generated');
}

# A materialized view that stays, on a view that changes: it would have to go
# with the view.
{
  my $model = sub {
    return { tables => {
      table(public => 't'),
      view(public => 'v', $_[0], 'public.t'),
      matview(public => 'mv', ' SELECT id FROM v;', 'public.v'),
    } };
  };
  throws_ok { diff_of($model->(' SELECT id FROM t;'), $model->(' SELECT id FROM t WHERE (id > 0);'))->operations }
    qr/\Arefusing to diff: materialized view public\.mv stands on view public\.v, which changes/,
    'a materialized view on a changed view is refused, naming both';

  # One that goes anyway is no obstacle: it is dropped ahead of the view.
  my $target = $model->(' SELECT id FROM t WHERE (id > 0);');
  delete $target->{tables}{'public.mv'};
  is_deeply(statements(diff_of($model->(' SELECT id FROM t;'), $target)), [
    'DROP MATERIALIZED VIEW public.mv;',
    'DROP VIEW public.v;',
    'CREATE VIEW public.v AS SELECT id FROM t WHERE (id > 0);',
  ], 'a materialized view the target does not have is dropped ahead of the view it stood on');
}

# A relation that is another kind of relation in the target.
for my $case (
  [ 'table',             'view',              { table(public => 'x') }, { view(public => 'x', ' SELECT 1;') } ],
  [ 'view',              'table',             { view(public => 'x', ' SELECT 1;') }, { table(public => 'x') } ],
  [ 'view',              'materialized view', { view(public => 'x', ' SELECT 1;') }, { matview(public => 'x', ' SELECT 1;') } ],
  [ 'materialized view', 'table',             { matview(public => 'x', ' SELECT 1;') }, { table(public => 'x') } ],
) {
  my ($from, $to, $source, $target) = @$case;
  throws_ok { diff_of({ tables => $source }, { tables => $target })->operations }
    qr/\Arefusing to diff: public\.x is a \Q$from\E in the database and a \Q$to\E in the target/,
    "a $from that is a $to in the target is refused";
}

# A view to create without a definition to create it from.
throws_ok { diff_of({ tables => {} }, { tables => { relation(v => public => 'v') } })->operations }
  qr/\Arefusing to diff: view public\.v .* no definition/,
  'a view the target model has no definition for is refused';

# Relations the model does not hold enough of to create them.
{
  my %kinds = (
    'foreign table'     => { relation(f => public => 'x') },
    'partitioned table' => { relation(p => public => 'x') },
  );
  for my $kind (sort keys %kinds) {
    throws_ok { diff_of({ tables => {} }, { tables => $kinds{$kind}, columns => { 'public.x' => columns('id') } })->operations }
      qr/\Arefusing to diff: \Q$kind\E public\.x is in the target and not in the database/,
      "a $kind to create is refused";
    like($@, qr/CREATE TABLE public\.x \(id integer\)/,
      "... naming the ordinary table that would have come of it");
  }

  throws_ok {
    diff_of(
      { tables => { relation(p => public => 'm') } },
      { tables => { relation(p => public => 'm'), table(public => 'm_2026', partition_of => 'public.m') } },
    )->operations
  } qr/\Arefusing to diff: table public\.m_2026 is a partition of public\.m in the target and not in the database/,
    'a partition to create is refused, naming the table it is a partition of';
}

# Dropping them is what the diff can do.
{
  is_deeply(statements(diff_of({ tables => { relation(f => public => 'ft') } }, { tables => {} })),
    [ 'DROP FOREIGN TABLE public.ft;' ], 'a foreign table is dropped as a foreign table');

  # DROP TABLE on the partitioned table takes its partitions; a DROP TABLE for
  # one of them after it names a table that is gone.
  my %partitioned = (
    relation(p => public => 'm'),
    table(public => 'a_part', partition_of => 'public.m'),
    table(public => 'm_2026', partition_of => 'public.m'),
  );
  is_deeply(statements(diff_of({ tables => { %partitioned } }, { tables => {} })),
    [ 'DROP TABLE public.m;' ],
    'a partitioned table that goes takes its partitions: one DROP TABLE');

  my %kept = %partitioned;
  delete $kept{'public.a_part'};
  is_deeply(statements(diff_of({ tables => { %partitioned } }, { tables => { %kept } })),
    [ 'DROP TABLE public.a_part;' ],
    'a partition that goes while its table stays is dropped for itself');
}

done_testing;
