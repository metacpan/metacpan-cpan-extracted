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

# --- column_opclasses ---
#
# WHY this matters: pgvector's hnsw access method has NO default operator
# class for vector, and ivfflat falls back to vector_l2_ops. So an hnsw index
# is only redeployable, and an ivfflat index only keeps its distance, if the
# opclass makes it out of pg_get_indexdef and back into the pg_index metadata
# (karr k39).

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(undef),
  {},
  'undef definition -> {}',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX users_embedding_idx ON auth.users USING hnsw (embedding vector_cosine_ops)'
  ),
  { embedding => 'vector_cosine_ops' },
  'pgvector hnsw opclass extracted',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    q{CREATE INDEX users_embedding_idx ON auth.users USING ivfflat (embedding vector_l2_ops) WITH (lists='100')}
  ),
  { embedding => 'vector_l2_ops' },
  'opclass extracted with a trailing WITH clause',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING btree (id, name text_pattern_ops)'
  ),
  { name => 'text_pattern_ops' },
  'only the column carrying a non-default opclass is reported',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING btree (name COLLATE "C" text_pattern_ops DESC NULLS LAST)'
  ),
  { name => 'text_pattern_ops' },
  'COLLATE clause and sort options are stepped over',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING btree (name DESC NULLS LAST)'
  ),
  {},
  'sort options are not mistaken for an opclass',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING btree ("Mixed Case" text_pattern_ops)'
  ),
  { 'Mixed Case' => 'text_pattern_ops' },
  'quoted identifier unquoted as the key',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    q{CREATE INDEX i ON t USING btree (lower((a || ','::text)), b text_pattern_ops)}
  ),
  { b => 'text_pattern_ops' },
  'expression entries with nested parens and commas do not break the split',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING gist (c tsvector_ops(siglen=32))'
  ),
  { c => 'tsvector_ops(siglen=32)' },
  'operator class parameters (PG13+) are kept with the name',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses(
    'CREATE INDEX i ON t USING btree (a) INCLUDE (b)'
  ),
  {},
  'INCLUDE columns are outside the key list and never reported',
);

is_deeply(
  DBIO::PostgreSQL::Introspect::Parse->column_opclasses('not an index definition'),
  {},
  'unparseable definition -> {}',
);

done_testing;
