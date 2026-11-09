use strict;
use warnings;
use Test::More;

# t/35-ddl-emit.t — DBIO::ClickHouse::DDL::Emit, the single source of DDL
# statement shape. Pure string functions, no database.
#
# These assertions are deliberately char-exact: Emit exists so that install_ddl
# and the later diff renderers produce byte-identical SQL for the same schema.
# A whitespace change here is a real behaviour change for the diff layer, and
# these tests are what makes it visible instead of silent.

use DBIO::ClickHouse::DDL::Emit qw(
  quote_ident quote_string column_def index_def
  engine_clause partition_by_clause primary_key_clause order_by_clause
  settings_clause create_table create_view drop_table
  alter_table_add_column alter_table_modify_column alter_table_drop_column
  alter_table_add_index alter_table_drop_index
  create_database drop_database
);

# --- quoting: always backticks, matching SHOW CREATE TABLE ----------------
is quote_ident('artist'), '`artist`',
  'simple identifier is still quoted (SHOW CREATE quotes unconditionally)';
is quote_ident('odd name'), '`odd name`', 'identifier with space';
is quote_ident('we`ird'),   '`we\\`ird`', 'embedded backtick is backslash-escaped';
is quote_string("it's"),    q{'it\\'s'},  'embedded quote is backslash-escaped';
is quote_string('a\\b'),    q{'a\\\\b'},  'embedded backslash is escaped';

# --- column_def: no NOT NULL, nullability is in the type ------------------
is column_def(name => 'name', type => 'String'),
  '`name` String', 'plain column';
is column_def(name => 'name', type => 'Nullable(String)'),
  '`name` Nullable(String)', 'nullability rides in the type, not a constraint';
is column_def(name => 'id', type => 'UUID', default => 'generateUUIDv4()'),
  '`id` UUID DEFAULT generateUUIDv4()', 'default emitted verbatim';
is column_def(name => 'rank', type => 'Int32', default => '0'),
  '`rank` Int32 DEFAULT 0', 'literal default emitted verbatim';
is column_def(name => 'x'),
  '`x` String', 'type defaults to String';

# --- index_def: the one skipping-index fragment ---------------------------
# It lives here rather than in Diff::Index because it appears in two different
# statements — inline in a CREATE TABLE body and after ALTER TABLE ... ADD.
is index_def({ index_name => 'score_mm', expr => 'score',
               type_full => 'minmax', granularity => 4 }),
  'INDEX `score_mm` score TYPE minmax GRANULARITY 4', 'skipping index fragment';
is index_def({ index_name => 'i', expr => 'id',
               type => 'set', type_full => 'set(100)', granularity => 1 }),
  'INDEX `i` id TYPE set(100) GRANULARITY 1',
  'type_full keeps the type arguments';
is index_def({ index_name => 'i', expr => 'id', type => 'set' }),
  'INDEX `i` id TYPE set',
  'bare type is the fallback, and no granularity omits the clause';
is index_def({ index_name => 'i', expr => 'lower(name)', type_full => 'minmax' }),
  'INDEX `i` lower(name) TYPE minmax',
  'the expression is emitted verbatim, not quoted as an identifier';

# --- engine clauses -------------------------------------------------------
is engine_clause('MergeTree'), 'ENGINE = MergeTree', 'engine clause';
is engine_clause('ReplacingMergeTree(version)'),
  'ENGINE = ReplacingMergeTree(version)', 'parameterized engine emitted verbatim';
is engine_clause(undef), 'ENGINE = MergeTree', 'engine defaults to MergeTree';

is partition_by_clause('toYYYYMM(ts)'), 'PARTITION BY toYYYYMM(ts)',
  'partition key is an expression, not an identifier';

is order_by_clause('ts', 'id'), 'ORDER BY (`ts`, `id`)', 'sorting key';
is order_by_clause('id'), 'ORDER BY (`id`)',
  'single-column key still uses the tuple form';
is order_by_clause(), 'ORDER BY tuple()', 'empty key -> tuple()';
is order_by_clause('ts', \'cityHash64(id)'), 'ORDER BY (`ts`, cityHash64(id))',
  'scalar ref entry is raw SQL';

is primary_key_clause('ts'), 'PRIMARY KEY (`ts`)', 'primary key clause';

# --- settings: sorted names, numbers bare, strings quoted -----------------
is settings_clause({ index_granularity => 8192 }),
  'SETTINGS index_granularity = 8192', 'numeric setting emitted bare';
is settings_clause({ b => 2, a => 1 }),
  'SETTINGS a = 1, b = 2', 'setting names sorted for deterministic output';
is settings_clause({ storage_policy => 'hot' }),
  q{SETTINGS storage_policy = 'hot'}, 'non-numeric setting quoted';
is settings_clause({ x => \'someExpr()' }),
  'SETTINGS x = someExpr()', 'scalar ref setting emitted verbatim';
is settings_clause({}), undef, 'empty settings -> undef, nothing to emit';
is settings_clause(undef), undef, 'no settings -> undef';

# --- create_table: indented body, clauses one per line --------------------
is create_table(
    name    => 'event',
    columns => [
      column_def(name => 'id', type => 'UUID'),
      column_def(name => 'ts', type => 'DateTime64(3)')
    ],
    clauses => [engine_clause('MergeTree'), order_by_clause('ts', 'id')]
  ),
  "CREATE TABLE `event` (\n  `id` UUID,\n  `ts` DateTime64(3)\n)\n"
    . "ENGINE = MergeTree\nORDER BY (`ts`, `id`);",
  'create_table wraps, indents the body, appends clauses one per line';

is create_table(
    name    => 'event',
    columns => [column_def(name => 'id', type => 'UUID')],
    clauses => [engine_clause('MergeTree'), undef, order_by_clause('id')]
  ),
  "CREATE TABLE `event` (\n  `id` UUID\n)\nENGINE = MergeTree\nORDER BY (`id`);",
  'undef clauses are dropped, so settings_clause can be passed straight through';

is create_view(name => 'v_event', definition => 'SELECT * FROM `event`'),
  'CREATE VIEW `v_event` AS SELECT * FROM `event`;', 'create_view';

is drop_table(name => 'event'), 'DROP TABLE `event`;',
  'drop_table, with no IF EXISTS';

# --- the ALTER TABLE forms -------------------------------------------------
# These are DDL. ClickHouse spells its row-level UPDATE/DELETE
# "ALTER TABLE ... UPDATE/DELETE" too, but those are asynchronous data
# mutations and belong to DBIO::ClickHouse::SQLMaker, not here.
is alter_table_add_column(
    table => 'user', definition => column_def(name => 'email', type => 'Nullable(String)')
  ),
  'ALTER TABLE `user` ADD COLUMN `email` Nullable(String);', 'ADD COLUMN';

is alter_table_modify_column(
    table => 'user', definition => column_def(name => 'rank', type => 'Int64')
  ),
  'ALTER TABLE `user` MODIFY COLUMN `rank` Int64;', 'MODIFY COLUMN';

is alter_table_modify_column(
    table => 'user',
    definition => column_def(name => 'rank', type => 'Int64', default => '0')
  ),
  'ALTER TABLE `user` MODIFY COLUMN `rank` Int64 DEFAULT 0;',
  'MODIFY COLUMN carries whatever column_def rendered, default included';

is alter_table_drop_column(table => 'user', name => 'legacy'),
  'ALTER TABLE `user` DROP COLUMN `legacy`;', 'DROP COLUMN';

# ADD INDEX takes the same fragment the CREATE TABLE body gets — the INDEX
# keyword comes from index_def, so the two spellings cannot drift apart.
is alter_table_add_index(
    table      => 'metric',
    definition => index_def({ index_name => 'score_mm', expr => 'score',
                              type_full => 'minmax', granularity => 4 })
  ),
  'ALTER TABLE `metric` ADD INDEX `score_mm` score TYPE minmax GRANULARITY 4;',
  'ADD INDEX wraps index_def unchanged';

is alter_table_drop_index(table => 'metric', name => 'old'),
  'ALTER TABLE `metric` DROP INDEX `old`;', 'DROP INDEX';

# --- the database statements ----------------------------------------------
# Deliberately unterminated: unlike everything above they never go into a DDL
# script, they are the two statements Deploy issues on their own around one.
is create_database(name => 'dbio_deploy_tmp_1_2'),
  'CREATE DATABASE `dbio_deploy_tmp_1_2`',
  'create_database, no ENGINE and no trailing semicolon';
is drop_database(name => 'dbio_deploy_tmp_1_2', if_exists => 1),
  'DROP DATABASE IF EXISTS `dbio_deploy_tmp_1_2`',
  'drop_database with IF EXISTS, the form Deploy always asks for';
is drop_database(name => 'scratch'), 'DROP DATABASE `scratch`',
  'IF EXISTS is opt-in';

done_testing;
