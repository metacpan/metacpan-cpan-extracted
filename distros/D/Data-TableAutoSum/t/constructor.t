#!/usr/bin/perl -w

use strict;

use Data::TableAutoSum;
use Data::Dumper;
use List::Util qw/sum/;
use Test::More;
use t'CommonStuff;

sub test_construct_table {
    my %arg = @_;
    my $arg = substr Dumper(\%arg), 0, 50;
    my @row = ref($arg{rows}) ? @{$arg{rows}} : (0 .. $arg{rows}-1);
    my @col = ref($arg{cols}) ? @{$arg{cols}} : (0 .. $arg{cols}-1);
    my $table = Data::TableAutoSum->new(%arg);
    ok eq_array [$table->rows()], \@row, "rows after construction";
    ok eq_array [$table->cols()], \@col, "cols after construction";
    TEST_DIMENSION: {
        my $r = $table->rows;
        my $c = $table->cols;
        is scalar($table->rows), scalar(@row), 
           "nr of rows after construction ($arg)";
        is scalar($table->cols), scalar(@col), 
           "nr of cols after construction ($arg)";
    }
    all_ok {$table->data(@_) == 0}
           [[$table->rows], [$table->cols]],
           "data(row,col) == 0 after construction";
    all_ok {$table->rowresult(shift()) == 0}
           [$table->rows],
           "rowresult == 0 after construction";
    all_ok {$table->colresult(shift()) == 0}
           [$table->cols],
           "colresult == 0 after construction";
    is $table->totalresult, 0, "totalresult after construction";
}

use constant STANDARD_DIM_TESTS => 8 * scalar(STANDARD_DIM());
    
use constant WRONG_NEW_PARAMS => ({},
                                  {rows => 10},
                                  {cols => 10},
                                  {rows =>  0, cols => 10},
                                  {rows => 10, cols =>  0},
                                  {rows =>  0, cols =>  0},
                                  {10, 10},
                                  {rows => "ten", cols => "ten"},
                                  {rows => [qw/smth is a double double/], cols => 4},
                                  {cols => [qw/smth is a double double/], rows => 4},
                                  {rows => [],  cols => [1]},
                                  {rows => [1], cols => []},
                                  {rows => [],  cols => []}
                                 );
use constant WRONG_NEW_PARAMS_TESTS => scalar WRONG_NEW_PARAMS;

use Test::More tests => 2 * STANDARD_DIM_TESTS + WRONG_NEW_PARAMS_TESTS;
use Test::Exception;

test_construct_table(rows => $_->[0], cols => $_->[1]) for STANDARD_DIM;
test_construct_table(rows => [_named_rows $_->[0]], 
                     cols => [_named_cols $_->[1]]) for STANDARD_DIM;
foreach (WRONG_NEW_PARAMS) {
    dies_ok {Data::TableAutoSum->new(%$_)} 
            "should die: new(".(Dumper $_).")";
}
