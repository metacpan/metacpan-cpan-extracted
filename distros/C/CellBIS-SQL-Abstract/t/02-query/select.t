#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $to_compare = '';
my $select = '';

$to_compare = 'SELECT * FROM table_test';
$select = $sql_abstract->select('table_test', []);
ok($sql_abstract->to_one_liner($select) eq $to_compare, "SQL Query : \n$select");

$to_compare = 'SELECT * FROM table_test ORDER BY id_test ASC LIMIT 5';
$select = $sql_abstract->select('table_test', [], {
  'orderby' => 'id_test',
  'order' => 'asc',
  'limit' => '5'
});
ok($sql_abstract->to_one_liner($select) eq $to_compare, "SQL Query : \n$select");

$to_compare = 'SELECT data FROM table_test GROUP BY data ORDER BY id_test ASC LIMIT 5';
$select = $sql_abstract->select('table_test', ['data'], {
  'groupby' => 'data',
  'orderby' => 'id_test',
  'order' => 'asc',
  'limit' => '5'
});
ok($sql_abstract->to_one_liner($select) eq $to_compare, "SQL Query : \n$select");

done_testing();
