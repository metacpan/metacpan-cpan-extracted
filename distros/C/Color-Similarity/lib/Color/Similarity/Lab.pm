package Color::Similarity::Lab;

=head1 NAME

Color::Similarity::Lab - compute color similarity using the L*a*b* color space

=head1 SYNOPSIS

  use Color::Similarity::Lab qw(distance rgb2lab distance_lab);
  # the greater the distance, more different the colors
  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

=head1 DESCRIPTION

Computes color similarity using the L*a*b* color space and Euclidean
distance metric.

The RGB -> L*a*b* conversion is just a wrapper around
L<Graphics::ColorObject>.

=cut

use strict;
use base qw(Exporter);

our $VERSION = '0.01';
our @EXPORT_OK = qw(rgb2lab distance distance_lab);

use Graphics::ColorObject qw(RGB_to_Lab);

=head1 FUNCTIONS

=head2 distance

  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

Converts the colors to the L*a*b* space and computes their distance.

=cut

sub distance {
    my( $t1, $t2 ) = @_;

    return distance_lab( RGB_to_Lab( $t1 ), RGB_to_Lab( $t2 ) );
}

=head2 rgb2lab

  [ $l, $a, $b ] = rgb2lab( $r, $g, $b );

Converts between RGB and L*a*b* color spaces (using
L<Graphics::ColorObject>).

=cut

sub rgb2lab {
    my( $r, $g, $b ) = @_;

    return RGB_to_Lab( [ $r, $g, $b ] );
}

=head2 distance_lab

  my $distance = distance_lab( [ $l1, $a1, $b1 ], [ $l2, $a2, $b2 ] );

Computes the Euclidean distance between two colors in the L*a*b* color space.

=cut

sub distance_lab {
    my( $t1, $t2 ) = @_;
    my( $L1, $a1, $b1 ) = @$t1;
    my( $L2, $a2, $b2 ) = @$t2;

    return sqrt(   ( $L2 - $L1 ) ** 2
                 + ( $a2 - $a1 ) ** 2
                 + ( $b2 - $b1 ) ** 2 );
}

=head1 SEE ALSO

L<Color::Similarity>, L<Color::Similarity::RGB>, L<Color::Similarity::HCL>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

sub _vtable {
    return { distance_rgb => \&distance,
             convert_rgb  => \&rgb2lab,
             distance     => \&distance_lab,
             };
}

1;
