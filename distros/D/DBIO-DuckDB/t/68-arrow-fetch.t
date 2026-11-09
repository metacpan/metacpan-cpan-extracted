#!/usr/bin/env perl
# t/68-arrow-fetch.t -- duckdb_arrow_fetch reads a result through libduckdb's
# Arrow interface and answers { names, formats, columns, rows }.
#
# WHY this matters: the point of the Arrow path is that a result comes back as
# columns, decoded per buffer, without the row iterator -- but a caller swaps
# a selectall_arrayref for it and must get the same VALUES. So every type is
# compared with the row path of the same query (laid on its side). The time
# types are the exception: DATE, TIME, TIMESTAMP and INTERVAL are compared with
# DuckDB's own text, CAST(v AS VARCHAR), and TIMESTAMPTZ is UTC whatever the
# session zone is. The row path of DBD::DuckDB 0.16 differs from that text; the
# comparison with it is a TODO block that turns green with the fixed DBD::DuckDB.
# What the decoder cannot render must throw, naming column and format and never
# a value.

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Temp ();
use FFI::Platypus::Memory qw(calloc memcpy);
use FFI::Platypus::Buffer qw(scalar_to_buffer);
use DBIO::DuckDB::Test;

my $PROBE = <<'EOP';
my $d = DBI->connect("dbi:DuckDB:dbname=$ARGV[0]", '', '', { RaiseError => 0, PrintError => 0 });
if ($d) { $d->disconnect; exit 0 }
exit 3;
EOP

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

$dbh->do(q{CREATE TYPE mood AS ENUM ('sad', 'ok', 'glad')});

# The row path of the same statement, as columns.
sub row_columns {
  my ($sql, @binds) = @_;
  my $sth = $dbh->prepare($sql);
  $sth->execute(@binds);
  my $cols = $sth->{NUM_OF_FIELDS};
  my $rows = $sth->fetchall_arrayref;
  return [ map { my $c = $_; [ map { $_->[$c] } @$rows ] } 0 .. $cols - 1 ];
}

# One column of values of one type, NULL last: compared with the row path.
my @cases = (
  [ 'BOOLEAN',   'b',  'BOOLEAN',   [ 'true', 'false' ] ],
  [ 'TINYINT',   'c',  'TINYINT',   [ '-128', '0', '127' ] ],
  [ 'SMALLINT',  's',  'SMALLINT',  [ '-32768', '0', '32767' ] ],
  [ 'INTEGER',   'i',  'INTEGER',   [ '-2147483648', '0', '2147483647' ] ],
  [ 'BIGINT',    'l',  'BIGINT',    [ '-9223372036854775808', '0', '9223372036854775807' ] ],
  [ 'UTINYINT',  'C',  'UTINYINT',  [ '0', '255' ] ],
  [ 'USMALLINT', 'S',  'USMALLINT', [ '0', '65535' ] ],
  [ 'UINTEGER',  'I',  'UINTEGER',  [ '0', '4294967295' ] ],
  [ 'UBIGINT',   'L',  'UBIGINT',   [ '0', '9223372036854775808', '18446744073709551615' ] ],
  [ 'HUGEINT',   'd:38,0', 'HUGEINT', [
      '-170141183460469231731687303715884105727', '0', '170141183460469231731687303715884105727',
      '-9223372036854775808', '-9223372036854775809', '-18446744073709551611',
      '-18446744073709551616', '9223372036854775808', '18446744073709551616' ] ],
  [ 'UHUGEINT',  'd:38,0', 'UHUGEINT', [ '0', '1', '340282366920938463463374607431768211455' ] ],
  [ 'FLOAT',     'f',  'FLOAT',     [ '1.5', '-0.25', '0.1', '3.4028235e38' ] ],
  [ 'DOUBLE',    'g',  'DOUBLE',    [ '1.5', '-0.1', '1e300', '0.30000000000000004' ] ],
  [ 'DECIMAL(4,1)',  'd:4,1,128',   'DECIMAL(4,1)',  [ '-999.9', '0', '999.9', '-0.5' ] ],
  [ 'DECIMAL(9,0)',  'd:9,0,128',   'DECIMAL(9,0)',  [ '-999999999', '0', '999999999' ] ],
  [ 'DECIMAL(18,3)', 'd:18,3,128',  'DECIMAL(18,3)', [ '123456789012.345', '-0.001', '0' ] ],
  [ 'DECIMAL(38,10)', 'd:38,10,128', 'DECIMAL(38,10)', [
      '-9999999999999999999999999999.9999999999', '0', '1.0000000001',
      '9999999999999999999999999999.9999999999' ] ],
  [ 'DECIMAL(38,0)', 'd:38,0,128',  'DECIMAL(38,0)', [
      '-99999999999999999999999999999999999999', '99999999999999999999999999999999999999' ] ],
  [ 'VARCHAR',   'u',  'VARCHAR',   [ q{'plain'}, q{''}, q{'äöü € 日本語'}, q{'it''s'} ] ],
  [ 'BLOB',      'z',  'BLOB',      [ q{'\xAA\x00\xFF'}, q{''}, q{'abc'} ] ],
  [ 'UUID',      'u',  'UUID',      [ q{'5f0d3a4e-0000-4000-8000-000000000001'}, q{'ffffffff-ffff-ffff-ffff-ffffffffffff'} ] ],
  [ 'JSON',      'u',  'JSON',      [ q{'{"a":[1,2]}'} ] ],
  [ 'DATE',      'tdD', 'DATE',     [ q{'1969-07-20'}, q{'1970-01-01'}, q{'2026-10-31'}, q{'0001-01-01'} ] ],
  [ 'TIMESTAMP_S',  'tss:', 'TIMESTAMP_S',  [ q{'1969-07-20 20:17:40'}, q{'2026-10-31 01:02:03'} ] ],
  [ 'TIMESTAMP_MS', 'tsm:', 'TIMESTAMP_MS', [ q{'2026-10-31 01:02:03.456'} ] ],
  [ 'TIMESTAMP',    'tsu:', 'TIMESTAMP',    [ q{'2026-10-31 01:02:03.456789'}, q{'2026-10-31 00:00:00'} ] ],
  [ 'TIMESTAMP_NS', 'tsn:', 'TIMESTAMP_NS', [ q{'2026-10-31 01:02:03.123456789'}, q{'2026-10-31 01:02:03'} ] ],
  [ 'ENUM',      'C',  'mood',      [ q{'sad'}, q{'glad'}, q{'ok'} ] ],
  [ 'LIST',      '+l', 'INTEGER[]', [ '[1, 2, NULL]', '[]', '[NULL]', '[7]' ] ],
  [ 'LIST of LIST', '+l', 'INTEGER[][]', [ '[[1], [2, NULL], NULL, []]', '[]' ] ],
  [ 'LIST of VARCHAR', '+l', 'VARCHAR[]', [ q{['a', NULL, 'b']}, q{['']} ] ],
  [ 'ARRAY',     '+w:2', 'INTEGER[2]', [ '[1, 2]', '[NULL, 3]' ] ],
  [ 'STRUCT',    '+s', 'STRUCT(x INTEGER, y VARCHAR)', [ q{{'x': 1, 'y': 'z'}}, q{{'x': NULL, 'y': NULL}} ] ],
  [ 'STRUCT with LIST', '+s', 'STRUCT(a INTEGER[], b STRUCT(c DOUBLE))',
      [ q{{'a': [1, NULL], 'b': {'c': 1.5}}}, q{{'a': NULL, 'b': NULL}}, q{{'a': [], 'b': {'c': NULL}}} ] ],
  [ 'MAP',       '+m', 'MAP(VARCHAR, INTEGER)', [ q{MAP {'k': 1, 'j': NULL}}, q{MAP {}} ] ],
  [ 'LIST of STRUCT', '+l', 'STRUCT(a INTEGER, b VARCHAR)[]',
      [ q{[{'a': 1, 'b': 'x'}, NULL, {'a': NULL, 'b': 'y'}]} ] ],
);

for my $case (@cases) {
  my ($name, $format, $type, $values) = @$case;
  my $sql = 'SELECT v FROM (VALUES '
    . join(', ', map { "(CAST($_ AS $type))" } @$values, 'NULL')
    . ') t(v)';
  my $t = $storage->duckdb_arrow_fetch($sql, []);
  my $want = row_columns($sql);

  is $t->{rows}, scalar @{ $want->[0] }, "$name: rows";
  is_deeply $t->{names}, ['v'], "$name: names";
  is $t->{formats}[0], $format, "$name: arrow format";
  is_deeply $t->{columns}, $want, "$name: values equal the row path";
  ok !defined $t->{columns}[0][-1], "$name: NULL is undef";
}

# The time types against DuckDB's own text, CAST(v AS VARCHAR): the fraction
# padded to the precision of the type and without trailing zeros, years up to 0
# as "YYYY-MM-DD (BC)" (year 1 - y, "(BC)" between date and time), before 1970.
my $BC_TS = q{CAST(DATE '0044-03-15 (BC)' AS TIMESTAMP) + INTERVAL '12 hours 0.5 seconds'};
my @text_cases = (
  [ 'TIME',                 'ttu',  q{TIME '12:34:56.789'} ],
  [ 'TIME .120',            'ttu',  q{TIME '11:30:00.120'} ],
  [ 'TIME .000005',         'ttu',  q{TIME '11:30:00.000005'} ],
  [ 'TIME midnight',        'ttu',  q{TIME '00:00:00'}, 1 ],
  [ 'TIME last tick',       'ttu',  q{TIME '23:59:59.999999'}, 1 ],
  [ 'TIMESTAMP_S',          'tss:', q{TIMESTAMP_S '1969-07-20 20:17:40'}, 1 ],
  [ 'TIMESTAMP_MS',         'tsm:', q{TIMESTAMP_MS '1969-07-20 20:17:40.123'} ],
  [ 'TIMESTAMP_MS .120',    'tsm:', q{TIMESTAMP_MS '2026-10-31 11:30:00.120'} ],
  [ 'TIMESTAMP',            'tsu:', q{TIMESTAMP '1969-07-20 20:17:40.123456'} ],
  [ 'TIMESTAMP .120',       'tsu:', q{TIMESTAMP '2026-10-31 11:30:00.120'} ],
  [ 'TIMESTAMP .000005',    'tsu:', q{TIMESTAMP '2026-10-31 11:30:00.000005'} ],
  [ 'TIMESTAMP_NS',         'tsn:', q{TIMESTAMP_NS '1969-07-20 20:17:40.123456789'} ],
  [ 'TIMESTAMP_NS .120',    'tsn:', q{TIMESTAMP_NS '2026-10-31 11:30:00.120'} ],
  [ 'TIMESTAMP_NS .000005', 'tsn:', q{TIMESTAMP_NS '2026-10-31 11:30:00.000005'} ],
  [ 'TIMESTAMP_NS .000000005', 'tsn:', q{TIMESTAMP_NS '2026-10-31 11:30:00.000000005'} ],
  [ 'TIMESTAMP at -1 tick', 'tsu:', q{TIMESTAMP '1969-12-31 23:59:59.999999'} ],
  [ 'DATE BC 0044',         'tdD',  q{DATE '0044-03-15 (BC)'} ],
  [ 'DATE BC 0001',         'tdD',  q{DATE '0001-12-31 (BC)'} ],
  [ 'DATE 0001-01-01',      'tdD',  q{DATE '0001-01-01'}, 1 ],
  [ 'TIMESTAMP BC',         'tsu:', "($BC_TS)" ],
);
for my $c (@text_cases) {
  my ($name, $format, $expr) = @$c;
  my $t    = $storage->duckdb_arrow_fetch("SELECT $expr AS v");
  my ($want) = $dbh->selectrow_array("SELECT CAST($expr AS VARCHAR)");
  is $t->{formats}[0], $format, "$name: arrow format";
  is $t->{columns}[0][0], $want, "$name: equal CAST(v AS VARCHAR)";
}

# what the row path of 0.16 already has the same stays against it
for my $c (grep { $_->[3] } @text_cases) {
  my ($name, $format, $expr) = @$c;
  my $sql = "SELECT $expr AS v";
  is_deeply $storage->duckdb_arrow_fetch($sql)->{columns}, row_columns($sql), "$name: equal the row path";
}
{
  my ($bc) = $dbh->selectrow_array("SELECT CAST($BC_TS AS VARCHAR)");
  is $bc, '0044-03-15 (BC) 12:00:00.5', 'the BC timestamp is the text this suite expects';
  my $t = $storage->duckdb_arrow_fetch(q{SELECT [DATE '0044-03-15 (BC)', NULL] AS l, {'t': TIME '11:30:00.120'} AS s});
  is_deeply $t->{columns}[0][0], [ '0044-03-15 (BC)', undef ], 'LIST of DATE: the same decoder, BC';
  is_deeply $t->{columns}[1][0], { t => '11:30:00.12' }, 'STRUCT with TIME: the same decoder, no trailing zeros';
}

# The row path of DBD::DuckDB 0.16 against the same values. A TODO: it differs
# from DuckDB's text and turns green with the fixed DBD::DuckDB.
my $ROW_PATH_TODO = 'DBD::DuckDB 0.16 differs from DuckDB\'s text (CAST(v AS VARCHAR)) in the row path: '
  . 'fraction, BC years, INTERVAL, infinity. The fix, with tests, is giterlizzi/perl-DBD-DuckDB#56. '
  . 'When this passes: remove the TODO, raise requires \'DBD::DuckDB\' in the cpanfile to the release '
  . 'with the fix and move these cases into the loop against the row path.';
my $INTERVALS = q{(INTERVAL 1 DAY + INTERVAL 3 HOUR), (INTERVAL '-5 months 2 days'),
        (INTERVAL 1 YEAR + INTERVAL 1500 MILLISECOND), (INTERVAL '-1 year'), (INTERVAL '-1 day'),
        (INTERVAL '-17 months'), (INTERVAL '-1 month'), (INTERVAL '13 months'), (NULL::INTERVAL)};
TODO: {
  local $TODO = $ROW_PATH_TODO;
  for my $c (grep { !$_->[3] } @text_cases) {
    my ($name, $format, $expr) = @$c;
    my $sql = "SELECT $expr AS v";
    is_deeply $storage->duckdb_arrow_fetch($sql)->{columns}, row_columns($sql), "$name: equal the row path";
  }
  my $isql = "SELECT v FROM (VALUES $INTERVALS) t(v)";
  is_deeply $storage->duckdb_arrow_fetch($isql)->{columns}, row_columns($isql), 'INTERVAL: equal the row path';
  $dbh->do(q{SET TimeZone = 'UTC'});
  for my $type (qw(DATE TIMESTAMP_S TIMESTAMP_MS TIMESTAMP TIMESTAMP_NS)) {
    my $sql = "SELECT v FROM (VALUES (CAST('infinity' AS $type)), (CAST('-infinity' AS $type))) t(v)";
    is_deeply $storage->duckdb_arrow_fetch($sql)->{columns}, row_columns($sql), "$type infinity: equal the row path";
  }
}

# Text inside nested values is characters too (the row path leaves it as bytes).
{
  my $t = $storage->duckdb_arrow_fetch(
    q{SELECT ['a', 'äö'] AS l, {'k': 'äö'} AS s, MAP {'ä': 'ö'} AS m});
  is_deeply $t->{columns}, [ [ ['a', "äö"] ], [ { k => "äö" } ], [ { "ä" => "ö" } ] ],
    'non-ASCII text in LIST, STRUCT and MAP: characters';
}

# Text stays text, as the row path has it: UTF-8 decoded characters.
{
  my $t = $storage->duckdb_arrow_fetch(q{SELECT 'äö€' AS s, '' AS e});
  is $t->{columns}[0][0], "äö€", 'non-ASCII text: characters';
  ok utf8::is_utf8($t->{columns}[0][0]), 'non-ASCII text: flagged as characters';
  is $t->{columns}[1][0], '', 'empty string stays empty, not undef';
}

# BOOLEAN keeps the row path's truth values.
{
  my $t = $storage->duckdb_arrow_fetch('SELECT true AS t, false AS f');
  ok  $t->{columns}[0][0], 'true is true';
  ok !$t->{columns}[1][0], 'false is false';
  is_deeply $t->{columns}, row_columns('SELECT true AS t, false AS f'), 'booleans as the row path';
}

# --- INTERVAL and TIMESTAMPTZ -------------------------------------------------

{
  my $t = $storage->duckdb_arrow_fetch(
    q{SELECT v FROM (VALUES (INTERVAL 1 DAY + INTERVAL 3 HOUR), (INTERVAL '-5 months 2 days'),
        (INTERVAL 1 YEAR + INTERVAL 1500 MILLISECOND), (INTERVAL '-1 year'), (INTERVAL '-1 day'),
        (INTERVAL '-17 months'), (INTERVAL '-1 month'), (INTERVAL '13 months'), (NULL::INTERVAL)) t(v)});
  is $t->{formats}[0], 'tin', 'INTERVAL: arrow format';
  is $t->{columns}[0][0], '1 day 03:00:00', 'INTERVAL: DuckDB text form, not the row path\'s "1 day"';
  my $want = $dbh->selectcol_arrayref(
    q{SELECT CAST(v AS VARCHAR) FROM (VALUES (INTERVAL 1 DAY + INTERVAL 3 HOUR), (INTERVAL '-5 months 2 days'),
        (INTERVAL 1 YEAR + INTERVAL 1500 MILLISECOND), (INTERVAL '-1 year'), (INTERVAL '-1 day'),
        (INTERVAL '-17 months'), (INTERVAL '-1 month'), (INTERVAL '13 months'), (NULL::INTERVAL)) t(v)});
  is_deeply $t->{columns}[0], $want, 'INTERVAL: equal CAST(v AS VARCHAR)';
}

{
  my $values = q{(TIMESTAMPTZ '2026-10-31 01:02:03+00'), (TIMESTAMPTZ '1969-07-20 20:17:40.5+05'), (NULL::TIMESTAMPTZ)};
  my $sql    = "SELECT v FROM (VALUES $values) t(v)";
  my ($zone) = $dbh->selectrow_array(q{SELECT current_setting('TimeZone')});
  for my $session_zone ($zone, 'America/Los_Angeles', 'UTC') {
    $dbh->do("SET TimeZone = '$session_zone'");
    my $t = $storage->duckdb_arrow_fetch($sql);
    $dbh->do(q{SET TimeZone = 'UTC'});
    my $want = $dbh->selectcol_arrayref("SELECT CAST(v AS VARCHAR) FROM (VALUES $values) t(v)");
    is_deeply $t->{columns}[0], $want, "TIMESTAMPTZ in UTC, whatever the session zone ($session_zone)";
    is $t->{columns}[0][0], '2026-10-31 01:02:03+00', 'TIMESTAMPTZ: text form with +00';
  }
  $dbh->do("SET TimeZone = '$zone'");
}

# --- infinity -----------------------------------------------------------------
# DuckDB stores +infinity as the largest value of the storage type and -infinity
# as the smallest plus one; the Arrow path answers DuckDB's own text.

{
  $dbh->do(q{SET TimeZone = 'UTC'});
  for my $c (
    [ 'DATE',          'tdD',  'DATE',          q{'2026-10-31'} ],
    [ 'TIMESTAMP_S',   'tss:', 'TIMESTAMP_S',   q{'2026-10-31 01:02:03'} ],
    [ 'TIMESTAMP_MS',  'tsm:', 'TIMESTAMP_MS',  q{'2026-10-31 01:02:03.456'} ],
    [ 'TIMESTAMP',     'tsu:', 'TIMESTAMP',     q{'2026-10-31 01:02:03.456789'} ],
    [ 'TIMESTAMP_NS',  'tsn:', 'TIMESTAMP_NS',  q{'2026-10-31 01:02:03.123456789'} ],
    [ 'TIMESTAMPTZ',   'tsu:UTC', 'TIMESTAMPTZ', q{'2026-10-31 01:02:03+00'} ],
  ) {
    my ($name, $format, $type, $normal) = @$c;
    my $sql = "SELECT v FROM (VALUES (CAST('infinity' AS $type)), (CAST('-infinity' AS $type)), "
      . "(CAST($normal AS $type)), (CAST(NULL AS $type))) t(v)";
    my $t    = $storage->duckdb_arrow_fetch($sql);
    my $want = $dbh->selectcol_arrayref("SELECT CAST(v AS VARCHAR) FROM ($sql) q");
    is $t->{formats}[0], $format, "$name infinity: arrow format";
    is_deeply [ @{ $t->{columns}[0] }[0, 1] ], [ 'infinity', '-infinity' ], "$name: infinity and -infinity are the words";
    is_deeply $t->{columns}[0], $want, "$name: equal CAST(v AS VARCHAR), the ordinary value and NULL kept";
  }

  # the neighbours of the sentinels are values, not infinity
  my $t = $storage->duckdb_arrow_fetch(
    q{SELECT v FROM (VALUES (TIMESTAMP '294247-01-10 04:00:54.775806')) t(v)});
  is $t->{columns}[0][0], '294247-01-10 04:00:54.775806', 'one tick before +infinity is a timestamp';
  my $d = $storage->duckdb_arrow_fetch(q{SELECT DATE '5881580-07-10' AS d});
  is $d->{columns}[0][0], '5881580-07-10', 'the last finite DATE is a date';
}

# --- several columns, names by position, duplicates --------------------------

{
  my $sql = q{SELECT 1 AS a, 'x' AS b, 2.5 AS a, NULL AS n};
  my $t   = $storage->duckdb_arrow_fetch($sql);
  is_deeply $t->{names}, [qw(a b a n)], 'names by position, duplicates kept';
  is scalar @{ $t->{formats} }, 4, 'a format per column';
  is_deeply $t->{columns}, row_columns($sql), 'duplicate names: values by position';
  is $t->{rows}, 1, 'one row';
}

# --- more than one block of 2048, NULLs across the boundary ------------------

{
  my $sql = q{SELECT i::INTEGER AS a,
                     CASE WHEN i % 7 = 0 THEN NULL ELSE i * 1.5 END::DOUBLE AS b,
                     CASE WHEN i % 5 = 0 THEN NULL ELSE 'v' || i END AS s,
                     CASE WHEN i % 3 = 0 THEN NULL ELSE [i, i + 1] END AS l,
                     CASE WHEN i % 11 = 0 THEN NULL ELSE i::HUGEINT * 100000000000000000000 END AS h
              FROM range(5000) t(i)};
  my $t = $storage->duckdb_arrow_fetch($sql);
  is $t->{rows}, 5000, 'more than two blocks: row count';
  is scalar @{ $t->{columns}[0] }, 5000, 'more than two blocks: every column complete';
  is_deeply $t->{columns}, row_columns($sql), 'more than two blocks: values and NULLs equal the row path';
  is_deeply [ map { defined $_ ? 1 : 0 } @{ $t->{columns}[1] }[2045 .. 2050] ],
    [ map { $_ % 7 == 0 ? 0 : 1 } 2045 .. 2050 ],
    'NULL pattern holds over the block boundary';
}

# --- binds --------------------------------------------------------------------

{
  my $t = $storage->duckdb_arrow_fetch(
    q{SELECT i, ? || '!' AS s FROM range(10) t(i) WHERE i > ? AND i < ?},
    [ 'hé', 3, 7 ],
  );
  is_deeply $t->{columns}, [ [ 4, 5, 6 ], [ ('hé!') x 3 ] ], 'binds are bound';
  is $t->{rows}, 3, 'rows with binds';
  my $none = $storage->duckdb_arrow_fetch('SELECT 42 AS x');
  is_deeply $none->{columns}, [ [42] ], 'binds default to none';
}

# --- an empty result ----------------------------------------------------------

{
  my $t = $storage->duckdb_arrow_fetch(q{SELECT 1::INTEGER AS a, 'x' AS b WHERE false});
  is_deeply $t, { names => [qw(a b)], formats => [qw(i u)], columns => [ [], [] ], rows => 0 },
    'empty result: names, formats, empty columns, 0 rows';
}

# --- what cannot be rendered throws, naming column and format, never a value --

for my $c (
  [ 'BIT',      q{'10110011101'::BIT},                   '10110011101' ],
  [ 'UNION',    q{union_value(tag := 'secret-value-1')}, 'secret-value-1' ],
  [ 'TIME WITH TIME ZONE', q{TIMETZ '12:34:56.123+02'},   '12:34:56' ],
  [ 'TIME_NS',  q{TIME_NS '12:34:56.123456789'},         '12:34:56' ],
  [ 'BIGNUM',   q{4242424242424242424242::BIGNUM},       '4242424242424242424242' ],
  [ 'BIT in a LIST', q{['1011101110111']::BIT[]},        '1011101110111' ],
) {
  my ($name, $expr, $value) = @$c;
  my $err;
  eval { $storage->duckdb_arrow_fetch("SELECT 1 AS before, $expr AS \"the col\"") ; 1 }
    or $err = "$@";
  ok defined $err, "$name: refused";
  like $err // '', qr/the col/, "$name: the message names the column";
  like $err // '', qr/format/i, "$name: the message names the arrow format";
  unlike $err // '', qr/\Q$value\E/, "$name: the message carries no value";
  unlike $err // '', qr/duckdb_arrow_fetch.*duckdb_arrow_fetch/s, "$name: one prefix, not stacked ones";
}

# --- an SQL error throws, and the connection carries on ----------------------

throws_ok { $storage->duckdb_arrow_fetch('SELECT * FROM no_such_table_arrow') }
  qr/no_such_table_arrow/, 'an SQL error throws';
throws_ok { $storage->duckdb_arrow_fetch('SELEKT 1') } qr/syntax/i, 'a parse error throws';
throws_ok { $storage->duckdb_arrow_fetch() } qr/Usage|sql/i, 'no SQL throws';
is_deeply $storage->duckdb_arrow_fetch('SELECT 5 AS x')->{columns}, [ [5] ], 'usable after the errors';

# --- a column that is NULL throughout -----------------------------------------

{
  my $t = $storage->duckdb_arrow_fetch(q{SELECT NULL::INTEGER AS v, NULL::VARCHAR AS s, NULL::INTEGER[] AS l FROM range(3)});
  is_deeply $t->{columns}, [ [ (undef) x 3 ], [ (undef) x 3 ], [ (undef) x 3 ] ], 'columns of NULLs only';
  is $t->{rows}, 3, 'rows of NULLs only';
}

# --- a MAP key that is nested is refused, a scalar key works ----------------------

for my $c (
  [ 'LIST key',   q{MAP {[1]: 2}},                         '1' ],
  [ 'STRUCT key', q{MAP {{'a': 'secret-key-1'}: 2}},       'secret-key-1' ],
  [ 'MAP key',    q{MAP {MAP {'k': 'secret-key-2'}: 2}},   'secret-key-2' ],
  [ 'ARRAY key',  q{MAP {[7, 8]::INTEGER[2]: 2}},          '78' ],
  [ 'LIST key in a LIST of MAP', q{[MAP {['secret-key-3']: 2}]}, 'secret-key-3' ],
) {
  my ($name, $expr, $value) = @$c;
  my $err;
  eval { $storage->duckdb_arrow_fetch("SELECT 1 AS before, $expr AS \"the col\""); 1 } or $err = "$@";
  ok defined $err, "MAP with $name: refused";
  like $err // '', qr/the col/, "MAP with $name: the message names the column";
  like $err // '', qr/format/i, "MAP with $name: the message names the format";
  like $err // '', qr/key/i, "MAP with $name: the message names the key";
  unlike $err // '', qr/HASH\(|ARRAY\(/, "MAP with $name: no reference text";
}
is_deeply $storage->duckdb_arrow_fetch(q{SELECT MAP {1: 'a', 2: 'b'} AS m})->{columns}, [ [ { 1 => 'a', 2 => 'b' } ] ],
  'a MAP with scalar keys still works';

# --- decoders on arrays with an offset and a validity bitmap -------------------
# DuckDB hands out offset 0 whatever the query, so the offset of a slice is
# only exercised by an array built by hand.

{
  my @keep;
  my $bytes = sub {
    my $data = shift;
    my $p = calloc(1, length($data) || 1);
    my ($src) = scalar_to_buffer($data);
    memcpy($p, $src, length $data) if length $data;
    push @keep, $p;
    return $p;
  };
  my $schema = sub {
    my ($format, @kids) = @_;
    my $children = @kids ? $bytes->(pack 'Q*', @kids) : 0;
    return $bytes->(pack 'Q Q Q q q Q Q Q Q', $bytes->("$format\0"), $bytes->("c\0"), 0, 0, scalar @kids, $children, 0, 0, 0);
  };
  my $array = sub {
    my (%a) = @_;
    my @buffers  = @{ $a{buffers} };
    my @children = @{ $a{children} // [] };
    return $bytes->(pack 'q q q q q Q Q Q Q Q', $a{length}, $a{nulls} // 0, $a{offset} // 0,
      scalar @buffers, scalar @children, $bytes->(pack 'Q*', @buffers),
      (@children ? $bytes->(pack 'Q*', @children) : 0), 0, 0, 0);
  };
  my $bitmap = sub { $bytes->(pack 'b*', join '', map { $_ ? 1 : 0 } @_) };
  my $decode = sub {
    my ($schema_ptr, $array_ptr) = @_;
    return DBIO::DuckDB::Arrow::_plan($schema_ptr, undef, 'c')->{decode}->($array_ptr);
  };

  # the first physical values are different on purpose: a decoder that ignores
  # the offset would read them
  is_deeply $decode->($schema->('i'), $array->(
      length => 4, offset => 3, nulls => 2,
      buffers => [ $bitmap->(0, 0, 0, 1, 0, 1, 0, 1), $bytes->(pack 'l<*', 10 .. 19) ])),
    [ 13, undef, 15, undef ], 'integer with offset 3 and validity';

  is_deeply $decode->($schema->('l'), $array->(
      length => 3, offset => 5,
      buffers => [ 0, $bytes->(pack 'q<*', map { -$_ } 1 .. 9) ])),
    [ -6, -7, -8 ], 'bigint with offset 5, no validity';

  my $bools = $decode->($schema->('b'), $array->(
      length => 5, offset => 6, nulls => 1,
      buffers => [ $bitmap->((0) x 6, 1, 1, 0, 1, 1, 1), $bitmap->((1) x 6, 1, 0, 1, 1, 0, 0) ]));
  is_deeply [ map { defined $_ ? ($_ ? 1 : 0) : undef } @$bools ], [ 1, 0, undef, 1, 0 ],
    'bool with offset 6 (across a byte) and validity';

  my $data = "aab" . "cccc" . "\xc3\xa4\xc3\xb6";
  is_deeply $decode->($schema->('u'), $array->(
      length => 3, offset => 2, nulls => 1,
      buffers => [ $bitmap->(0, 0, 1, 0, 1), $bytes->(pack 'l<*', 0, 2, 3, 7, 7, 11), $bytes->($data) ])),
    [ 'cccc', undef, "\x{e4}\x{f6}" ], 'text with offset 2, an empty string, UTF-8 and validity';

  my $ints = $array->(length => 6, buffers => [ 0, $bytes->(pack 'l<*', 1 .. 6) ]);
  is_deeply $decode->($schema->('+l', $schema->('i')), $array->(
      length => 3, offset => 1, nulls => 1,
      buffers => [ $bitmap->(0, 1, 0, 1), $bytes->(pack 'l<*', 0, 2, 3, 6, 6) ],
      children => [ $ints ])),
    [ [3], undef, [] ], 'list with offset 1 and validity';

  # a MAP whose entry struct has an offset and a NULL entry
  my $keys   = $array->(length => 4, buffers => [ 0, $bytes->(pack 'l<*', 0, 1, 2, 3, 4), $bytes->('xabc') ]);
  my $values = $array->(length => 4, buffers => [ 0, $bytes->(pack 'l<*', 9, 1, 2, 3) ]);
  my $entries = $array->(length => 3, offset => 1, nulls => 1,
    buffers => [ $bitmap->(0, 1, 0, 1) ], children => [ $keys, $values ]);
  my $entry_schema = $schema->('+s', $schema->('u'), $schema->('i'));
  is_deeply $decode->($schema->('+m', $entry_schema), $array->(
      length => 2, buffers => [ 0, $bytes->(pack 'l<*', 0, 2, 3) ], children => [ $entries ])),
    [ { a => 1 }, { c => 3 } ], 'map: the offset and the validity of the entry struct count';

  FFI::Platypus::Memory::free($_) for @keep;
}

# --- an exception in the middle of a block frees everything ----------------------

{
  my $tmp  = File::Temp->newdir;
  my $file = "$tmp/mid-block.duckdb";
  my $s    = DBIO::DuckDB::Test->init_schema(
    no_populate => 1, no_deploy => 1, dsn => "dbi:DuckDB:dbname=$file",
  );
  my $st = $s->storage;
  $st->ensure_connected;
  my $sql = q{SELECT i AS a, 'v' || i AS b, [i] AS c, i * 1.5 AS d, i::HUGEINT AS e FROM range(5000) t(i)};
  my $orig = \&DBIO::DuckDB::Arrow::_array_head;

  for my $die_at (3, 20, 30) {
    my $calls = 0;
    {
      no warnings 'redefine';
      local *DBIO::DuckDB::Arrow::_array_head = sub {
        die "died in the decoder\n" if ++$calls == $die_at;
        goto &$orig;
      };
      throws_ok { $st->duckdb_arrow_fetch($sql) } qr/died in the decoder/,
        "an exception in call $die_at of the decoder is thrown";
    }
    is_deeply $st->duckdb_arrow_fetch('SELECT 5 AS x')->{columns}, [ [5] ], "usable after the exception ($die_at)";
    is $st->duckdb_arrow_fetch($sql)->{rows}, 5000, "a whole fetch works after the exception ($die_at)";
  }
  $st->disconnect;
  my $rc = system($^X, '-MDBI', '-e', $PROBE, $file);
  is $rc >> 8, 0, 'a second process opens the file after disconnect, though fetches died in a block';
}

# --- many calls: nothing is left lying around ----------------------------------

{
  my $ok = 1;
  for my $i (1 .. 300) {
    my $t = $storage->duckdb_arrow_fetch(
      q{SELECT i, 'v' || i AS s, [i] AS l FROM range(?::BIGINT) t(i)}, [ 2100 ]);
    $ok = 0 unless $t->{rows} == 2100 and $t->{columns}[1][2099] eq 'v2099';
    eval { $storage->duckdb_arrow_fetch(q{SELECT 1 AS a, '10'::BIT AS b}) };
  }
  ok $ok, '300 calls (two blocks each) with refusals between';
  is_deeply $dbh->selectall_arrayref('SELECT 1 + 1'), [ [2] ], 'the connection is usable after the loop';
}

# --- the database file is given back after disconnect ------------------------

{
  my $tmp  = File::Temp->newdir;
  my $file = "$tmp/arrow.duckdb";
  my $s    = DBIO::DuckDB::Test->init_schema(
    no_populate => 1, no_deploy => 1, dsn => "dbi:DuckDB:dbname=$file",
  );
  my $st = $s->storage;
  $st->ensure_connected;
  my $held = system($^X, '-MDBI', '-e', $PROBE, $file) >> 8;
  is $held, 3, 'baseline: a connected storage holds the file, a second process is refused';
  $st->duckdb_arrow_fetch(q{SELECT i, 'v' || i AS s FROM range(5000) t(i)}) for 1 .. 20;
  eval { $st->duckdb_arrow_fetch(q{SELECT '1'::BIT AS b}) };
  $st->duckdb_arrow_fetch(q{SELECT 1 AS a WHERE false});
  $s->storage->disconnect;

  my $rc = system($^X, '-MDBI', '-e', $PROBE, $file);
  is $rc >> 8, 0, 'a second process opens the file after disconnect';
}

done_testing;
