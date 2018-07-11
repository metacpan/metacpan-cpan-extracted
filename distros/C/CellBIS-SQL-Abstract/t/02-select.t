#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();

my $select = $sql_abstract->select('table_test', []);
ok($select eq 'SELECT * FROM table_test', "SQL Query [$select] is true");

$select = $sql_abstract->select('table_test', [], {
  'orderby' => 'id_test',
  'order' => 'asc',
  'limit' => '5'
});
ok($select eq 'SELECT * FROM table_test ORDER BY id_test ASC LIMIT 5', "SQL Query [$select] is true");

$select = $sql_abstract->select('table_test', ['data'], {
  'groupby' => 'data',
  'orderby' => 'id_test',
  'order' => 'asc',
  'limit' => '5'
});
ok($select eq 'SELECT data FROM table_test GROUP BY data ORDER BY id_test ASC LIMIT 5', "SQL Query [$select] is true");

done_testing();
