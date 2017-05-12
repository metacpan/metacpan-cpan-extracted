#!perl -T

use Data::Tabulate;
use Test::More tests => 3;

my @array = (1..20);
my $obj   = Data::Tabulate->new();
$obj->max_columns(3);
my @table = $obj->tabulate(@array);

my @check = (
               [1..3],
               [4..6],
               [7..9],
               [10..12],
               [13..15],
               [16..18],
               [19..20,undef]
            );
is_deeply(\@table,\@check);
is($obj->cols,3);
is($obj->rows,7);
