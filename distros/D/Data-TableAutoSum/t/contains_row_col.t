#!/usr/bin/perl

use strict;
use warnings;

use Data::TableAutoSum;
use Test::More;
use t'CommonStuff;
use List::Util qw/shuffle/;

sub test_contains_row_col {
    my ($rows, $cols) = @_;
    my @row = map {"$_" . rand() . "r"} (1 .. $rows);
    my @col = map {"$_" . rand() . "c"} (1 .. $cols);
    my $table = Data::TableAutoSum->new(rows => \@row, cols => \@col);
    
    @row = shuffle @row;
    @col = shuffle @col;
    
    all_ok { $table->contains_row(shift()) }
           \@row,
           "contains_row(...) should be true for all initialized rows";
           
    all_ok { ! $table->contains_row(shift()) }
           \@col,
           "contains_row(...) should be false for all initialized cols";

    all_ok { $table->contains_col(shift()) }
           \@col,
           "contains_row(...) should be true for all initialized rows";
           
    all_ok { ! $table->contains_col(shift()) }
           \@row,
           "contains_row(...) should be false for all initialized cols";
}

use Test::More tests => 4 * STANDARD_DIM();

test_contains_row_col(@$_) for STANDARD_DIM;
