# t/58-dbd-decimal-reader-premise.t -- karr k49: the premise of
# DBIO::DuckDB::Storage::_duckdb_exact_decimals, held as a fact.
#
# DBD::DuckDB 0.16 reads a DECIMAL through a double and its HUGEINT reader
# subtracts 2**128 for every odd upper word. The storage replaces that reader
# for the versions measured. This file measures the DBD ALONE, in a child
# process that never loads the storage, and goes red the day the DBD reads
# these values right: then the replacement can be removed.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

my $script = <<'PERL';
use strict; use warnings; use DBI;
my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
my ($a) = $dbh->selectrow_array(q{SELECT CAST('1234567890123456.7890' AS DECIMAL(20,4))});
my ($b) = $dbh->selectrow_array(q{SELECT CAST('9999999999999999.9999' AS DECIMAL(20,4))});
print "$a\n$b\n";
PERL

open my $fh, '-|', $^X, (map { "-I$_" } @INC), '-e', $script or die "cannot run child: $!";
my ($tail, $odd) = map { chomp; $_ } <$fh>;
close $fh;

my $v = DBD::DuckDB->VERSION;

if ($tail eq '1234567890123456.7890' and $odd eq '9999999999999999.9999') {
  fail("DBD::DuckDB $v reads numeric(20,4) exactly now: remove "
     . "DBIO::DuckDB::Storage::_duckdb_exact_decimals and this file");
}
else {
  pass("DBD::DuckDB $v still misreads DECIMAL, so the exact reader is needed");
  isnt($tail, '1234567890123456.7890', "... through a double: got '$tail'");
  isnt($odd,  '9999999999999999.9999', "... and the hugeint word: got '$odd'");
}

done_testing;
