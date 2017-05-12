package Color::Similarity::RGB;

=head1 NAME

Color::Similarity::RGB - compute color similarity using the RGB color space

=head1 SYNOPSIS

  use Color::Similarity::RGB qw(distance rgb2rgb distance_rgb);
  # the greater the distance, more different the colors
  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

=head1 DESCRIPTION

Computes color similarity using the RGB color space and Euclidean
distance metric.

=cut

use strict;
use base qw(Exporter);

our $VERSION = '0.01';
our @EXPORT_OK = qw(rgb2rgb distance distance_rgb);

=head1 FUNCTIONS

=head2 distance

  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

Synonim for C<distance_rgb>, for consistency with other
C<Color::Similarity::*> modules.

=cut

*distance = \&distance_rgb;

=head2 rgb2rgb

  [ $r, $g, $b ] = rgb2rgb( $r, $g, $b );

Silly "conversion" function, for consistency with other
C<Color::Similarity::*> modules.

=cut

sub rgb2rgb {
    my( $r, $g, $b ) = @_;

    return [ $r, $g, $b ];
}

=head2 distance_rgb

  my $distance = distance_rgb( [ $r1, $g1, $b1 ], [ $r2, $b2, $b2 ] );

Computes the Euclidean distance between two colors in the RGB color space.

=cut

sub distance_rgb {
    my( $t1, $t2 ) = @_;
    my( $r1, $g1, $b1 ) = @$t1;
    my( $r2, $g2, $b2 ) = @$t2;

    return sqrt(   ( $r2 - $r1 ) ** 2
                 + ( $g2 - $g1 ) ** 2
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
    return { distance_rgb => \&distance_rgb,
             convert_rgb  => \&rgb2rgb,
             distance     => \&distance_rgb,
             };
}

1;
