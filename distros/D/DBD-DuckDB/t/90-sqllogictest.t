#perl -T

use strict;
use warnings;

use Test::More;
use POSIX;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

run_sqllogictest(\*DATA, $dbh);

done_testing;

__DATA__
statement ok
SELECT version()

statement ok
CREATE TABLE all_types AS FROM test_all_types()

# DUCKDB_TYPE_BOOLEAN

query B
SELECT bool FROM all_types
----
FALSE
TRUE
NULL

# DUCKDB_TYPE_TINYINT (int8)

query I
SELECT tinyint FROM all_types LIMIT 2
----
-128
127

# DUCKDB_TYPE_UTINYINT (uint8)

query I
SELECT utinyint FROM all_types LIMIT 2
----
0
255

# DUCKDB_TYPE_SMALLINT (int16)

query I
SELECT smallint FROM all_types LIMIT 2
----
-32768
32767

# DUCKDB_TYPE_USMALLINT (uint16)

query I
SELECT usmallint FROM all_types LIMIT 2
----
0
65535

# DUCKDB_TYPE_INTEGER (int32)

query I
SELECT int FROM all_types LIMIT 2
----
-2147483648
2147483647

# DUCKDB_TYPE_UINTEGER (uint32)

query I
SELECT uint FROM all_types LIMIT 2
----
0
4294967295

# DUCKDB_TYPE_BIGINT (int64)

query I
SELECT bigint FROM all_types LIMIT 2
----
-9223372036854775808
9223372036854775807

# DUCKDB_TYPE_UBIGINT (uint64)

query I
SELECT ubigint FROM all_types LIMIT 2
----
0
18446744073709551615

# DUCKDB_TYPE_HUGEINT (int64)

query I
SELECT hugeint FROM all_types LIMIT 2
----
-170141183460469231731687303715884105728
170141183460469231731687303715884105727

# DUCKDB_TYPE_UUID

query S
SELECT uuid FROM all_types LIMIT 2
----
00000000-0000-0000-0000-000000000000
ffffffff-ffff-ffff-ffff-ffffffffffff

# DUCKDB_TYPE_BIT

query S
SELECT bit FROM all_types LIMIT 2
----
0010001001011100010101011010111
10101

# DUCKDB_TYPE_FLOAT

query S
SELECT float FROM all_types LIMIT 2
----
-3.40282346638529e+38
3.40282346638529e+38

# DUCKDB_TYPE_DOUBLE

query S
SELECT double FROM all_types LIMIT 2
----
-1.79769313486232e+308
1.79769313486232e+308

# DUCKDB_TYPE_DATE

query S
SELECT date FROM all_types LIMIT 2
----
-5877641-06-25
5881580-07-10

# DUCKDB_TYPE_TIMESTAMP

query S
SELECT timestamp FROM all_types LIMIT 2
----
-290308-12-22 00:00:00
294247-01-10 04:00:54.775806

# DUCKDB_TYPE_DECIMAL

query III
SELECT dec_4_1, dec_9_4, dec_18_6 FROM all_types LIMIT 2
----
-999.9	-99999.9999	-1000000000000.000000
999.9	99999.9999	1000000000000.000000

# DUCKDB_TYPE_ARRAY - INT

query S
SELECT int_array FROM all_types LIMIT 2
----
[]
[42,999,null,null,-42]

# DUCKDB_TYPE_ARRAY - nested INT

query S
SELECT nested_int_array FROM all_types LIMIT 2
----
[]
[[],[42,999,null,null,-42],null,[],[42,999,null,null,-42]]

# DUCKDB_TYPE_ENUM

query SSS
SELECT small_enum, medium_enum, large_enum FROM all_types LIMIT 2
----
DUCK_DUCK_ENUM	enum_0	enum_0
GOOSE	enum_299	enum_69999

# Test with NULL char

# DUCKDB_TYPE_VARCHAR (test only UTF-8)

query S
SELECT varchar FROM all_types LIMIT 1
----
🦆🦆🦆🦆🦆🦆

# DUCKDB_TYPE_BLOB

# query S
# SELECT blob FROM all_types LIMIT 2
# ----
# thisisalongblob\0withnullbytes
# a
