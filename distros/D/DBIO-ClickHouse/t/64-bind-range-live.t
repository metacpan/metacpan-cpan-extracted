use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/64-bind-range-live.t -- an integer outside the range of its column's type,
# against a live server (karr k43). The offline contract is t/63-bind-safety.t;
# this is the half only a server can answer:
#
#   1. the PREMISE: the server really does store NULL / a wrapped number for
#      such a value, without an error, and no session setting changes that. If
#      this ever turns red the server learned to throw and the driver's check
#      is redundant -- say so, do not quietly delete either side.
#   2. the driver's answer: the value is refused before it is sent, the row is
#      not written, and the edges of every range still go through and read back
#      as written.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

my $schema = DBIO::ClickHouse::Test->init_schema(no_populate => 1);
my $dbh    = $schema->storage->dbh;

# --- 1. the premise ------------------------------------------------------------

$dbh->do('CREATE TABLE range_probe (id Int32, n Nullable(UInt8), m UInt8) ENGINE = MergeTree ORDER BY id');
my $one = sub {
  my ($sql) = @_;
  my ($v) = $dbh->selectrow_array($sql);
  return $v;
};

$dbh->do('INSERT INTO range_probe (id, n, m) VALUES (?, ?, ?)', undef, 1, 300, 300);
is $one->('SELECT ifNull(toString(n), \'NULL\') FROM range_probe WHERE id = 1'), 'NULL',
  'the server stores NULL for 300 at a Nullable(UInt8), without an error';
is $one->('SELECT m FROM range_probe WHERE id = 1'), 300 % 256,
  'and 300 mod 256 at a UInt8, without an error';

for my $set (
  'input_format_null_as_default = 0',
  'input_format_values_interpret_expressions = 0',
  'input_format_values_accurate_types_of_literals = 0',
  'insert_null_as_default = 0',
) {
  my $ok = eval { $dbh->do("SET $set"); 1 };
  $dbh->do('INSERT INTO range_probe (id, n, m) VALUES (?, ?, ?)', undef, 2, 300, 1) if $ok;
  is $one->('SELECT ifNull(toString(n), \'NULL\') FROM range_probe WHERE id = 2'), 'NULL',
    "SET $set does not make the server refuse it"
    if $ok;
  $dbh->do('ALTER TABLE range_probe DELETE WHERE id = 2 SETTINGS mutations_sync = 1');
}

# --- 2. the driver's answer ----------------------------------------------------

my $rs = $schema->resultset('Probe');
my $sent = DBIO::ClickHouse::Test->probe_row;
my $n = 100;
my $before = $rs->count;

for my $case (
  [ i8  => 128 ], [ i8 => -129 ], [ i16 => 32768 ], [ i16 => '-32769' ],
  [ i64 => '9223372036854775808' ], [ u32 => '-1' ], [ u32 => '4294967296' ],
  [ u64 => '-1' ], [ u64 => '18446744073709551616' ],
) {
  my ($col, $value) = @$case;
  throws_ok { $rs->create({ %$sent, id => ++$n, $col => $value }) }
    qr/table dbio_test_probe, column \Q$col\E\b.*outside the range.*Nothing was sent/s,
    "$value at $col is refused, naming table and column";
}
is $rs->count, $before, 'no refused row was written';

for my $case (
  [ i8 => 127 ], [ i8 => -128 ], [ i16 => 32767 ], [ i64 => '9223372036854775807' ],
  [ u32 => 0 ], [ u32 => 4294967295 ], [ u64 => 0 ], [ u64 => '18446744073709551615' ],
) {
  my ($col, $value) = @$case;
  my $id = ++$n;
  lives_ok { $rs->create({ %$sent, id => $id, $col => $value }) } "$value at $col is accepted";
  is $rs->find($id)->get_column($col), $value, '... and read back as written';
}

done_testing;
