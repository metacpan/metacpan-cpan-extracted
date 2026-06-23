use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Introspect::Parse ();

# --- include_columns ---

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->include_columns(undef),
  [],
  'undef definition -> []',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->include_columns(
    'CREATE INDEX foo ON tbl (a) INCLUDE (b, c)'
  ),
  ['b', 'c'],
  'simple INCLUDE clause',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->include_columns(
    'CREATE INDEX foo ON tbl (a) INCLUDE ("col with space", d)'
  ),
  ['col with space', 'd'],
  'strips whitespace and double quotes',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->include_columns(
    'CREATE INDEX foo ON tbl (a)'
  ),
  [],
  'no INCLUDE clause -> []',
);

# --- storage_params ---

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->storage_params(undef),
  {},
  'undef reloptions -> {}',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->storage_params('{fillfactor=70, vacuum_cleanup_index_scale_factor=0.1}'),
  { fillfactor => '70', vacuum_cleanup_index_scale_factor => '0.1' },
  'string form with braces',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->storage_params(['fillfactor=70', 'pages_per_range=128']),
  { fillfactor => '70', pages_per_range => '128' },
  'arrayref form',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->storage_params('{}'),
  {},
  'empty braces -> {}',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->storage_params('fillfactor=70'),
  { fillfactor => '70' },
  'bare string without braces',
);

done_testing;
