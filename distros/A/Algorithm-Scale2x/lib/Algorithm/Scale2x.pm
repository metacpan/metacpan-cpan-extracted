package Algorithm::Scale2x;

use strict;
use warnings;

use base qw( Exporter );

our $VERSION   = '0.04';
our @EXPORT_OK = qw( scale2x scale3x );

=head1 NAME

Algorithm::Scale2x - Generic implementation of the Scale2x algorithm

=head1 SYNOPSIS

    use Algorithm::Scale2x;

    # optionally exported
    # use Algorithm::Scale2x qw( scale2x scale3x );

    # To start, you must grab a pixel plus all 8 surrounding pixels
    my @pixels = $image->get_pixels( $x, $y ); 

    # scale2x - returns a 2x2 grid of scaled pixels
    my @result2x = Algorithm::Scale2x::scale2x( @pixels );

    # scale3x - returns a 3x3 grid of scaled pixels
    my @result3x = Algorithm::Scale2x::scale3x( @pixels );

=head1 DESCRIPTION

This module provides a generic implementation of the Scale2x and Scale3x algorithms.
Scale2x is described as:

    ...[a] real-time graphics effect able to increase the size of small bitmaps
    guessing the missing pixels without interpolating pixels and blurring the images.

=head1 METHODS

=head2 scale2x( @pixels )

Given a 3x3 grid of pixels (i.e color index numbers), it will expand the centre pixel
into 4 new pixels (i.e. 2x scale).

    +---+---+---+
    | 0 | 1 | 2 |    +----+----+
    +---+---+---+    | 4A | 4B |
    | 3 | 4 | 5 | => +----+----+
    +---+---+---+    | 4C | 4D |
    | 6 | 7 | 8 |    +----+----+
    +---+---+---+

=cut

sub scale2x {
    my @pixels = @_;
    my @E;

    if( $pixels[ 1 ] != $pixels[ 7 ] && $pixels[ 3 ] != $pixels[ 5 ] ) {
        $E[ 0 ] = ( $pixels[ 3 ] == $pixels[ 1 ] ? $pixels[ 3 ] : $pixels[ 4 ] );
        $E[ 1 ] = ( $pixels[ 1 ] == $pixels[ 5 ] ? $pixels[ 5 ] : $pixels[ 4 ] );
        $E[ 2 ] = ( $pixels[ 3 ] == $pixels[ 7 ] ? $pixels[ 3 ] : $pixels[ 4 ] );
        $E[ 3 ] = ( $pixels[ 7 ] == $pixels[ 5 ] ? $pixels[ 5 ] : $pixels[ 4 ] );
    }
    else {
        @E = ( $pixels[ 4 ] ) x 4;
    }

    return @E;
}

=head2 scale3x( @pixels )

Given a 3x3 grid of pixels (i.e color index numbers), it will expand the centre pixel
into 9 new pixels (i.e. 3x scale).

    +---+---+---+    +----+----+----+
    | 0 | 1 | 2 |    | 4A | 4B | 4C |
    +---+---+---+    +----+----+----+
    | 3 | 4 | 5 | => | 4D | 4E | 4F |
    +---+---+---+    +----+----+----+
    | 6 | 7 | 8 |    | 4G | 4H | 4I |
    +---+---+---+    +----+----+----+

=cut

sub scale3x {
    my @pixels = @_;
    my @E;

    if( $pixels[ 1 ] != $pixels[ 7 ] && $pixels[ 3 ] != $pixels[ 5 ] ) {
        $E[ 0 ] = ( $pixels[ 3 ] == $pixels[ 1 ] ? $pixels[ 3 ] : $pixels[ 4 ] );
        $E[ 1 ] = (
                ( $pixels[ 3 ] == $pixels[ 1 ] && $pixels[ 4 ] != $pixels[ 2 ] ) ||
                ( $pixels[ 1 ] == $pixels[ 5 ] && $pixels[ 4 ] != $pixels[ 0 ] )
                ? $pixels[ 1 ] : $pixels[ 4 ]
        );
        $E[ 2 ] = ( $pixels[ 1 ] == $pixels[ 5 ] ? $pixels[ 5 ] : $pixels[ 4 ] );
        $E[ 3 ] = (
                ( $pixels[ 3 ] == $pixels[ 1 ] && $pixels[ 4 ] != $pixels[ 6 ] ) ||
                ( $pixels[ 3 ] == $pixels[ 7 ] && $pixels[ 4 ] != $pixels[ 0 ] )
                ? $pixels[ 3 ] : $pixels[ 4 ]
        );
        $E[ 4 ] = $pixels[ 4 ];
        $E[ 5 ] = (
                ( $pixels[ 1 ] == $pixels[ 5 ] && $pixels[ 4 ] != $pixels[ 8 ] ) ||
                ( $pixels[ 7 ] == $pixels[ 5 ] && $pixels[ 4 ] != $pixels[ 2 ] )
                ? $pixels[ 5 ] : $pixels[ 4 ]
        );
        $E[ 6 ] = ( $pixels[ 3 ] == $pixels[ 7 ] ? $pixels[ 3 ] : $pixels[ 4 ] );
        $E[ 7 ] = (
                ( $pixels[ 3 ] == $pixels[ 7 ] && $pixels[ 4 ] != $pixels[ 8 ] ) ||
                ( $pixels[ 7 ] == $pixels[ 5 ] && $pixels[ 4 ] != $pixels[ 6 ] )
                ? $pixels[ 7 ] : $pixels[ 4 ]
        );
        $E[ 8 ] = ( $pixels[ 7 ] == $pixels[ 5 ] ? $pixels[ 5 ] : $pixels[ 4 ] );
    }
    else {
        @E = ( $pixels[ 4 ] ) x 9;
    }

    return @E;
}

=head1 SEE ALSO

=over 4 

=item * http://scale2x.sourceforge.net/

=item * http://scale2x.sourceforge.net/algorithm.html

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
