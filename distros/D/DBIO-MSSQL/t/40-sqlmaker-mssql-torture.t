use strict;
use warnings;
use Test::More;
use DBIO::Test ':DiffSQL';

# Offline test of the MSSQL LIMIT/OFFSET dialect. DBIO replaced the
# DBIx::Class sql_limit_dialect string dispatch with a single overridable
# apply_limit on the SQLMaker subclass; DBIO::MSSQL::SQLMaker targets the
# ROW_NUMBER() OVER() windowing dialect (SQL Server 2005+).

my $ROWS   = DBIO::SQLMaker::ClassicExtensions->__rows_bindtype;
my $OFFSET = DBIO::SQLMaker::ClassicExtensions->__offset_bindtype;
my $TOTAL  = DBIO::SQLMaker::ClassicExtensions->__total_bindtype;

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::MSSQL::Storage',
  no_deploy    => 1,
  quote_names  => 1,
);
# prime caches
$schema->storage->sql_maker;

# --- simple LIMIT, no order_by: RNO with the (SELECT(1)) default order ---
{
  my $rs = $schema->resultset('Artist')->search({}, { rows => 5 });

  is_same_sql_bind(
    $rs->as_query,
    q{(
      SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield] FROM (
        SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield],
               ROW_NUMBER() OVER( ORDER BY (SELECT(1)) ) AS [rno__row__index]
          FROM (
            SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
              FROM [artist] [me]
          ) [me]
      ) [me]
      WHERE [rno__row__index] >= ? AND [rno__row__index] <= ?
    )},
    [
      [ $OFFSET => 1 ],
      [ $TOTAL  => 5 ],
    ],
    'simple LIMIT uses ROW_NUMBER() OVER with default order',
  );
}

# --- ordered LIMIT + OFFSET (page): RNO with the real order, wrapped in a
#     TOP-max subselect by the storage ordered-subselect handling ---
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    {
      order_by            => 'me.artistid',
      rows                => 5,
      offset              => 10,
      unsafe_subselect_ok => 1,
    },
  );

  is_same_sql_bind(
    $rs->as_query,
    q{(
      SELECT TOP 2147483647 [me].[artistid], [me].[name], [me].[rank], [me].[charfield] FROM (
        SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield],
               ROW_NUMBER() OVER( ORDER BY [me].[artistid] ) AS [rno__row__index]
          FROM (
            SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
              FROM [artist] [me]
          ) [me]
      ) [me]
      WHERE [rno__row__index] >= ? AND [rno__row__index] <= ?
    )},
    [
      [ $OFFSET => 11 ],
      [ $TOTAL  => 15 ],
    ],
    'ordered LIMIT/OFFSET uses ROW_NUMBER() OVER with TOP wrapper, binds offset+1 / offset+rows',
  );
}

# --- ordered + limited used as a subselect without unsafe_subselect_ok:
#     the storage guard must refuse it (MSSQL ordered-subselect safety) ---
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    { order_by => 'me.artistid', rows => 5 },
  );

  eval { $rs->as_query };
  like(
    $@,
    qr/ordered subselect/i,
    'ordered limited subselect without unsafe_subselect_ok is refused',
  );
}

done_testing;
