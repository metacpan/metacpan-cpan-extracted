#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $to_compare = '';
my $insert = '';

$to_compare = 'INSERT INTO table_test(col1, col2, col3) VALUES(?, ?, NOW())';
$insert = $sql_abstract->insert('table_test', ['col1', 'col2', 'col3'], ['val1', 'val2', 'NOW()'], 'pre-st');
is($insert, $to_compare, "SQL Query : \n$insert");

$to_compare = 'INSERT INTO table_test(col1, col2, col3) VALUES(\'val1\', \'val2\', \'val3\')';
$insert = $sql_abstract->insert('table_test', ['col1', 'col2', 'col3'], ['val1', 'val2', 'val3']);
is($insert, $to_compare, "SQL Query : \n$insert");

done_testing();

