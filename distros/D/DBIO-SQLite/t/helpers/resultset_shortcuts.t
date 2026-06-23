use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Test that all shortcut methods work natively without load_components

# --- me ---
{
  my $rs = $schema->resultset('CD');
  is($rs->me, 'me.', 'me() returns current_source_alias with dot');
  is($rs->me('title'), 'me.title', 'me(col) returns alias.col');

  # With joined RS
  my $joined = $rs->search({}, { alias => 'cds' });
  is($joined->me, 'cds.', 'me() uses current_source_alias');
}

# --- order_by ---
{
  my $rs = $schema->resultset('CD');

  # Hash ref (standard)
  my $ordered = $rs->order_by({ -desc => 'title' });
  isa_ok($ordered, 'DBIO::ResultSet', 'order_by returns RS');
  my @cds = $ordered->all;
  ok(@cds > 0, 'order_by returned results');

  # Magic string - simple
  my $asc = $rs->order_by('title');
  isa_ok($asc, 'DBIO::ResultSet', 'magic order_by returns RS');

  # Magic string - DESC with !
  my $desc = $rs->order_by('!title');
  isa_ok($desc, 'DBIO::ResultSet', 'magic !order_by returns RS');

  # Magic string - comma separated
  my $multi = $rs->order_by('year,!title');
  isa_ok($multi, 'DBIO::ResultSet', 'magic comma order_by returns RS');
}

# --- distinct ---
{
  my $rs = $schema->resultset('CD')->distinct;
  isa_ok($rs, 'DBIO::ResultSet', 'distinct returns RS');
}

# --- group_by ---
{
  my $rs = $schema->resultset('CD')->group_by('year');
  isa_ok($rs, 'DBIO::ResultSet', 'group_by returns RS');
}

# --- columns ---
{
  my $rs = $schema->resultset('CD')->columns([qw/title year/]);
  isa_ok($rs, 'DBIO::ResultSet', 'columns returns RS');
  my $row = $rs->hri->first;
  ok(exists $row->{title}, 'columns includes title');
  ok(exists $row->{year}, 'columns includes year');
}

# --- add_columns ---
{
  my $rs = $schema->resultset('CD')->add_columns([{ double_year => \'year * 2' }]);
  isa_ok($rs, 'DBIO::ResultSet', 'add_columns returns RS');
}

# --- hri ---
{
  my $rs = $schema->resultset('CD')->hri;
  isa_ok($rs, 'DBIO::ResultSet', 'hri returns RS');
  my $row = $rs->first;
  is(ref $row, 'HASH', 'hri returns hashref');
  ok(exists $row->{title}, 'hri hashref has columns');
}

# --- rows / limit ---
{
  my $rs = $schema->resultset('CD')->rows(2);
  isa_ok($rs, 'DBIO::ResultSet', 'rows returns RS');
  my @all = $rs->all;
  is(scalar @all, 2, 'rows limits results');

  my $limited = $schema->resultset('CD')->limit(1);
  my @lim = $limited->all;
  is(scalar @lim, 1, 'limit is alias for rows');
}

# --- has_rows ---
{
  ok($schema->resultset('CD')->has_rows, 'has_rows returns true for non-empty RS');
  ok(!$schema->resultset('CD')->search({ cdid => -1 })->has_rows,
    'has_rows returns false for empty RS');
}

# --- page ---
{
  my $rs = $schema->resultset('CD')->rows(2)->page(1);
  isa_ok($rs, 'DBIO::ResultSet', 'page returns RS');
}

# --- limited_page ---
{
  my $rs = $schema->resultset('CD')->limited_page(1, 3);
  isa_ok($rs, 'DBIO::ResultSet', 'limited_page returns RS');
  my @all = $rs->all;
  ok(@all <= 3, 'limited_page limits rows');

  # Hash form
  my $rs2 = $schema->resultset('CD')->limited_page({ page => 1, rows => 2 });
  my @all2 = $rs2->all;
  ok(@all2 <= 2, 'limited_page hash form works');
}

# --- prefetch ---
{
  my $rs = $schema->resultset('CD')->prefetch('artist');
  isa_ok($rs, 'DBIO::ResultSet', 'prefetch returns RS');
  my $cd = $rs->first;
  ok($cd->artist->name, 'prefetch loaded relationship');
}

# --- remove_columns ---
{
  my $rs = $schema->resultset('CD')->remove_columns([qw/year/]);
  isa_ok($rs, 'DBIO::ResultSet', 'remove_columns returns RS');
}

# --- null / not_null ---
{
  # Test with nullable column
  my $all_count = $schema->resultset('Artist')->count;
  my $not_null = $schema->resultset('Artist')->not_null('name');
  isa_ok($not_null, 'DBIO::ResultSet', 'not_null returns RS');
  ok($not_null->count > 0, 'not_null finds rows');

  # With array ref
  my $multi = $schema->resultset('Artist')->not_null(['name']);
  isa_ok($multi, 'DBIO::ResultSet', 'not_null arrayref returns RS');
}

# --- like / not_like ---
{
  my $rs = $schema->resultset('CD')->like('title', '%Spoon%');
  isa_ok($rs, 'DBIO::ResultSet', 'like returns RS');

  my $not = $schema->resultset('CD')->not_like('title', '%Spoon%');
  isa_ok($not, 'DBIO::ResultSet', 'not_like returns RS');

  # Combined count should equal total
  my $total = $schema->resultset('CD')->count;
  is($rs->count + $not->count, $total, 'like + not_like = total');
}

# --- results_exist ---
{
  ok($schema->resultset('CD')->results_exist, 'results_exist returns true');
  ok(!$schema->resultset('CD')->search({ cdid => -1 })->results_exist,
    'results_exist returns false for empty RS');
}

# --- correlate ---
{
  my $artist_rs = $schema->resultset('Artist');
  my $with_cd_count = $artist_rs->search(undef, {
    '+columns' => {
      cd_count => $artist_rs->correlate('cds')->count_rs->as_query
    }
  });
  isa_ok($with_cd_count, 'DBIO::ResultSet', 'correlate works in subquery');
  my @rows = $with_cd_count->hri->all;
  ok(@rows > 0, 'correlate query returns rows');
  ok(exists $rows[0]->{cd_count}, 'correlated count column exists');
}

# --- search_or ---
{
  my $rs = $schema->resultset('CD');
  my $spoon = $rs->search({ title => { -like => '%Spoon%' } });
  my $fork  = $rs->search({ title => { -like => '%Fork%' } });
  my $combined = $rs->search_or([$spoon, $fork]);
  isa_ok($combined, 'DBIO::ResultSet', 'search_or returns RS');
}

# --- union ---
{
  my $rs = $schema->resultset('CD');
  my $rs1 = $rs->search({ year => 1999 })->hri;
  my $rs2 = $rs->search({ year => 2001 })->hri;
  my $union = $rs1->union($rs2);
  isa_ok($union, 'DBIO::ResultSet', 'union returns RS');
  my @all = $union->all;
  ok(@all >= 0, 'union query executes');
}

# --- chaining ---
{
  # The most important test: chaining multiple shortcuts
  my @rows = $schema->resultset('CD')
    ->columns([qw/title year/])
    ->order_by('!year')
    ->rows(3)
    ->hri
    ->all;

  is(scalar @rows, 3, 'chained shortcuts: got 3 rows');
  is(ref $rows[0], 'HASH', 'chained shortcuts: hri returned hashes');
  ok(exists $rows[0]->{title}, 'chained shortcuts: has title');
  ok(exists $rows[0]->{year}, 'chained shortcuts: has year');
}

# --- one_row ---
{
  my $cd = $schema->resultset('CD')->one_row;
  ok($cd, 'one_row returns a row');
  isa_ok($cd, 'DBIO::Row', 'one_row returns Row object');

  my $cd2 = $schema->resultset('CD')->one_row({ title => { -like => '%Spoon%' } });
  ok($cd2, 'one_row with condition returns a row');

  my $cd3 = $schema->resultset('CD')->one_row({ cdid => -1 });
  ok(!defined $cd3, 'one_row returns undef for no match');
}

# --- no_columns ---
{
  my $rs = $schema->resultset('CD')->no_columns->search(undef, {
    '+columns' => ['title'],
  });
  my $row = $rs->hri->first;
  ok(exists $row->{title}, 'no_columns + add title: has title');
  ok(!exists $row->{year}, 'no_columns + add title: no year');
}

# --- bare ---
{
  my $searched = $schema->resultset('CD')->search({ cdid => 1 });
  is($searched->count, 1, 'searched RS has 1 row');
  my $bare = $searched->bare;
  isa_ok($bare, 'DBIO::ResultSet', 'bare returns RS');
  ok($bare->count > 1, 'bare RS has all rows');
}

# --- rand ---
{
  my $rs = $schema->resultset('CD')->rand(2);
  isa_ok($rs, 'DBIO::ResultSet', 'rand returns RS');
  my @rows = $rs->all;
  is(scalar @rows, 2, 'rand(2) returns 2 rows');

  # Error cases
  throws_ok {
    $schema->resultset('CD')->rand(0)
  } qr/positive amount/, 'rand(0) throws';
  throws_ok {
    $schema->resultset('CD')->rand(1.5)
  } qr/integer amount/, 'rand(1.5) throws';
}

# --- explain ---
{
  my $plan = $schema->resultset('CD')->explain;
  is(ref $plan, 'ARRAY', 'explain returns arrayref');
  ok(@$plan > 0, 'explain returns query plan rows');
}

done_testing;
