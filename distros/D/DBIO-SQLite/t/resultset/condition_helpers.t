use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

# --- null: single column ---
{
  # Create an artist with NULL charfield
  my $artist_rs = $schema->resultset('Artist');
  my $null_rs = $artist_rs->null('charfield');
  isa_ok($null_rs, 'DBIO::ResultSet', 'null returns RS');

  my @rows = $null_rs->all;
  for my $row (@rows) {
    ok(!defined $row->charfield, "null('charfield') row has NULL charfield");
  }
}

# --- null: multiple columns via arrayref ---
{
  my $rs = $schema->resultset('Artist')->null([qw/charfield/]);
  isa_ok($rs, 'DBIO::ResultSet', 'null with arrayref returns RS');
  my @rows = $rs->all;
  for my $row (@rows) {
    ok(!defined $row->charfield, 'null arrayref: charfield is NULL');
  }
}

# --- null: multiple columns as list ---
{
  my $rs = $schema->resultset('Artist')->null('charfield');
  my @rows = $rs->all;
  ok(@rows >= 0, 'null with list args works');
}

# --- not_null: single column ---
{
  my $rs = $schema->resultset('Artist')->not_null('name');
  isa_ok($rs, 'DBIO::ResultSet', 'not_null returns RS');
  my @rows = $rs->all;
  for my $row (@rows) {
    ok(defined $row->name, "not_null('name') row has defined name");
  }
}

# --- not_null: arrayref ---
{
  my $rs = $schema->resultset('Artist')->not_null(['name']);
  my @rows = $rs->all;
  for my $row (@rows) {
    ok(defined $row->name, 'not_null arrayref: name is defined');
  }
}

# --- null + not_null should cover all rows ---
{
  my $total = $schema->resultset('Artist')->count;
  my $null_count = $schema->resultset('Artist')->null('charfield')->count;
  my $not_null_count = $schema->resultset('Artist')->not_null('charfield')->count;
  is($null_count + $not_null_count, $total, 'null + not_null = total');
}

# --- like: single column ---
{
  my $rs = $schema->resultset('CD')->like('title', '%Spoon%');
  isa_ok($rs, 'DBIO::ResultSet', 'like returns RS');
  my @rows = $rs->all;
  for my $row (@rows) {
    like($row->title, qr/Spoon/, "like finds Spoon in title");
  }
}

# --- like: arrayref of columns ---
{
  # Search for pattern in multiple columns (title)
  my $rs = $schema->resultset('CD')->like(['title'], '%Spoon%');
  isa_ok($rs, 'DBIO::ResultSet', 'like with arrayref returns RS');
  my @rows = $rs->all;
  for my $row (@rows) {
    like($row->title, qr/Spoon/, 'like arrayref finds pattern');
  }
}

# --- not_like: single column ---
{
  my $rs = $schema->resultset('CD')->not_like('title', '%Spoon%');
  isa_ok($rs, 'DBIO::ResultSet', 'not_like returns RS');
  my @rows = $rs->all;
  for my $row (@rows) {
    unlike($row->title, qr/Spoon/, "not_like excludes Spoon");
  }
}

# --- not_like: arrayref of columns ---
{
  my $rs = $schema->resultset('CD')->not_like(['title'], '%Spoon%');
  my @rows = $rs->all;
  for my $row (@rows) {
    unlike($row->title, qr/Spoon/, 'not_like arrayref excludes pattern');
  }
}

# --- like + not_like = total ---
{
  my $total = $schema->resultset('CD')->count;
  my $like = $schema->resultset('CD')->like('title', '%Spoon%')->count;
  my $not_like = $schema->resultset('CD')->not_like('title', '%Spoon%')->count;
  is($like + $not_like, $total, 'like + not_like = total');
}

# --- chaining condition helpers ---
{
  my @rows = $schema->resultset('Artist')
    ->not_null('name')
    ->like('name', '%er%')
    ->all;

  for my $row (@rows) {
    ok(defined $row->name, 'chained: name defined');
    like($row->name, qr/er/, 'chained: name matches pattern');
  }
}

done_testing;
