use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

# --- is_paged: thorough ---
{
  my $rs = $schema->resultset('CD');
  ok(!$rs->is_paged, 'plain RS is not paged');

  my $paged = $rs->search(undef, { page => 1, rows => 3 });
  ok($paged->is_paged, 'RS with page attr is paged');

  my $rows_only = $rs->search(undef, { rows => 5 });
  ok(!$rows_only->is_paged, 'RS with only rows is not paged');
}

# --- is_ordered: thorough ---
{
  my $rs = $schema->resultset('CD');
  ok(!$rs->is_ordered, 'plain RS is not ordered');

  my $ordered = $rs->order_by('title');
  ok($ordered->is_ordered, 'RS with order_by is ordered');

  my $desc = $rs->order_by({ -desc => 'year' });
  ok($desc->is_ordered, 'RS with desc order is ordered');
}

# --- has_rows ---
{
  ok($schema->resultset('CD')->has_rows, 'has_rows: CDs exist');
  ok(!$schema->resultset('CD')->search({ cdid => -999 })->has_rows,
    'has_rows: impossible condition returns false');

  # has_rows should be efficient (only fetch 1 row)
  my $rs = $schema->resultset('CD');
  ok($rs->has_rows, 'has_rows on full table');
}

# --- limit (alias for rows) ---
{
  my $rs = $schema->resultset('CD')->limit(2);
  isa_ok($rs, 'DBIO::ResultSet', 'limit returns RS');
  my @rows = $rs->all;
  is(scalar @rows, 2, 'limit(2) returns exactly 2 rows');

  my $single = $schema->resultset('CD')->limit(1);
  is(scalar($single->all), 1, 'limit(1) returns exactly 1 row');
}

# --- limited_page: two args ---
{
  my $rs = $schema->resultset('CD')->limited_page(1, 2);
  isa_ok($rs, 'DBIO::ResultSet', 'limited_page(page, rows) returns RS');
  my @rows = $rs->all;
  ok(@rows <= 2, 'limited_page(1,2) returns at most 2 rows');
  ok($rs->is_paged, 'limited_page creates a paged RS');
}

# --- limited_page: hashref ---
{
  my $rs = $schema->resultset('CD')->limited_page({ page => 2, rows => 2 });
  isa_ok($rs, 'DBIO::ResultSet', 'limited_page(hashref) returns RS');
  ok($rs->is_paged, 'limited_page hashref creates paged RS');
}

# --- limited_page: single arg (page only, must have rows already) ---
{
  my $rs = $schema->resultset('CD')->search(undef, { rows => 3 });
  my $paged = $rs->limited_page(2);
  isa_ok($paged, 'DBIO::ResultSet', 'limited_page(page) returns RS');
  ok($paged->is_paged, 'limited_page single arg creates paged RS');
}

# --- pagination: page 1 vs page 2 differ ---
{
  my $total = $schema->resultset('CD')->count;
  SKIP: {
    skip 'Need at least 3 CDs for pagination test', 2 unless $total >= 3;

    my $page1 = $schema->resultset('CD')->limited_page(1, 2);
    my $page2 = $schema->resultset('CD')->limited_page(2, 2);

    my @p1 = $page1->all;
    my @p2 = $page2->all;

    is(scalar @p1, 2, 'page 1 has 2 rows');
    ok(@p2 > 0, 'page 2 has rows');

    # Pages should have different rows
    my %p1_ids = map { $_->cdid => 1 } @p1;
    my @overlap = grep { $p1_ids{$_->cdid} } @p2;
    is(scalar @overlap, 0, 'page 1 and page 2 have no overlap');
  }
}

# --- me() ---
{
  my $rs = $schema->resultset('CD');
  is($rs->me, 'me.', 'me() returns source alias with dot');
  is($rs->me('title'), 'me.title', 'me(col) returns alias.col');

  my $aliased = $rs->search(undef, { alias => 'cds' });
  is($aliased->me, 'cds.', 'me() respects custom alias');
  is($aliased->me('year'), 'cds.year', 'me(col) with custom alias');
}

# --- distinct ---
{
  my $rs = $schema->resultset('CD')->distinct;
  isa_ok($rs, 'DBIO::ResultSet', 'distinct returns RS');
  my @rows = $rs->all;
  ok(@rows > 0, 'distinct query executes');

  # distinct(0) should turn off distinct
  my $nodist = $schema->resultset('CD')->distinct(0);
  isa_ok($nodist, 'DBIO::ResultSet', 'distinct(0) returns RS');
}

# --- group_by ---
{
  my $rs = $schema->resultset('CD')->search(undef, {
    columns => ['year'],
    group_by => 'year',
  });
  my @rows = $rs->hri->all;
  ok(@rows > 0, 'group_by returns rows');

  # Using the shortcut method
  my $grouped = $schema->resultset('CD')->columns(['year'])->group_by('year');
  my @g_rows = $grouped->hri->all;
  is(scalar @g_rows, scalar @rows, 'group_by shortcut matches manual');
}

# --- columns / add_columns ---
{
  my $rs = $schema->resultset('CD')->columns([qw/title year/]);
  my $row = $rs->hri->first;
  ok(exists $row->{title}, 'columns: has title');
  ok(exists $row->{year}, 'columns: has year');

  # columns() without args returns column list
  my @cols = $schema->resultset('CD')->columns;
  ok(@cols > 0, 'columns() without args returns column list');

  # add_columns
  my $plus = $schema->resultset('CD')->add_columns([{ doubled => \'year * 2' }]);
  isa_ok($plus, 'DBIO::ResultSet', 'add_columns returns RS');
}

# --- hri ---
{
  my $rs = $schema->resultset('CD')->hri;
  my $row = $rs->first;
  is(ref $row, 'HASH', 'hri returns hashref rows');
  ok(exists $row->{title}, 'hri hashref has title');
  ok(exists $row->{cdid}, 'hri hashref has cdid');
}

# --- prefetch ---
{
  my $rs = $schema->resultset('CD')->prefetch('artist');
  my $cd = $rs->first;
  ok($cd, 'prefetch returns a row');
  ok($cd->artist->name, 'prefetched artist accessible without extra query');

  # Multiple prefetches
  my $multi = $schema->resultset('CD')->prefetch('artist', 'tracks');
  isa_ok($multi, 'DBIO::ResultSet', 'prefetch with multiple rels returns RS');
}

# --- bare ---
{
  my $searched = $schema->resultset('CD')->search({ cdid => 1 });
  is($searched->count, 1, 'searched RS has 1 row');

  my $bare = $searched->bare;
  isa_ok($bare, 'DBIO::ResultSet', 'bare returns RS');
  ok($bare->count > 1, 'bare RS has all rows (no filters)');
}

# --- no_columns ---
{
  my $rs = $schema->resultset('CD')->no_columns->search(undef, {
    '+columns' => ['title'],
  });
  my $row = $rs->hri->first;
  ok(exists $row->{title}, 'no_columns + add title works');
  my @keys = keys %$row;
  is(scalar @keys, 1, 'no_columns: only selected column present');
}

# --- one_row ---
{
  my $cd = $schema->resultset('CD')->one_row;
  ok($cd, 'one_row returns a row');
  isa_ok($cd, 'DBIO::Row', 'one_row returns Row');

  my $with_cond = $schema->resultset('CD')->one_row({ cdid => 1 });
  ok($with_cond, 'one_row with condition works');
  is($with_cond->cdid, 1, 'one_row with condition returns correct row');

  my $none = $schema->resultset('CD')->one_row({ cdid => -1 });
  ok(!defined $none, 'one_row returns undef for no match');
}

# --- rand ---
{
  my $rs = $schema->resultset('CD')->rand;
  isa_ok($rs, 'DBIO::ResultSet', 'rand() returns RS');
  my @rows = $rs->all;
  is(scalar @rows, 1, 'rand() default returns 1 row');

  my $multi = $schema->resultset('CD')->rand(3);
  my @mrows = $multi->all;
  is(scalar @mrows, 3, 'rand(3) returns 3 rows');

  # Error cases
  throws_ok { $schema->resultset('CD')->rand(0) }
    qr/positive/, 'rand(0) throws';
  throws_ok { $schema->resultset('CD')->rand(-1) }
    qr/positive/, 'rand(-1) throws';
  throws_ok { $schema->resultset('CD')->rand(1.5) }
    qr/integer/, 'rand(1.5) throws';
}

done_testing;
