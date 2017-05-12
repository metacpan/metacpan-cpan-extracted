#!/usr/bin/perl -w

use strict;

use Data::TableAutoSum;
use List::Util qw/sum/;
use Test::More;
use Test::Exception;
use t'CommonStuff;

sub test_set_and_get_data {
    my $table = Data::TableAutoSum->new(@_);
    my $rows_x_cols = [[$table->rows], [$table->cols]];
    all_ok {$table->data(@_,"$_[0].$_[1]") == "$_[0].$_[1]"}
           $rows_x_cols,
           'data(row,col,$row.$col) == $row.$col';
    all_ok {$table->data(@_) == "$_[0].$_[1]"}
           $rows_x_cols,
           'data(row,col) == $row.$col';
    all_ok {
        my $value = $table->data(@_) = "$_[1].$_[0]";
        $value == "$_[1].$_[0]" and
        $value == $table->data(@_)
    } $rows_x_cols,
      'data(row,col) = $col.$row == $col.$row (lvalue assign)';
}

use constant OUT_OF_RANGE_VALUES => (-9999, -1, -0.5, 0.5, "one", 1_000_000);
sub test_out_of_range_exception {
    my %dim = @_;
    my $table = Data::TableAutoSum->new(%dim);
    my ($r, $c) = @dim{qw/rows cols/};
    my $good_row = int rand $table->rows;
    my $good_col = int rand $table->cols;
    
    all_dies_ok {$table->data(shift(),$good_col)}
                [OUT_OF_RANGE_VALUES, $r+1, 2*$r],
                "data(wrong, $good_col) for a $r x $c table";


    all_dies_ok {$table->data($good_row,shift())}
                [OUT_OF_RANGE_VALUES, $c+1, 2*$c],
                "data($good_row,wrong) for a $r x $c table";
}

use constant SET_AND_GET_TESTS  => 3 * 2 * scalar(STANDARD_DIM);
use constant OUT_OF_RANGE_TESTS => 2 * scalar(STANDARD_DIM);
    
use Test::More tests => SET_AND_GET_TESTS + OUT_OF_RANGE_TESTS;
foreach (STANDARD_DIM) {
    my %arg = (rows => $_->[0], cols => $_->[1]);
    test_set_and_get_data(%arg);
    test_set_and_get_data(rows => [_named_rows $_->[0]],
                          cols => [_named_cols $_->[1]]);
    test_out_of_range_exception(%arg);
}
