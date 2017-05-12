use strict;
use warnings;

package Array::Split;

BEGIN {
    $Array::Split::VERSION = '1.103261';
}

# ABSTRACT: split an array into sub-arrays

use Sub::Exporter::Simple qw( split_by split_into );
use List::Util 'max';
use POSIX 'ceil';

sub split_by {
    my ( $split_size, @original ) = @_;

    $split_size = ceil max( $split_size, 1 );

    my @sub_arrays;
    for my $element ( @original ) {
        push @sub_arrays, [] if !@sub_arrays;
        push @sub_arrays, [] if @{ $sub_arrays[-1] } >= $split_size;

        push @{ $sub_arrays[-1] }, $element;
    }

    return @sub_arrays;
}

sub split_into {
    my ( $count, @original ) = @_;

    $count = max( $count, 1 );

    my $size = ceil @original / $count;

    return split_by( $size, @original );
}

1;

__END__

=pod

=head1 NAME

Array::Split - split an array into sub-arrays

=head1 VERSION

version 1.103261

=head1 SYNOPSIS

    use Array::Split qw( split_by split_into );

=head1 DESCRIPTION

This module offers functions to separate all the elements of one array into multiple arrays.

=head2 split_by ( $split_size, @original )

Splits up the original array into sub-arrays containing the contents of the original. Each sub-array's size is the same
or less than $split_size, with the last one usually being the one to have less if there are not enough elements in
@original.

=head2 split_into ( $count, @original )

Splits the given array into even-sized (as even as maths allow) sub-arrays. It tries to create as many sub-arrays as
$count indicates, but will return less if there are not enough elements in @original.

Returns a list of array references.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
