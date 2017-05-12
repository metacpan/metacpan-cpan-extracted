#!/usr/bin/perl 

use strict;
use warnings;

use Data::TableAutoSum;
use t'CommonStuff;
use Test::More;
use Test::Exception;

sub test_is_equal_same_dim {
    my ($table1, $table2) = map {Data::TableAutoSum->new(@_)} (1 .. 2);
    foreach my $row ($table1->rows) {
        foreach my $col ($table1->cols) {
            $table1->data($row,$col) = $table2->data($row,$col) = rand();
        }
    }
    ok $table1->is_equal($table2), 
       "After initialization with same values, both tables should be equal (@_)"
    or diag "Table 1:\n" . $table1->as_string,
            "Table 2:\n" . $table2->as_string;
                    
    all_ok {
        my $old_value = $table2->data(@_);
        $table2->data(@_) += 0.1;
        !$table1->is_equal($table2) or return 0;
        $table2->data(@_) = $old_value;
        $table1->is_equal($table2) or return 0;
    } [ [grep {defined} ($table1->rows())[0..5]],   # don't test everything
        [grep {defined} ($table2->cols())[0..5]] ], # as some tests make it plausible
    "Changing an element => !equal, rechanging => equal  (@_)";
}

sub test_is_equal_differ_dim {
    my $table    = Data::TableAutoSum->new(@_);
    my %arg = my %arg_long = my %arg_high = @_;
    $arg_long{cols} *= 2;
    my $table_long = Data::TableAutoSum->new(%arg_long);
    ok !$table->is_equal($table_long), "! table is_equal table long (@_)";
    ok !$table_long->is_equal($table), "! table_long is_equal table (@_)";

    $arg_high{rows} *= 2;
    my $table_high = Data::TableAutoSum->new(%arg_high);
    ok !$table->is_equal($table_high), "! table is_equal table high (@_)";
    ok !$table_long->is_equal($table), "! table_high is_equal table (@_)";
    
    $table->rows > 1 or $table->cols > 1 or return;
    ok !$table->is_equal(Data::TableAutoSum->new(rows => [reverse $table->rows],
                                                 cols => [reverse $table->cols])),
       "! equal with reversed rows and cols (@_)";                                          
}

use Test::More tests => 55;

foreach (STANDARD_DIM) {
    local @_ = (rows => $_->[0], cols => $_->[1]);
    &test_is_equal_same_dim;
    &test_is_equal_differ_dim;
    throws_ok { Data::TableAutoSum->new(@_)->is_equal(1) } 
              qr/parameter/i,
              "is_equal should throw a parameter exception when comparing to 1";
}
