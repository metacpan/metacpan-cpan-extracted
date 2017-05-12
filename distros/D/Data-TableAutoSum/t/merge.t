#!/usr/bin/perl 

use strict;
use warnings;

use Data::TableAutoSum;
use Test::More;
use t'CommonStuff;

sub test_merge {
    my %arg = @_;
    my (@table) = map {Data::TableAutoSum->new(%arg)} (1 .. 2);
    $_->change(sub {$_ = round rand}) for @table;
    my $sumtable = Data::TableAutoSum->merge(sub {shift() + shift()}, @table);
    all_ok {
        my $sum = $sumtable->data(@_);
        my $x   = $table[0]->data(@_);
        my $y   = $table[1]->data(@_);
        $sum == $x + $y or diag "$sum != ($x + $y == " . ($x+$y) . ")";
    } [ [$table[0]->rows], [$table[0]->cols] ],
      'Merged two tables with $a + $b' . "(" . substr(Dumper(\@_),0,50) .")";
}

sub test_wrong_size {
    my @size1 = @{ shift() };
    my @size2 = @{ shift() };
}

use Test::More tests => 2 * scalar(STANDARD_DIM) + 1;

foreach (STANDARD_DIM) {
    my %arg = (rows => $_->[0], cols => $_->[1]);
    test_merge(%arg);
    test_merge(rows => [_named_rows $_->[0]],
               cols => [_named_cols $_->[1]]);
}

all_dies_ok {
    Data::TableAutoSum->merge(
       sub {shift() + shift()},
       Data::TableAutoSum->new(rows => $_->[0]->[0], cols => $_->[0]->[1]),
       Data::TableAutoSum->new(rows => $_->[1]->[0], cols => $_->[1]->[1])
    );
}  [ [ [1, 1], [1, 2], [1, 1000], [2, 2], [2, 1000] ],
     [ [2, 1], [1, 1001], [1000, 1] ] ],
   "merging of different sized tables";
