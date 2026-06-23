use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

# --- count_literal basic ---
{
  my $count = $schema->resultset('CD')->count_literal('1 = 1');
  ok($count > 0, 'count_literal with always-true returns positive count');
  is($count, $schema->resultset('CD')->count, 'count_literal 1=1 matches total count');
}

# --- count_literal with condition ---
{
  my $count = $schema->resultset('CD')->count_literal('year = ?', 1999);
  ok(defined $count, 'count_literal with bind value returns defined count');
  is(
    $count,
    $schema->resultset('CD')->search({ year => 1999 })->count,
    'count_literal matches equivalent search count'
  );
}

# --- count_literal with impossible condition ---
{
  my $count = $schema->resultset('CD')->count_literal('1 = 0');
  is($count, 0, 'count_literal with always-false returns 0');
}

done_testing;
