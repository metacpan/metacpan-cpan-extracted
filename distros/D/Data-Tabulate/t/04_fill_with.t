#!perl -T

use Data::Tabulate;
use Test::More tests => 2;

my @array = (1..4);
my $obj   = Data::Tabulate->new();
$obj->max_columns(3);
$obj->min_columns(3);
$obj->fill_with( 'hi' );
my @table = $obj->tabulate(@array);

my @check = (
               [1..3],
               [4, 'hi', 'hi'],
            );
is_deeply(\@table,\@check);
is( $table[1]->[2], 'hi' );
