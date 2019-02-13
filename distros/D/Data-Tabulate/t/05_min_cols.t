#!/usr/bin/env perl

use Data::Tabulate;
use Test::More;

my @array = (1..20);
my $obj   = Data::Tabulate->new();

$obj->min_columns(4);
$obj->max_columns(5);

my @table = $obj->tabulate(@array);

my @check = (
               [1..4],
               [5..8],
               [9..12],
               [13..16],
               [17..20]
            );
is_deeply \@table,\@check;

is $obj->cols, 4;
is $obj->rows, 5;

is $obj->min_columns, 4;
is $obj->max_columns, 5;

$obj->min_columns('test');
$obj->max_columns('test');

is $obj->min_columns, 4;
is $obj->max_columns, 5;

$obj->max_columns(3);
is $obj->min_columns, 3;

done_testing();
