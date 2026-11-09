use strict;
use warnings;
use Test::More;

# Live (core k399, ADR 0080, ADR 0013): every pair of types that
# DBIO::Firebird::Diff::Column calls lossless keeps the stored values.
#
# `lossy` is false for these pairs, so an upgrade runs them without
# allow_destructive. A pair is on the list only if the values of a table that
# holds rows read back unchanged after the ALTER the diff writes; this file is
# that measurement, pair by pair, with the values at the ends of the ranges
# (smallint -32768 / 32767, integer -2^31 / 2^31-1, bigint -2^63 / 2^63-1).
#
# Skipped unless a DSN is provided (as t/15, t/28):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the table "k399_probe".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live lossless-pair test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Diff::Column;

my $dbh = DBI->connect($dsn, $user, $pass, {
  RaiseError => 0, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;

$dbh->do('DROP TABLE "k399_probe"');

# [ old ddl, new ddl, old info, new info, values (SQL literals) ]
my @probes = (
  [ 'smallint', 'integer',  { data_type => 'smallint' }, { data_type => 'integer' },
    [ '-32768', '0', '32767' ] ],
  [ 'smallint', 'bigint',   { data_type => 'smallint' }, { data_type => 'bigint' },
    [ '-32768', '0', '32767' ] ],
  [ 'smallint', 'int128',   { data_type => 'smallint' }, { data_type => 'int128' },
    [ '-32768', '0', '32767' ] ],
  [ 'integer', 'bigint',    { data_type => 'integer' }, { data_type => 'bigint' },
    [ '-2147483648', '0', '2147483647' ] ],
  [ 'integer', 'int128',    { data_type => 'integer' }, { data_type => 'int128' },
    [ '-2147483648', '0', '2147483647' ] ],
  [ 'bigint', 'int128',     { data_type => 'bigint' }, { data_type => 'int128' },
    [ '-9223372036854775807', '0', '9223372036854775807' ] ],
  [ 'smallint', 'double precision', { data_type => 'smallint' }, { data_type => 'double precision' },
    [ '-32768', '0', '32767' ], 'int' ],
  [ 'integer', 'double precision', { data_type => 'integer' }, { data_type => 'double precision' },
    [ '-2147483648', '0', '2147483647' ], 'int' ],
  [ 'date', 'timestamp',    { data_type => 'date' }, { data_type => 'timestamp' },
    [ q{'0001-01-01'}, q{'2026-10-30'}, q{'9999-12-31'} ], 'date' ],
  [ 'char(5)', 'varchar(5)', { data_type => 'char', size => 5 }, { data_type => 'varchar', size => 5 },
    [ q{'ab'}, q{'abcde'}, q{''} ], 'text' ],
  [ 'char(5)', 'varchar(9)', { data_type => 'char', size => 5 }, { data_type => 'varchar', size => 9 },
    [ q{'ab'}, q{'abcde'} ], 'padded' ],
  [ 'char(4) character set octets', 'varchar(4) character set octets',
    { data_type => 'binary', size => 4 }, { data_type => 'varbinary', size => 4 },
    [ q{x'00ff10aa'}, q{x'41424344'} ] ],
  [ 'varchar(10)', 'varchar(20)', { data_type => 'varchar', size => 10 }, { data_type => 'varchar', size => 20 },
    [ q{'ab'}, q{'abcdefghij'} ], 'text' ],
  [ 'numeric(9,2)', 'numeric(12,2)', { data_type => 'numeric', size => [ 9, 2 ] },
    { data_type => 'numeric', size => [ 12, 2 ] }, [ '-9999999.99', '0.01', '9999999.99' ] ],
);

# What the column holds, as the server renders it (so no DBD conversion is in
# the comparison).
sub read_back {
  my ($kind) = @_;
  my $expr = $kind && ($kind eq 'text' || $kind eq 'padded') ? q{'<' || "c" || '>'}
           : $kind && $kind eq 'int' ? q{CAST("c" AS BIGINT)}
           : $kind && $kind eq 'date' ? q{CAST(CAST("c" AS DATE) AS VARCHAR(40) CHARACTER SET NONE)}
           : q{CAST("c" AS VARCHAR(40) CHARACTER SET NONE)};
  my $rows = $dbh->selectcol_arrayref(qq{SELECT $expr FROM "k399_probe" ORDER BY "id"});
  return $rows;
}

sub isnt_deeply_values {
  my ($got, $was, $name) = @_;
  isnt join("\0", @$got), join("\0", @$was), $name;
}

for my $probe (@probes) {
  my ($from, $to, $old_info, $new_info, $values, $kind) = @$probe;
  my $label = "$from -> $to";

  my $op = DBIO::Firebird::Diff::Column->new(
    action => 'alter', table_name => 'k399_probe', column_name => 'c',
    old_info => { column_name => 'c', not_null => 0, %$old_info },
    new_info => { column_name => 'c', not_null => 0, %$new_info },
  );

  $dbh->do('DROP TABLE "k399_probe"');
  unless ($dbh->do(qq{CREATE TABLE "k399_probe" ("id" INTEGER NOT NULL, "c" $from)})) {
    SKIP: { skip "$label: the server has no such column (" . $dbh->errstr . ')', 2 }
    next;
  }

  my $n = 0;
  $dbh->do(qq{INSERT INTO "k399_probe" ("id", "c") VALUES (} . ++$n . ", $_)")
    or BAIL_OUT("cannot insert $_ into a $from column: " . $dbh->errstr)
    for @$values;

  my $before = read_back($kind);
  my $padded = $kind && $kind eq 'padded';
  ok $padded ? $op->lossy : !$op->lossy,
    $padded ? "$label: the driver calls it lossy" : "$label: the driver calls it lossless";

  my $sql = eval { $op->as_sql };
  my $ok  = defined $sql && $dbh->do($sql);
  ok $ok, "$label: the server takes the ALTER" or diag($@ || $dbh->errstr);
  if ($ok && $padded) {
    # the reason it is lossy: the server pads the stored value to the new length
    isnt_deeply_values(read_back($kind), $before, "$label: the server changes the stored value (padding)");
  }
  elsif ($ok) {
    is_deeply read_back($kind), $before, "$label: every value reads back unchanged";
  }
  if ($ok && $kind && $kind eq 'date') {
    my ($off) = $dbh->selectrow_array(
      q{SELECT COUNT(*) FROM "k399_probe" WHERE "c" <> CAST(CAST("c" AS DATE) AS TIMESTAMP)});
    is $off, 0, "$label: the date is the timestamp at midnight";
  }

  $dbh->do('DROP TABLE "k399_probe"');
}

$dbh->do('DROP TABLE "k399_probe"');
$dbh->disconnect;
done_testing;
