# t/74-hugeint-row-reader.t -- HUGEINT through the row path of the storage.
#
# DBD::DuckDB 0.16 subtracts 2**128 from a HUGEINT whose upper word tests true
# on `$upper & (1 << 64)`; before perl 5.24 that is `$upper & 1`, so a value
# with an odd upper word came back 2**128 too low (the largest HUGEINT as a
# negative number). The storage replaces the reader
# (DBIO::DuckDB::Storage::_duckdb_exact_hugeints); every value here is read
# through the storage's handle and compared with its decimal text.
use strict;
use warnings;
use Test::More;

use DBIO::DuckDB::Test;

my $schema = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $dbh    = $schema->storage->dbh;

my $max = '170141183460469231731687303715884105727';
my $min = '-170141183460469231731687303715884105728';

my @cases = (
  [ 'largest HUGEINT (upper word odd)'  => $max ],
  [ 'smallest HUGEINT'                  => $min ],
  [ '10**20 (upper word 5)'             => '100000000000000000000' ],
  [ '-10**20'                           => '-100000000000000000000' ],
  [ '2**64 (upper word 1)'              => '18446744073709551616' ],
  [ '2**64-1 (upper word 0)'            => '18446744073709551615' ],
  [ '-2**64'                            => '-18446744073709551616' ],
  [ '-1'                                => '-1' ],
  [ '0'                                 => '0' ],
  [ '1'                                 => '1' ],
);

for my $case (@cases) {
  my ($name, $want) = @$case;
  my ($got) = $dbh->selectrow_array("SELECT CAST('$want' AS HUGEINT)");
  is($got, $want, "HUGEINT $name");
}

my ($null) = $dbh->selectrow_array('SELECT CAST(NULL AS HUGEINT)');
ok(!defined $null, 'HUGEINT NULL');

# several rows in one result, stored in a table, odd and even upper words mixed
$dbh->do('CREATE TABLE hg (id INTEGER, v HUGEINT)');
my @vals = map { $_->[1] } @cases;
$dbh->do("INSERT INTO hg VALUES ($_, CAST('$vals[$_]' AS HUGEINT))") for 0 .. $#vals;
$dbh->do('INSERT INTO hg VALUES (99, NULL)');
my $rows = $dbh->selectall_arrayref('SELECT v FROM hg ORDER BY id');
is_deeply([ map { $_->[0] } @$rows ], [ @vals, undef ], 'a column of HUGEINT reads back whole');

# a wide DECIMAL is a HUGEINT inside; it reads its own bytes
my @decimals = (
  [ '99999999999999999999999999999999999999' => 'DECIMAL(38,0)' ],
  [ '-99999999999999999999999999999999999999' => 'DECIMAL(38,0)' ],
  [ '12345678901234567890123456.1234567890' => 'DECIMAL(38,10)' ],
  [ '-12345678901234567890123456.1234567890' => 'DECIMAL(38,10)' ],
  [ '9999999999999999.9999' => 'DECIMAL(20,4)' ],
);
for my $d (@decimals) {
  my ($want, $type) = @$d;
  my ($got) = $dbh->selectrow_array("SELECT CAST('$want' AS $type)");
  is($got, $want, "$type $want");
}

done_testing;
