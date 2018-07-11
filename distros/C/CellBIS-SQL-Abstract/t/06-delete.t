#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();

my $delete = $sql_abstract->delete(
  'table_test',
  {
    'where'   => 'table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ?',
    'orderby' => 'col1',
    'limit'   => '10'
  });
ok($delete eq 'DELETE FROM table_test WHERE table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ? '.
  'ORDER BY col1 LIMIT 10', "SQL Query [$delete] is true");

$delete = $sql_abstract->delete(
  'table_test',
  {
    'where'   => 'table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ?',
    'orderby' => 'col1'
  });
ok($delete eq 'DELETE FROM table_test WHERE table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ? '.
  'ORDER BY col1', "SQL Query [$delete] is true");

done_testing();

