#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $to_compare   = '';
my $delete       = '';

$to_compare
  = 'DELETE FROM table_test '
  . 'WHERE table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ? '
  . 'ORDER BY col1 LIMIT 10';
$delete = $sql_abstract->delete(
  'table_test',
  {
    'where' =>
      'table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ?',
    'orderby' => 'col1',
    'limit'   => '10'
  }
);
ok($sql_abstract->to_one_liner($delete) eq $to_compare,
  "SQL Query is true : \n[$delete]");

$to_compare
  = 'DELETE FROM table_test '
  . 'WHERE table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ? '
  . 'ORDER BY col1';
$delete = $sql_abstract->delete(
  'table_test',
  {
    'where' =>
      'table_test.col2 = ? AND table_test.col1 = ? OR table_test.col3 = ?',
    'orderby' => 'col1'
  }
);
ok($sql_abstract->to_one_liner($delete) eq $to_compare,
  "SQL Query is true : \n[$delete]");

done_testing();

