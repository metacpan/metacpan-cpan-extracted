#!/usr/bin/perl -w

use strict;

use Data::TableAutoSum;
use List::Util qw/sum/;
use Test::More;
use Test::Exception;
use t'CommonStuff;

sub test_change {
    my $table = Data::TableAutoSum->new(@_);
    $table->change(sub {$_ = 42; "now the table describes the sense of life"});
    my $rows_x_cols = [[$table->rows], [$table->cols]];
    all_ok {$table->data(@_) == 42}
           $rows_x_cols,
           "After changing, table data should be 42 (@_)";
    $table->change(sub {$_ = round rand(); "quantum physics ?!"});
    my $sum = $table->totalresult;
    $table->change(sub {$_ = 1 - $_; "the world is turning around"});
    is round $table->totalresult, round( $table->rows * $table->cols - $sum ),
       "Taking the complement should yield the complement (@_)";
}

use Test::More tests => 2 * scalar(STANDARD_DIM) + 2;

test_change(rows => $_->[0], cols => $_->[1]) for STANDARD_DIM;

dies_ok { Data::TableAutoSum->new(rows => 2, cols => 2)->change }
        "should die: change called without any argument";

dies_ok { Data::TableAutoSum->new(rows => 2, cols => 2)->change("$_$_") }
        "should die: change called with a non sub-routine argument";        
