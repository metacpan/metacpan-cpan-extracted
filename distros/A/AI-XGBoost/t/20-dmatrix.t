#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 6;

BEGIN {
    use_ok('AI::XGBoost::DMatrix');
}

{
    my $matrix = [ [ 1, 1 ] ];
    my $data = AI::XGBoost::DMatrix->FromMat( matrix => $matrix );
    is( $data->num_row, scalar @$matrix,          'DMatrix constructed has the right number of rows' );
    is( $data->num_col, scalar @{ $matrix->[0] }, 'DMatrix constructed has the right number of cols' );
    is_deeply( [ $data->dims ], [ 1, 2 ], 'DMatrix dim method returns correct dimensions' );
}

{
    my $matrix = [ map { [$_] } 0 .. 9 ];
    my $dmatrix = AI::XGBoost::DMatrix->FromMat( matrix => $matrix );
    my $sliced_matrix = $dmatrix->slice( [ map { $_ % 2 ? $_ : () } 0 .. 9 ] );
    is( $sliced_matrix->num_row, ( scalar @$matrix ) / 2, 'Sliced DMatrix has right number of rows' );
    is( $sliced_matrix->num_col, scalar @{ $matrix->[0] }, 'Sliced DMatrix has right number of cols' );
}
