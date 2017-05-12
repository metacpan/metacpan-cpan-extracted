#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

sub num_jobs {

}

#by definition an atomic index

my $sep = "\t";

sub combination {
    my ($num_idx) = @_;

    #all vs all
    my $z = 1;
    print join( $sep, qw/z i j row col/ ), "\n";
    for ( my $i = 0; $i < $num_idx - 1; $i++ ) {
        for ( my $j = $i + 1; $j < $num_idx; $j++ ) {

            print join( $sep, $z, $i, $j );

            my ( $corrected_row, $corrected_col ) = position( $z, $num_idx );
            print $sep, join( $sep, $corrected_row, $corrected_col ), $sep;

            print "\n";
            $z++;
        }
    }

}

sub num_elements {
    my $i = shift;
    return ( ($i) * ( $i - 1 ) ) / 2;
}

sub position {
    my ( $elem_idx, $size ) = @_;

    #$size = number of rows = number of columns
    my $num_elements = num_elements($size);

    #the counting starts from 0 or 1, but we need the elements left (inverted)
    #since I assume the triangular matrix to be the function f(x) = x
    my $k = $num_elements - $elem_idx + 1;

    #here the integral of f(x) = x -> F(x) = 1/2 x^2 -> F(y) = sqrt(2x) with a small correction of 0.5
    my $raw_row = int( sqrt( 2 * $k ) - 0.5 );
    #-2 -> index corrections
    my $corrected_row = $size - $raw_row - 2;

    #now we have the row, time for the column
    my $inv_row       = $size - $corrected_row - 1;
    my $raw_col       = $num_elements - num_elements( $inv_row + 1 );
    my $corrected_col = $elem_idx - $raw_col + $corrected_row;

    return ( $corrected_row, $corrected_col );
}

combination(10);

