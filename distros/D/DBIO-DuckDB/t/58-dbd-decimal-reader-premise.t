# t/58-dbd-decimal-reader-premise.t -- karr k49: the premise of
# DBIO::DuckDB::Storage::_duckdb_exact_decimals, held as a fact.
#
# DBD::DuckDB 0.16 reads a DECIMAL over an NV (`$value / 10**$scale`), and its
# HUGEINT reader subtracts 2**128 for every odd upper word. 20 digits fit a
# __float128 (33-34 digits), so on a perl with that NV a DECIMAL(20,4) is read
# exactly and the premise would wrongly look gone; 38 digits fit no NV of any
# perl, hence DECIMAL(38,4). The storage replaces that reader for the versions
# measured. This file measures the DBD ALONE, in a child process that never
# loads the storage, and goes red the day the DBD reads these values right:
# then the replacement can be removed.
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use ChildPerl;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

my $script = <<'PERL';
use strict; use warnings; use DBI;
my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
my ($a) = $dbh->selectrow_array(q{SELECT CAST('9876543210987654321098765432109876.5432' AS DECIMAL(38,4))});
my ($b) = $dbh->selectrow_array(q{SELECT CAST('1111111111111111111111111111111111.1111' AS DECIMAL(38,4))});
print "$a\n$b\n";
PERL

my @lines  = capture_child_perl($script);
my $status = $?;
my $out    = join '', @lines;
my ($tail, $odd) = map { my $l = $_; chomp $l; $l } @lines;

my $v = DBD::DuckDB->VERSION;

# The premise is a measurement; a child that gave no two values measured
# nothing, and that is a failure, not a pass of either branch.
if ($status != 0 or @lines != 2 or !defined $tail or !defined $odd) {
  fail('the child process measured the DBD');
  diag("the child process ended with status $status and printed:\n" . (length $out ? $out : '(nothing)'));
}
elsif ($tail eq '9876543210987654321098765432109876.5432' and $odd eq '1111111111111111111111111111111111.1111') {
  fail("DBD::DuckDB $v reads numeric(38,4) exactly now: remove "
     . "DBIO::DuckDB::Storage::_duckdb_exact_decimals and this file");
}
else {
  pass("DBD::DuckDB $v still misreads DECIMAL, so the exact reader is needed");
  isnt($tail, '9876543210987654321098765432109876.5432', "... through an NV: got '$tail'");
  isnt($odd,  '1111111111111111111111111111111111.1111', "... and the hugeint word: got '$odd'");
}

done_testing;
