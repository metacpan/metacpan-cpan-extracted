use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBIO::SQLite::Test; DBIO::SQLite::Test->import(':DiffSQL'); 1 }
    or plan skip_all => 'DBIO::SQLite::Test (from DBIO::SQLite) required for SQL comparison helpers';
}

# Offline test for the MSSQL RowNumberOver limit dialect. No live DB and no
# SQLite test infrastructure -- exercises DBIO::MSSQL::SQLMaker->apply_limit
# directly, which is what the storage invokes to slice result sets (MSSQL has
# no LIMIT/OFFSET keyword before 2012). DBIO replaced the DBIx::Class
# sql_limit_dialect string dispatch with a single overridable apply_limit on
# the SQLMaker subclass.

use_ok 'DBIO::MSSQL::SQLMaker';

my $OFFSET = DBIO::SQLMaker::ClassicExtensions->__offset_bindtype;
my $TOTAL  = DBIO::SQLMaker::ClassicExtensions->__total_bindtype;

# apply_limit pushes its slicing binds onto $maker->{limit_bind}; collect them
# the way the storage does, then assert SQL + binds together.
sub limit {
  my ($maker, $sql, $rs_attrs, $rows, $offset) = @_;
  local $maker->{limit_bind}  = [];
  local $maker->{select_bind} = [];
  my $out = $maker->apply_limit($sql, $rs_attrs, $rows, $offset);
  return ($out, [ @{ $maker->{limit_bind} } ]);
}

# --- quoted identifiers, rows + offset, no order_by --------------------------
# MSSQL overrides _rno_default_order to '(SELECT(1))' because it forbids an
# empty OVER() clause (core base returns undef -> empty OVER( )).
{
  my $maker = DBIO::MSSQL::SQLMaker->new(quote_char => ['[', ']'], name_sep => '.');

  my ($sql, $bind) = limit(
    $maker,
    q{SELECT [me].[id], [me].[name] FROM [artist] [me]},
    {
      alias         => 'me',
      _selector_sql => '[me].[id], [me].[name]',
      select        => ['me.id', 'me.name'],
      as            => ['id', 'name'],
    },
    10,
    5,
  );

  is_same_sql_bind(
    $sql,
    $bind,
    q{
      SELECT [me].[id], [me].[name] FROM (
        SELECT [me].[id], [me].[name],
               ROW_NUMBER() OVER( ORDER BY (SELECT(1)) ) AS [rno__row__index]
          FROM (
            SELECT [me].[id], [me].[name] FROM [artist] [me]
          ) [me]
      ) [me]
      WHERE [rno__row__index] >= ? AND [rno__row__index] <= ?
    },
    [
      [ $OFFSET => 6 ],     # offset + 1
      [ $TOTAL  => 15 ],    # offset + rows
    ],
    'quoted RNO: rows+offset, default (SELECT(1)) order, binds offset+1 / offset+rows',
  );

  like(
    $sql,
    qr/ROW_NUMBER\(\) \s OVER\( \s+ ORDER \s BY \s \Q(SELECT(1))\E \s \)/x,
    'default order is (SELECT(1)), not an empty OVER()',
  );
}

# --- quoted identifiers, rows only (offset 0) -> binds 1 / rows -------------
{
  my $maker = DBIO::MSSQL::SQLMaker->new(quote_char => ['[', ']'], name_sep => '.');

  my ($sql, $bind) = limit(
    $maker,
    q{SELECT [me].[id], [me].[name] FROM [artist] [me]},
    {
      alias         => 'me',
      _selector_sql => '[me].[id], [me].[name]',
      select        => ['me.id', 'me.name'],
      as            => ['id', 'name'],
    },
    10,
    0,
  );

  is_same_sql_bind(
    $sql,
    $bind,
    q{
      SELECT [me].[id], [me].[name] FROM (
        SELECT [me].[id], [me].[name],
               ROW_NUMBER() OVER( ORDER BY (SELECT(1)) ) AS [rno__row__index]
          FROM (
            SELECT [me].[id], [me].[name] FROM [artist] [me]
          ) [me]
      ) [me]
      WHERE [rno__row__index] >= ? AND [rno__row__index] <= ?
    },
    [
      [ $OFFSET => 1 ],     # offset + 1
      [ $TOTAL  => 10 ],    # offset + rows
    ],
    'quoted RNO: rows only (offset 0), binds 1 / rows',
  );
}

# --- quoted identifiers, explicit order_by -> real ORDER BY in OVER() --------
{
  my $maker = DBIO::MSSQL::SQLMaker->new(quote_char => ['[', ']'], name_sep => '.');

  my ($sql, $bind) = limit(
    $maker,
    q{SELECT [me].[id], [me].[name] FROM [artist] [me]},
    {
      alias         => 'me',
      _selector_sql => '[me].[id], [me].[name]',
      select        => ['me.id', 'me.name'],
      as            => ['id', 'name'],
      order_by      => 'me.name',
    },
    10,
    5,
  );

  is_same_sql_bind(
    $sql,
    $bind,
    q{
      SELECT [me].[id], [me].[name] FROM (
        SELECT [me].[id], [me].[name],
               ROW_NUMBER() OVER( ORDER BY [me].[name] ) AS [rno__row__index]
          FROM (
            SELECT [me].[id], [me].[name] FROM [artist] [me]
          ) [me]
      ) [me]
      WHERE [rno__row__index] >= ? AND [rno__row__index] <= ?
    },
    [
      [ $OFFSET => 6 ],
      [ $TOTAL  => 15 ],
    ],
    'quoted RNO: explicit order_by lands in OVER( ORDER BY ... )',
  );
}

# --- unquoted identifiers ----------------------------------------------------
{
  my $maker = DBIO::MSSQL::SQLMaker->new(quote_char => '', name_sep => '.');

  my ($sql, $bind) = limit(
    $maker,
    q{SELECT me.id, me.name FROM artist me},
    {
      alias         => 'me',
      _selector_sql => 'me.id, me.name',
      select        => ['me.id', 'me.name'],
      as            => ['id', 'name'],
    },
    3,
    0,
  );

  is_same_sql_bind(
    $sql,
    $bind,
    q{
      SELECT me.id, me.name FROM (
        SELECT me.id, me.name,
               ROW_NUMBER() OVER( ORDER BY (SELECT(1)) ) AS rno__row__index
          FROM (
            SELECT me.id, me.name FROM artist me
          ) me
      ) me
      WHERE rno__row__index >= ? AND rno__row__index <= ?
    },
    [
      [ $OFFSET => 1 ],
      [ $TOTAL  => 3 ],
    ],
    'unquoted RNO: bare identifiers, default order, binds 1 / rows',
  );
}

# --- the storage wires this SQLMaker as its sql_maker_class ------------------
use_ok 'DBIO::MSSQL::Storage';
is(
  DBIO::MSSQL::Storage->sql_maker_class,
  'DBIO::MSSQL::SQLMaker',
  'Storage uses DBIO::MSSQL::SQLMaker',
);

done_testing;
