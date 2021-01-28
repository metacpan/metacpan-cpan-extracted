#!/usr/bin/perl
use Mojo::Base -base;
use Test::More;

use Mojo::Util qw(dumper);
use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new();
my $to_compare   = '';
my $insert       = '';

$to_compare
  = "INSERT INTO table_test(col1, col2, col3) VALUES ('val1', 'val2', 'val3'), ('val11', 'val21', 'val31'), ('val12', 'val22', 'val32'), ('val13', 'val23', 'val33')";
$insert = $sql_abstract->insert_bulk(
  'table_test',
  ['col1', 'col2', 'col3'],
  [
    ['val1',  'val2',  'val3'],
    ['val11', 'val21', 'val31'],
    ['val12', 'val22', 'val32'],
    ['val13', 'val23', 'val33']
  ]
);
is $insert->[0], $to_compare, "SQL Query : \n$insert->[0]";

note 'with prepare statement';
my $value = [
  'val1',  'val2',  'val3',  'val11', 'val21', 'val31',
  'val12', 'val22', 'val32', 'val13', 'val23', 'val33'
];
$to_compare
  = "INSERT INTO table_test(col1, col2, col3) VALUES (?, ?, ?), (?, ?, ?), (?, ?, ?), (?, ?, ?)";
$insert = $sql_abstract->insert_bulk(
  'table_test',
  ['col1', 'col2', 'col3'],
  [
    ['val1',  'val2',  'val3'],
    ['val11', 'val21', 'val31'],
    ['val12', 'val22', 'val32'],
    ['val13', 'val23', 'val33']
  ],
  'pre-st'
);
is $insert->[0], $to_compare, "SQL Query : \n$insert->[0]";
my @inserting = @{$insert};
shift @inserting;
is_deeply $value => \@inserting, 'value ok';

done_testing();
