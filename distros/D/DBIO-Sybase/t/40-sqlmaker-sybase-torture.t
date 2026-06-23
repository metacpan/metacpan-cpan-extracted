use strict;
use warnings;
use Test::More;
use DBIO::Test ':DiffSQL';

# Offline test of the Sybase ASE LIMIT/OFFSET dialect. DBIO replaced the
# DBIx::Class sql_limit_dialect string dispatch with a single overridable
# apply_limit on the SQLMaker subclass; DBIO::Sybase::SQLMaker targets the
# GenericSubQ dialect (a correlated COUNT(*) subquery against a stable,
# main-table order). ASE has no native LIMIT/OFFSET and no single
# windowing/TOP construct that works reliably for all query shapes across
# server versions -- this is the same dialect DBIx::Class used for ASE.

my $ROWS   = DBIO::SQLMaker::ClassicExtensions->__rows_bindtype;
my $OFFSET = DBIO::SQLMaker::ClassicExtensions->__offset_bindtype;
my $TOTAL  = DBIO::SQLMaker::ClassicExtensions->__total_bindtype;

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::Sybase::Storage::ASE',
  no_deploy    => 1,
  quote_names  => 1,
);
# prime caches
$schema->storage->sql_maker;

is(
  ref $schema->storage->sql_maker,
  'DBIO::Sybase::SQLMaker',
  'ASE storage wires up DBIO::Sybase::SQLMaker',
);

# --- ordered LIMIT only: GenericSubQ slices with COUNT(*) < ? ---
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    { order_by => 'me.artistid', rows => 3 },
  );

  is_same_sql_bind(
    $rs->as_query,
    q{(
      SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
        FROM (
          SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
            FROM [artist] [me]
        ) [me]
      WHERE ( SELECT COUNT(*) FROM [artist] [rownum__emulation]
              WHERE ( [rownum__emulation].[artistid] < [me].[artistid] ) ) < ?
      ORDER BY [me].[artistid] ASC
    )},
    [
      [ $ROWS => 3 ],
    ],
    'ordered LIMIT uses GenericSubQ correlated COUNT(*) subquery, no LIMIT/OFFSET',
  );
}

# --- ordered LIMIT + OFFSET (page): GenericSubQ slices with COUNT(*)
#     BETWEEN ? AND ?, binds offset / offset+rows-1 ---
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    { order_by => 'me.artistid', rows => 3, offset => 3 },
  );

  is_same_sql_bind(
    $rs->as_query,
    q{(
      SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
        FROM (
          SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]
            FROM [artist] [me]
        ) [me]
      WHERE ( SELECT COUNT(*) FROM [artist] [rownum__emulation]
              WHERE ( [rownum__emulation].[artistid] < [me].[artistid] ) ) BETWEEN ? AND ?
      ORDER BY [me].[artistid] ASC
    )},
    [
      [ $OFFSET => 3 ],
      [ $TOTAL  => 5 ],
    ],
    'ordered LIMIT/OFFSET uses GenericSubQ, binds offset / offset+rows-1',
  );
}

# --- offset without a stable order: GenericSubQ must refuse it ---
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    { rows => 3, offset => 3 },
  );

  eval { $rs->as_query };
  like(
    $@,
    qr/Generic Subquery Limit does not work on resultsets without an order/i,
    'offset without a stable order_by is refused (GenericSubQ requirement)',
  );
}

done_testing;
