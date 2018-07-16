#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $to_compare = '';
my $select_join = '';

$to_compare =
  'SELECT t1.first_name, t1.last_name, t2.company_name FROM my_users AS t1 '.
  'INNER JOIN my_companies AS t2 '.
  'ON t1.id = t2.id_company_users '.
  'WHERE t1.id = 2 AND t2.id_company_users = 1 ORDER BY t1.id DESC LIMIT 10';
$select_join = $sql_abstract->select_join(
  [
    { name => 'my_users', 'alias' => 't1', primary => 1 },
    { name => 'my_companies', 'alias' => 't2' }
  ],
  [
    't1.first_name',
    't1.last_name',
    't2.company_name',
  ],
  {
    'typejoin' => {
      'my_companies' => 'inner',
    },
    'join'     => [
      {
        name   => 'my_companies',
        onjoin => [
          't1.id', 't2.id_company_users',
        ]
      }
    ],
    'where'    => 't1.id = 2 AND t2.id_company_users = 1',
    'orderby'  => 't1.id',
    'order'    => 'desc', # asc || desc
    'limit'    => '10'
  }
);
ok($sql_abstract->to_one_liner($select_join) eq $to_compare, "SQL Query is true : \n$select_join");

done_testing();

1;
