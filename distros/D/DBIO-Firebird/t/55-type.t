use strict;
use warnings;
use Test::More;

# Offline unit test for the consolidated Firebird type module.

use_ok 'DBIO::Firebird::Type';

use DBIO::Firebird::Type qw(sql_type_from_rdb ddl_type_from_info render_size);

# --- sql_type_from_rdb: rdb$field_type number -> bare SQL type ----------------
is(sql_type_from_rdb(7),  'smallint',         'type 7  -> smallint');
is(sql_type_from_rdb(8),  'integer',          'type 8  -> integer');
is(sql_type_from_rdb(9),  'bigint',           'type 9  -> bigint');
is(sql_type_from_rdb(12), 'date',             'type 12 -> date');
is(sql_type_from_rdb(14), 'timestamp',        'type 14 -> timestamp');
is(sql_type_from_rdb(27), 'double precision', 'type 27 -> double precision');
is(sql_type_from_rdb(37), 'varchar',          'type 37 -> varchar');

# decimal/numeric return the BARE type -- size travels separately in the model.
# (Regression guard: previously folded "(p,s)" into the type string, which then
# got double-rendered by Diff::Table as "decimal(p,s)(p,s)".)
is(sql_type_from_rdb(16), 'decimal',          'type 16 -> decimal (bare, no inline size)');

# Unknown type number falls back to varchar.
is(sql_type_from_rdb(999), 'varchar',         'unknown type -> varchar fallback');

# --- ddl_type_from_info: DBIO column_info -> Firebird DDL type -----------------
is(ddl_type_from_info({ data_type => 'integer' }), 'INTEGER',         'integer -> INTEGER');
is(ddl_type_from_info({ data_type => 'bigint' }),  'INTEGER',         'bigint  -> INTEGER');
is(ddl_type_from_info({ data_type => 'serial' }),  'BIGINT',          'serial  -> BIGINT');
is(ddl_type_from_info({ data_type => 'varchar' }), 'VARCHAR(255)',    'varchar -> VARCHAR(255)');
is(ddl_type_from_info({ data_type => 'text' }),    'BLOB SUB_TYPE TEXT', 'text -> BLOB SUB_TYPE TEXT');
is(ddl_type_from_info({ data_type => 'timestamp' }), 'DATE',          'timestamp -> DATE');
is(ddl_type_from_info({ data_type => 'numeric' }), 'DECIMAL(18,6)',   'numeric -> DECIMAL(18,6)');
is(ddl_type_from_info({ data_type => 'boolean' }), 'SMALLINT',        'boolean -> SMALLINT');
is(ddl_type_from_info({ data_type => 'custom_t' }), 'CUSTOM_T',       'unknown -> uppercased');
is(ddl_type_from_info({}),                          'VARCHAR(255)',   'missing data_type -> VARCHAR(255)');

# --- render_size: model size field -> SQL suffix ------------------------------
is(render_size(undef),    '',         'undef size -> empty');
is(render_size(255),      '(255)',    'scalar size -> (n)');
is(render_size([10, 2]),  '(10,2)',   'arrayref size -> (p,s)');

done_testing;
