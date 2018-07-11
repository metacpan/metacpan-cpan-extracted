#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $select1 = $sql_abstract->select_join(
  [
    { name => 'table1', 'alias' => 't1', primary => 1 },
    { name => 'table2', 'alias' => 't2' }
  ],
  [
    't1.col1', 't1.col2',
    't2.col1', 't2.col2'
  ],
  {
    'typejoin' => {
      'table2' => 'inner',
    },
    'join'     => [
      {
        name   => 'table2',
        onjoin => [
          't1.col1', 't2.col2',
        ]
      }
    ],
    'where'    => 't2.col1 = ? AND t1.col2 = ?',
    'orderby'  => 't1.col1',
    'order'    => 'desc', # asc || desc
    'limit'    => '10'
  }
);
# print $select1;
ok($select1 eq 'SELECT t1.col1, t1.col2, t2.col1, t2.col2 FROM table1 AS t1 '.
  'INNER JOIN table2 AS t2 ON t1.col1 = t2.col2 WHERE t2.col1 = ? AND t1.col2 = ? '.
  'ORDER BY t1.col1 DESC LIMIT 10', "SQL Query [".substr($select1, 0, 100)."...] is true");

done_testing();

1;
