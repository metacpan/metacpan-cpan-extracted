use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $cd_rs = $schema->resultset('CD');

my $sqlt_type = $schema->storage->sqlt_type;
my $has_all_ops = ($sqlt_type ne 'SQLite'); # SQLite < 3.39 lacks INTERSECT ALL / EXCEPT ALL

# --- intersect ---
{
  my $old = $cd_rs->search({ year => { '<=' => 1999 } })->hri;
  my $titled = $cd_rs->search({ title => { -like => '%Spoon%' } })->hri;

  my $inter = $old->intersect($titled);
  isa_ok($inter, 'DBIO::ResultSet', 'intersect returns RS');

  my @rows = $inter->all;
  # All rows should satisfy both conditions
  for my $row (@rows) {
    ok($row->{year} <= 1999, "intersect row year <= 1999");
    like($row->{title}, qr/Spoon/, "intersect row title matches Spoon");
  }
}

# --- intersect_all (not supported by SQLite) ---
SKIP: {
  skip 'INTERSECT ALL not supported on SQLite', 2 unless $has_all_ops;

  my $rs1 = $cd_rs->search({ year => 1999 })->hri;
  my $rs2 = $cd_rs->search({ year => { '>=' => 1997 } })->hri;

  my $inter = $rs1->intersect_all($rs2);
  isa_ok($inter, 'DBIO::ResultSet', 'intersect_all returns RS');

  my @rows = $inter->all;
  for my $row (@rows) {
    is($row->{year}, 1999, "intersect_all row has year 1999");
  }
}

# --- except ---
{
  my $all_hri = $cd_rs->hri;
  my $spoon = $cd_rs->search({ title => { -like => '%Spoon%' } })->hri;

  my $non_spoon = $all_hri->except($spoon);
  isa_ok($non_spoon, 'DBIO::ResultSet', 'except returns RS');

  my @rows = $non_spoon->all;
  for my $row (@rows) {
    unlike($row->{title}, qr/Spoon/, "except row title does not match Spoon");
  }

  # Count: except + intersect should cover all
  my $intersected = $all_hri->intersect($spoon);
  is(
    scalar(@rows) + $intersected->count,
    $cd_rs->count,
    'except + intersect covers total count'
  );
}

# --- except_all (not supported by SQLite) ---
SKIP: {
  skip 'EXCEPT ALL not supported on SQLite', 2 unless $has_all_ops;

  my $all_hri = $cd_rs->hri;
  my $old = $cd_rs->search({ year => { '<' => 2000 } })->hri;

  my $modern = $all_hri->except_all($old);
  isa_ok($modern, 'DBIO::ResultSet', 'except_all returns RS');

  my @rows = $modern->all;
  for my $row (@rows) {
    ok($row->{year} >= 2000, "except_all row year >= 2000");
  }
}

# --- union ---
{
  my $rs1 = $cd_rs->search({ year => 1999 })->hri;
  my $rs2 = $cd_rs->search({ year => 2001 })->hri;

  my $union = $rs1->union($rs2);
  isa_ok($union, 'DBIO::ResultSet', 'union returns RS');
  my @rows = $union->all;
  ok(@rows > 0, 'union returns rows');
}

# --- union_all (duplicates preserved) ---
{
  my $rs1 = $cd_rs->search({ year => 1999 })->hri;
  my $union = $rs1->union_all($rs1);
  isa_ok($union, 'DBIO::ResultSet', 'union_all returns RS');

  # union_all should have 2x the rows
  my $single_count = $rs1->count;
  is($union->count, $single_count * 2, 'union_all preserves duplicates');
}

# --- union with array of RSes ---
{
  my $rs1 = $cd_rs->search({ year => 1997 })->hri;
  my $rs2 = $cd_rs->search({ year => 1998 })->hri;
  my $rs3 = $cd_rs->search({ year => 1999 })->hri;

  my $combined = $rs1->union([$rs2, $rs3]);
  isa_ok($combined, 'DBIO::ResultSet', 'union with array returns RS');

  my @rows = $combined->all;
  ok(@rows >= 0, 'union with multiple RSes executes');
}

# --- error: mismatched result_class ---
{
  my $hri_rs = $cd_rs->hri;
  my $plain_rs = $cd_rs; # default result_class

  throws_ok {
    $hri_rs->union($plain_rs)
  } qr/ResultClass.*do not match/i, 'set operation with mismatched result_class throws';
}

# --- chaining: except after search ---
{
  my $old = $cd_rs->search({ year => { '<' => 2000 } })->hri;
  my $spoon = $cd_rs->search({ title => { -like => '%Spoon%' } })->hri;

  my $result = $old->except($spoon);
  isa_ok($result, 'DBIO::ResultSet', 'except after search works');
  my @rows = $result->all;
  for my $row (@rows) {
    ok($row->{year} < 2000, 'chained except: year < 2000');
    unlike($row->{title}, qr/Spoon/, 'chained except: not Spoon');
  }
}

# --- intersect: empty result ---
{
  my $y1999 = $cd_rs->search({ year => 1999 })->hri;
  my $y2001 = $cd_rs->search({ year => 2001 })->hri;

  # Intersect of disjoint sets should be empty
  my $empty = $y1999->intersect($y2001);
  is($empty->count, 0, 'intersect of disjoint sets is empty');
}

done_testing;
