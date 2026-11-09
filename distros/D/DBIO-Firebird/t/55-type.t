use strict;
use warnings;
use Test::More;

# Offline unit test for the consolidated Firebird type module.

use_ok 'DBIO::Firebird::Type';

use DBIO::Firebird::Type qw(sql_type_from_rdb ddl_type_from_info render_size);

# --- sql_type_from_rdb: rdb$field_type number -> bare SQL type ----------------
is(sql_type_from_rdb(7),  'smallint',         'type 7  -> smallint');
is(sql_type_from_rdb(8),  'integer',          'type 8  -> integer');
is(sql_type_from_rdb(10), 'float',            'type 10 -> float');
is(sql_type_from_rdb(12), 'date',             'type 12 -> date');
is(sql_type_from_rdb(13), 'time',             'type 13 -> time');
# Corrected claims (these were pinned wrong against a real server, which stores
# CHAR as 14 and BIGINT as 16 with sub_type 0): 14 was 'timestamp', 9 'bigint',
# 16 'decimal'.
is(sql_type_from_rdb(14), 'char',             'type 14 -> char (not timestamp)');
is(sql_type_from_rdb(16, 0), 'bigint',        'type 16, sub_type 0 -> bigint (not decimal)');
is(sql_type_from_rdb(9),  'quad',             'type 9  -> quad (not bigint)');
is(sql_type_from_rdb(23), 'boolean',          'type 23 -> boolean');
is(sql_type_from_rdb(24), 'decfloat',         'type 24 -> decfloat');
is(sql_type_from_rdb(26, 0), 'int128',        'type 26 -> int128');
is(sql_type_from_rdb(27), 'double precision', 'type 27 -> double precision');
is(sql_type_from_rdb(28), 'time with time zone',      'type 28 -> time with time zone');
is(sql_type_from_rdb(29), 'timestamp with time zone', 'type 29 -> timestamp with time zone');
is(sql_type_from_rdb(35), 'timestamp',        'type 35 -> timestamp');
is(sql_type_from_rdb(37), 'varchar',          'type 37 -> varchar');

# numeric/decimal: the integer storage type plus sub_type 1/2. Bare type --
# size travels separately in the model. (Regression guard: previously folded
# "(p,s)" into the type string, which then got double-rendered by Diff::Table
# as "decimal(p,s)(p,s)".)
is(sql_type_from_rdb(8,  1), 'numeric', 'type 8,  sub_type 1 -> numeric (NUMERIC(9,2))');
is(sql_type_from_rdb(7,  1), 'numeric', 'type 7,  sub_type 1 -> numeric (NUMERIC(4,1))');
is(sql_type_from_rdb(16, 2), 'decimal', 'type 16, sub_type 2 -> decimal (bare, no inline size)');
is(sql_type_from_rdb(26, 1), 'numeric', 'type 26, sub_type 1 -> numeric (NUMERIC(30,2))');
is(sql_type_from_rdb(8,  0), 'integer', 'type 8,  sub_type 0 -> integer');

# blob sub_type: text vs binary (261 was always "text").
is(sql_type_from_rdb(261, 1), 'blob sub_type text', 'blob sub_type 1 -> blob sub_type text');
is(sql_type_from_rdb(261, 0), 'blob',               'blob sub_type 0 -> blob (binary)');

# charset OCTETS (id 1) makes char/varchar binary/varbinary.
is(sql_type_from_rdb(37, 0, 1), 'varbinary', 'varchar in OCTETS -> varbinary');
is(sql_type_from_rdb(14, 0, 1), 'binary',    'char in OCTETS -> binary');
is(sql_type_from_rdb(37, 0, 4), 'varchar',   'varchar in another charset stays varchar');

# Unknown type number falls back to varchar.
is(sql_type_from_rdb(999), 'varchar',         'unknown type -> varchar fallback');

# --- ddl_type_from_info: DBIO column_info -> Firebird DDL type -----------------
is(ddl_type_from_info({ data_type => 'integer' }), 'INTEGER',         'integer -> INTEGER');
# Corrected claims: bigint -> INTEGER and timestamp -> DATE were pinned, but
# both lose data (64-bit range; time of day under dialect 3).
is(ddl_type_from_info({ data_type => 'bigint' }),  'BIGINT',          'bigint  -> BIGINT (not INTEGER)');
is(ddl_type_from_info({ data_type => 'smallint' }), 'SMALLINT',       'smallint -> SMALLINT (not INTEGER)');
is(ddl_type_from_info({ data_type => 'serial' }),  'BIGINT',          'serial  -> BIGINT');
is(ddl_type_from_info({ data_type => 'varchar' }), 'VARCHAR(255)',    'varchar (no size) -> VARCHAR(255) default');
is(ddl_type_from_info({ data_type => 'text' }),    'BLOB SUB_TYPE TEXT', 'text -> BLOB SUB_TYPE TEXT');
is(ddl_type_from_info({ data_type => 'timestamp' }), 'TIMESTAMP',     'timestamp -> TIMESTAMP (not DATE)');
is(ddl_type_from_info({ data_type => 'datetime' }),  'TIMESTAMP',     'datetime -> TIMESTAMP');
is(ddl_type_from_info({ data_type => 'date' }),      'DATE',          'date -> DATE');
is(ddl_type_from_info({ data_type => 'numeric' }), 'DECIMAL(18,6)',   'numeric (no size) -> DECIMAL(18,6) default');
is(ddl_type_from_info({ data_type => 'boolean' }), 'BOOLEAN',         'boolean -> BOOLEAN (Firebird 3 minimum, karr k36)');
is(ddl_type_from_info({ data_type => 'custom_t' }), 'CUSTOM_T',       'unknown -> uppercased');
is(ddl_type_from_info({}),                          'VARCHAR(255)',   'missing data_type -> VARCHAR(255)');

# --- ddl_type_from_info: declared size must be honored, not hardcoded (karr #15) -
is(ddl_type_from_info({ data_type => 'varchar', size => 24 }), 'VARCHAR(24)',
  'varchar size=>24 -> VARCHAR(24), not the hardcoded 255');
is(ddl_type_from_info({ data_type => 'nvarchar', size => 1000 }), 'VARCHAR(1000)',
  'nvarchar size=>1000 -> VARCHAR(1000), not truncated to 255');
is(ddl_type_from_info({ data_type => 'char' }), 'CHAR(1)',
  'char (no size) -> CHAR(1) default');
is(ddl_type_from_info({ data_type => 'char', size => 10 }), 'CHAR(10)',
  'char size=>10 -> CHAR(10), not the hardcoded 1');
is(ddl_type_from_info({ data_type => 'nchar', size => 5 }), 'CHAR(5)',
  'nchar size=>5 -> CHAR(5)');
is(ddl_type_from_info({ data_type => 'decimal', size => [20, 4] }), 'DECIMAL(20,4)',
  'decimal size=>[20,4] -> DECIMAL(20,4), not the hardcoded (18,6)');
is(ddl_type_from_info({ data_type => 'numeric', size => [10, 2] }), 'DECIMAL(10,2)',
  'numeric size=>[10,2] -> DECIMAL(10,2)');

# --- render_size: model size field -> SQL suffix ------------------------------
is(render_size(undef),    '',         'undef size -> empty');
is(render_size(255),      '(255)',    'scalar size -> (n)');
is(render_size([10, 2]),  '(10,2)',   'arrayref size -> (p,s)');

done_testing;
