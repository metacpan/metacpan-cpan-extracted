use strict;
use warnings;
use Test::More;

use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Column;
use DBIO::SQL::Util ();

# OFFLINE (karr k42, ADR 0008). Some ALTER TABLE statements of the column pass
# leave a Db2 table in reorg-pending state: every INSERT, UPDATE and CREATE INDEX
# on it then fails with SQL0668N rc 7 until a REORG has run. The diff emitted
# those statements and never the REORG, so an upgrade that dropped a column and
# created an index on the same table stopped at the index, half applied, and the
# table took no row afterwards.
#
# What this file claims:
#
#   * the diff carries the REORG as an operation of its own -- visible in
#     ->operations, ->as_sql and ->summary before anything is applied;
#   * exactly one per table, however many of its column statements ask for it,
#     after the last column operation and before the first index operation, so
#     the index and foreign key passes find a usable table;
#   * which column operations ask for it is what was measured on Db2 12.1.5
#     (the table in ADR 0008), not a guess: DROP COLUMN, SET/DROP NOT NULL and
#     a SET DATA TYPE do, apart from a mere change of length within VARCHAR,
#     VARGRAPHIC or VARBINARY; ADD COLUMN and SET/DROP DEFAULT do not.
#
# The models are in the catalog shape DBIO::DB2::Introspect::Columns returns --
# catalog_type is TYPENAME (CHARACTER, DOUBLE), catalog_size is LENGTH -- because that is
# what both sides of a real diff are (karr k41).

my $REORG = 'DBIO::DB2::Diff::Reorg';

sub col {
  my ($name, $type, $size, %rest) = @_;
  return { column_name => $name, catalog_type => $type, catalog_size => $size,
           not_null => 0, %rest };
}

my $ID = col(id => 'INTEGER', 4, not_null => 1, is_pk => 1, pk_position => 1);

# A model of plain tables: name => [ columns ], and optionally the indexes.
sub model {
  my ($columns, $indexes) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, kind => 'table' } } keys %$columns },
    columns      => $columns,
    indexes      => $indexes // {},
    foreign_keys => {},
  };
}

sub ops_of {
  my ($source, $target) = @_;
  return @{ DBIO::DB2::Diff->new(source => $source, target => $target)->operations };
}

# One line per operation: what it is and on which table.
sub shape {
  return [ map {
    my $kind = ref $_; $kind =~ s/^DBIO::DB2::Diff:://;
    join ' ', $kind, $_->action, $_->table_name;
  } @_ ];
}

# ============================================================================
# 1. Where the operation stands, and how many there are.
#    "a": two statements that ask for a REORG (a dropped column, a changed
#         type) and a new index -- the shape of the failure on the card.
#    "b": an added column and a new index -- no REORG.
#    "c": a column that becomes NOT NULL -- a REORG, and no index.
# ============================================================================
{
  my $source = model({
    a => [ $ID, col(legacy => 'VARCHAR', 10), col(qty => 'INTEGER', 4), col(name => 'VARCHAR', 40) ],
    b => [ $ID ],
    c => [ $ID, col(label => 'VARCHAR', 20) ],
  });
  my $target = model({
    a => [ $ID, col(qty => 'BIGINT', 8), col(name => 'VARCHAR', 40) ],
    b => [ $ID, col(note => 'VARCHAR', 20) ],
    c => [ $ID, col(label => 'VARCHAR', 20, not_null => 1) ],
  }, {
    a => { idx_a_name => { index_name => 'idx_a_name', columns => ['name'] } },
    b => { idx_b_note => { index_name => 'idx_b_note', columns => ['note'] } },
  });

  my @ops = ops_of($source, $target);

  is_deeply shape(@ops), [
    'Column alter a',
    'Column drop a',
    'Column add b',
    'Column alter c',
    'Reorg reorg a',
    'Reorg reorg c',
    'Index create a',
    'Index create b',
  ], 'one REORG per table that needs one, after the column pass and before the index pass';

  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  my @sql  = DBIO::SQL::Util::_split_statements($diff->as_sql);

  is_deeply \@sql, [
    'ALTER TABLE "a" ALTER COLUMN "qty" SET DATA TYPE BIGINT',
    'ALTER TABLE "a" DROP COLUMN "legacy"',
    'ALTER TABLE "b" ADD COLUMN "note" VARCHAR(20)',
    'ALTER TABLE "c" ALTER COLUMN "label" SET NOT NULL',
    q{CALL SYSPROC.ADMIN_CMD('REORG TABLE "a"')},
    q{CALL SYSPROC.ADMIN_CMD('REORG TABLE "c"')},
    'CREATE INDEX "idx_a_name" ON "a" ("name")',
    'CREATE INDEX "idx_b_note" ON "b" ("note")',
  ], 'the statements apply() runs, in order: each REORG is one statement of its own, '
   . 'standing before the CREATE INDEX on its table';

  like $diff->summary, qr/^  ~reorg: a$/m, 'summary names the REORG of a';
  like $diff->summary, qr/^  ~reorg: c$/m, '... and of c';
  unlike $diff->summary, qr/reorg: b/,     '... and none for b';
}

# ============================================================================
# 2. The statement. The table name goes in as a quoted identifier, unqualified
#    like the ALTER TABLE statements beside it (ADMIN_CMD resolves it against
#    CURRENT SCHEMA, as they are), inside a string literal -- so a " in the name
#    is doubled for the identifier and a ' for the literal.
# ============================================================================
{
  my $odd = q{dbio k42'q "1};
  my @ops = ops_of(
    model({ $odd => [ $ID, col(gone => 'INTEGER', 4) ] }),
    model({ $odd => [ $ID ] }),
  );
  my ($reorg) = grep { $_->isa($REORG) } @ops;

  ok $reorg, 'a dropped column on an oddly named table gets its REORG';
  is $reorg && $reorg->as_sql,
    q{CALL SYSPROC.ADMIN_CMD('REORG TABLE "dbio k42''q ""1"');},
    'identifier quoted, " doubled in it and \' doubled for the string literal';
  is $reorg && $reorg->table_name, $odd, 'table_name is the name as the model has it';
  is $reorg && $reorg->action, 'reorg',  'action is reorg';

  is_deeply [ DBIO::SQL::Util::_split_statements($reorg ? $reorg->as_sql : '') ],
    [ q{CALL SYSPROC.ADMIN_CMD('REORG TABLE "dbio k42''q ""1"')} ],
    'core splits it into the one statement it is';
}

# ============================================================================
# 3. Which column operations ask for a REORG. One column "c" per case, changed
#    from the first definition to the second; the answer is the column
#    operation's own (reorg_recommended) and, through the orchestrator, whether
#    the diff carries a REORG at all. Each line is a row of the measurement in
#    ADR 0008.
# ============================================================================
my @CASES = (
  # name, live column (undef: absent), target column (undef: absent), REORG?
  [ 'DROP COLUMN',                  [ 'INTEGER', 4 ],       undef,                         1 ],
  [ 'ADD COLUMN',                   undef,                  [ 'INTEGER', 4 ],              0 ],
  [ 'ADD COLUMN NOT NULL DEFAULT',  undef,                  [ 'INTEGER', 4, not_null => 1, catalog_default => '0' ], 0 ],
  [ 'SET NOT NULL',                 [ 'INTEGER', 4 ],       [ 'INTEGER', 4, not_null => 1 ], 1 ],
  [ 'DROP NOT NULL',                [ 'INTEGER', 4, not_null => 1 ], [ 'INTEGER', 4 ],     1 ],
  [ 'SET DEFAULT',                  [ 'VARCHAR', 20 ],      [ 'VARCHAR', 20, catalog_default => q{'new'} ], 0 ],
  [ 'changed DEFAULT',              [ 'VARCHAR', 20, catalog_default => q{'old'} ], [ 'VARCHAR', 20, catalog_default => q{'new'} ], 0 ],
  [ 'VARCHAR(20) -> VARCHAR(40)',   [ 'VARCHAR', 20 ],      [ 'VARCHAR', 40 ],             0 ],
  [ 'VARCHAR(50) -> VARCHAR(20)',   [ 'VARCHAR', 50 ],      [ 'VARCHAR', 20 ],             0 ],
  [ 'VARGRAPHIC(20) -> (40)',       [ 'VARGRAPHIC', 20 ],   [ 'VARGRAPHIC', 40 ],          0 ],
  [ 'VARBINARY(20) -> (40)',        [ 'VARBINARY', 20 ],    [ 'VARBINARY', 40 ],           0 ],
  [ 'VARCHAR longer, and a DEFAULT', [ 'VARCHAR', 20 ],     [ 'VARCHAR', 40, catalog_default => q{'new'} ], 0 ],
  [ 'VARCHAR longer, and NOT NULL', [ 'VARCHAR', 20 ],      [ 'VARCHAR', 40, not_null => 1 ], 1 ],
  [ 'CHAR(10) -> CHAR(20)',         [ 'CHARACTER', 10 ],    [ 'CHARACTER', 20 ],           1 ],
  [ 'CHAR(10) -> VARCHAR(20)',      [ 'CHARACTER', 10 ],    [ 'VARCHAR', 20 ],             1 ],
  [ 'VARCHAR(20) -> CHAR(20)',      [ 'VARCHAR', 20 ],      [ 'CHARACTER', 20 ],           1 ],
  [ 'VARCHAR(20) -> VARGRAPHIC(20)', [ 'VARCHAR', 20 ],     [ 'VARGRAPHIC', 20 ],          1 ],
  [ 'SMALLINT -> INTEGER',          [ 'SMALLINT', 2 ],      [ 'INTEGER', 4 ],              1 ],
  [ 'INTEGER -> BIGINT',            [ 'INTEGER', 4 ],       [ 'BIGINT', 8 ],               1 ],
  [ 'BIGINT -> INTEGER',            [ 'BIGINT', 8 ],        [ 'INTEGER', 4 ],              1 ],
  [ 'DECIMAL(10,2) -> (12,2)',      [ 'DECIMAL', '10,2' ],  [ 'DECIMAL', '12,2' ],         1 ],
  [ 'DECIMAL(12,2) -> (10,2)',      [ 'DECIMAL', '12,2' ],  [ 'DECIMAL', '10,2' ],         1 ],
  [ 'REAL -> DOUBLE',               [ 'REAL', 4 ],          [ 'DOUBLE', 8 ],               1 ],
  [ 'DATE -> TIMESTAMP',            [ 'DATE', 4 ],          [ 'TIMESTAMP', 6 ],            1 ],
  [ 'TIMESTAMP(6) -> (12)',         [ 'TIMESTAMP', 6 ],     [ 'TIMESTAMP', 12 ],           1 ],
  [ 'INTEGER -> VARCHAR(20)',       [ 'INTEGER', 4 ],       [ 'VARCHAR', 20 ],             1 ],
  [ 'INTEGER -> DOUBLE',            [ 'INTEGER', 4 ],       [ 'DOUBLE', 8 ],               1 ],
  # Not measured, and so answered with a REORG: one too many costs time, one
  # too few breaks the upgrade.
  [ 'a type nobody measured, longer', [ 'LONG VARCHAR', 100 ], [ 'LONG VARCHAR', 200 ],    1 ],
);

for my $case (@CASES) {
  my ($name, $live, $want, $expect) = @$case;

  my @ops = ops_of(
    model({ t => [ $ID, ($live ? col(c => @$live) : ()) ] }),
    model({ t => [ $ID, ($want ? col(c => @$want) : ()) ] }),
  );
  my @column = grep { $_->isa('DBIO::DB2::Diff::Column') } @ops;
  my @reorg  = grep { $_->isa($REORG) } @ops;

  is scalar(@column), 1, "$name: one column operation";
  is $column[0] && ($column[0]->reorg_recommended ? 1 : 0), $expect,
    "$name: the column operation " . ($expect ? 'asks for a REORG' : 'asks for none');
  is scalar(@reorg), $expect,
    "$name: the diff carries " . ($expect ? 'one REORG' : 'no REORG')
    or diag join "\n", map { $_->as_sql } @ops;
}

# ============================================================================
# 4. A diff without a column operation that asks for one says nothing about a
#    REORG -- not for a new table, not for a dropped one, not for an index.
# ============================================================================
{
  my $diff = DBIO::DB2::Diff->new(
    source => model({ gone => [ $ID ], kept => [ $ID, col(name => 'VARCHAR', 20) ] }),
    target => model(
      { fresh => [ $ID ], kept => [ $ID, col(name => 'VARCHAR', 40) ] },
      { kept => { idx_kept_name => { index_name => 'idx_kept_name', columns => ['name'] } } },
    ),
  );

  is_deeply shape(@{ $diff->operations }), [
    'Table create fresh',
    'Table drop gone',
    'Column alter kept',
    'Index create kept',
  ], 'create, drop, a longer VARCHAR and an index: no REORG operation';
  unlike $diff->as_sql, qr/REORG/i, '... and none in the SQL';
}

done_testing;
