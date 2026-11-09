use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $cd_rs = $schema->resultset('CD');

# intersect_all and except_all used to be SKIPped here, on a
# $storage->sqlt_type eq 'SQLite' comparison -- the driver-name match ADR 0021
# records as the anti-pattern this family of seams replaces -- and the skip's
# comment named a "< 3.39" boundary nobody had sourced. It was wrong: 3.39.0
# (2022-06-25) added RIGHT and FULL OUTER JOIN, not the ALL variants.
#
# The gap is not version-bounded at all. SQLite's compound operators are UNION,
# UNION ALL, INTERSECT and EXCEPT, with ALL attaching to UNION alone
# (sqlite.org/lang_select.html, "Compound Select Statements"); all four arrived
# together on 2000-06-06, before version 1.0, and the changelog through 3.53.4
# adds no INTERSECT ALL and no EXCEPT ALL. So there is no version on which
# these two blocks could have run, and the skip can become what it should have
# been: an assertion that the driver refuses them (karr k30, ADR 0039).

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

# --- intersect_all (refused: SQLite has no INTERSECT ALL) ---
{
  my $rs1 = $cd_rs->search({ year => 1999 })->hri;
  my $rs2 = $cd_rs->search({ year => { '>=' => 1997 } })->hri;

  my @sql;
  $schema->storage->debugcb(sub { push @sql, $_[1] });
  $schema->storage->debug(1);

  throws_ok
    { $rs1->intersect_all($rs2) }
    qr/\QSQLite has no INTERSECT ALL operator\E/,
    'intersect_all is refused by the driver instead of emitting an operator '
  . 'the engine does not have',
  ;

  $schema->storage->debug(0);
  $schema->storage->debugcb(undef);

  is (scalar @sql, 0, '... and it issued no SQL at all: the keyword is '
  . 'resolved before the first operand is rendered, so the refusal happens at '
  . 'query-build time (ADR 0039 section 4)')
    or diag explain \@sql;
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

# --- except_all (refused: SQLite has no EXCEPT ALL) ---
{
  my $all_hri = $cd_rs->hri;
  my $old = $cd_rs->search({ year => { '<' => 2000 } })->hri;

  throws_ok
    { $all_hri->except_all($old) }
    qr/\QSQLite has no EXCEPT ALL operator\E/,
    'except_all is refused too -- the same gap, and the same refusal',
  ;

  my $hint = '$rs->except';

  throws_ok
    { $all_hri->except_all($old) }
    qr/\Q$hint\E/,
    '... and the message names $rs->except as the nearest thing SQLite has '
  . 'while saying it is not equivalent: except removes duplicates, which is '
  . 'the whole difference the ALL variant was asked for. The block above '
  . 'proves except itself still works, so the refusal is about the missing '
  . 'operator and not about set difference',
  ;
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
