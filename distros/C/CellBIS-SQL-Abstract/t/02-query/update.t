#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $update       = '';
my $to_compare   = '';

# Prepare Statement
$to_compare
  = "UPDATE table_test SET clause_col1=?, col2=?, col3=? "
  . "WHERE clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ? "
  . "ORDER BY col1 ASC LIMIT 1";
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {
    'where'   => "clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ?",
    'orderby' => 'col1',
    'order' => 'asc',    # asc || desc
    'limit' => '1'
  },
  'pre-st'
);
is($sql_abstract->to_one_liner($update), $to_compare, "SQL Query : \n$update");

# No Prepare Statement
$to_compare
  = "UPDATE table_test SET clause_col1='val1', col2='val2', col3='val3' "
  . "WHERE clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3' "
  . "ORDER BY col1 ASC LIMIT 1";
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {
    'where' =>
      "clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3'",
    'orderby' => 'col1',
    'order'   => 'asc',    # asc || desc
    'limit'   => '1'
  }
);
is($sql_abstract->to_one_liner($update),
  $to_compare, "SQL Query No Prepare Statement: \n$update");


# Prepare Statement
$to_compare
  = 'UPDATE table_test SET clause_col1=?, col2=?, col3=? '
  . 'WHERE clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ? '
  . 'ORDER BY col1 ASC';
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {
    'where'   => 'clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ?',
    'orderby' => 'col1',
    'order' => 'asc',    # asc || desc
  },
  'pre-st'
);
is($sql_abstract->to_one_liner($update), $to_compare, "SQL Query : \n$update");

# No Prepare Statement
$to_compare
  = "UPDATE table_test SET clause_col1='val1', col2='val2', col3='val3' "
  . "WHERE clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3' "
  . 'ORDER BY col1 ASC';
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {
    'where' =>
      "clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3'",
    'orderby' => 'col1',
    'order'   => 'asc',    # asc || desc
  }
);
is($sql_abstract->to_one_liner($update), $to_compare, "SQL Query : \n$update");


# Prepare Statement
$to_compare = 'UPDATE table_test SET clause_col1=?, col2=?, col3=? '
  . 'WHERE clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ?';
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {'where' => 'clause_col1 = ? AND clause_col2 = ? OR clause_col3 = ?',},
  'pre-st'
);
is($sql_abstract->to_one_liner($update), $to_compare, "SQL Query : \n$update");

# No Prepare Statement
$to_compare
  = "UPDATE table_test SET clause_col1='val1', col2='val2', col3='val3' "
  . "WHERE clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3'";
$update = $sql_abstract->update(
  'table_test',
  ['clause_col1', 'col2', 'col3'],
  ['val1',        'val2', 'val3'],
  {
    'where' =>
      "clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3'",
  }
);
is($sql_abstract->to_one_liner($update),
  $to_compare, "SQL Query No Prepare Statement : \n$update");


# with 3 argument
$update = $sql_abstract->update(
  'table_test',
  {'clause_col1' => 'val1', 'col2' => 'val2', 'col3' => 'val3'},
  {
    'where' =>
      "clause_col1 = 'clause_val1' AND clause_col2 = 'clause_val2' OR clause_col3 = 'clause_val3'",
  }
);
like(
  $sql_abstract->to_one_liner($update),
  qr/UPDATE(.*)SET(.*)\=(.*)WHERE(.*)/,
  "SQL Query : \n$update"
);


done_testing();
