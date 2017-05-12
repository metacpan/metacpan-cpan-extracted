#!perl -T

use Data::Tabulate;
use Test::More tests => 12;

my @array = (1..12);
my $obj   = Data::Tabulate->new();
my @table = $obj->tabulate(@array);

my @check = (
               [1..3],
               [4..6],
               [7..9],
               [10..12],
            );
is_deeply(\@table,\@check);
is($obj->cols,3);
is($obj->rows,4);


@array = (1..16);
@check = (
           [1..4],
           [5..8],
           [9..12],
           [13..16],
         );
is_deeply([$obj->tabulate(@array)],[@check]);
is($obj->cols,4);
is($obj->rows,4);

@array = (1..10);
@check = (
            [1..3],
            [4..6],
            [7..9],
            [10,undef,undef],
         );
my @res = $obj->tabulate(@array);
is_deeply([@res],[@check]);
is($obj->rows,4);
is($obj->cols,3);

@array = (1);
@check = ([1]);
is_deeply([$obj->tabulate(@array)],[@check]);
is($obj->rows,1);
is($obj->cols,1);
