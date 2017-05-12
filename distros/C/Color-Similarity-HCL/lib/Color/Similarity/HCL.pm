package Color::Similarity::HCL;

=head1 NAME

Color::Similarity::HCL - compute color similarity using the HCL color space

=head1 SYNOPSIS

  use Color::Similarity::HCL qw(distance rgb2hcl distance_hcl);
  # the greater the distance, more different the colors
  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

=head1 DESCRIPTION

Computes color similarity using the color space and distance metric
defined in the research report:

HCL: a new Color Space for a more Effective Content-based Image
Retrieval

M. Sarifuddin <m.sarifuddin@uqo.ca> - Rokia Missaoui <rokia.missaoui@uqo.ca>
DE<eacute>partement d'informatique et d'ingE<eacute>nierie,
UniversitE<eacute> du QuE<eacute>bec en Outaouais
C.P. 1250, Succ. B Gatineau
QuE<eacute>ebec Canada, J8X 3X7

L<http://w3.uqo.ca/missaoui/Publications/TRColorSpace.zip>

=cut

use strict;
use base qw(Exporter);

our $VERSION = '0.05';
our @EXPORT_OK = qw(rgb2hcl distance distance_hcl);

use List::Util qw(max min);
use Math::Trig qw(pi rad2deg deg2rad atan);

use constant pip2   => pi / 2; # work around old Math::Trig
use constant Y0     => 100;
use constant gamma  => 3;
use constant Al     => 1.4456;
use constant Ah_inc => 0.16;

=head1 FUNCTIONS

=head2 distance

  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

Converts the colors to the HCL space and computes their distance.

=cut

sub distance {
    my( $t1, $t2 ) = @_;

    return distance_hcl( rgb2hcl( @$t1 ), rgb2hcl( @$t2 ) );
}

=head2 rgb2hcl

  [ $h, $c, $l ] = rgb2hcl( $r, $g, $b );

Converts between RGB and HCL color spaces.

=cut

sub _atan {
    my( $y, $x ) = @_;

    return $y < 0 ? - pip2 : pip2 if $x == 0;
    return atan( $y / $x );
}

sub rgb2hcl {
    my( $r, $g, $b ) = @_;

    my( $min, $max ) = ( min( $r, $g, $b ), max( $r, $g, $b ) );
    return [ 0, 0, 0 ] if $max == 0; # special-case black
    my $alpha = ( $min / $max ) / Y0;
    my $Q = exp( $alpha * gamma );

    my( $rg, $gb, $br ) = ( $r - $g, $g - $b, $b - $r );
    my $L = ( $Q * $max + ( 1 - $Q ) * $min ) / 2;
    my $C = $Q * ( abs( $rg ) + abs( $gb ) + abs( $br ) ) / 3;
    my $H = rad2deg( _atan( $gb, $rg ) );

    # The paper uses 180, not 90, but using 180 gives
    # red the same HCL value as green...
#   Alternative A
#    $H = 90 + $H         if $rg <  0 && $gb >= 0;
#    $H = $H - 90         if $rg <  0 && $gb <  0;
#   Alternative B
#    $H = 2 * $H / 3      if $rg >= 0 && $gb >= 0;
#    $H = 4 * $H / 3      if $rg >= 0 && $gb <  0;
#    $H = 90 + 4 * $H / 3 if $rg <  0 && $gb >= 0;
#    $H = 3 * $H / 4 - 90 if $rg <  0 && $gb <  0;
#   From http://w3.uqo.ca/missaoui/Publications/TRColorSpace.zip
    $H = 2 * $H / 3      if $rg >= 0 && $gb >= 0;
    $H = 4 * $H / 3      if $rg >= 0 && $gb <  0;
    $H = 180 + 4 * $H / 3 if $rg <  0 && $gb >= 0;
    $H = 2 * $H / 3 - 180 if $rg <  0 && $gb <  0;

    return [ $H, $C, $L ];
}

=head2 distance_hcl

  my $distance = distance_hcl( [ $h1, $c1, $l1 ], [ $h2, $c2, $l2 ] );

Computes the distance between two colors in the HCL color space.

=cut

sub distance_hcl {
    my( $t1, $t2 ) = @_;
    my( $h1, $c1, $l1 ) = @$t1;
    my( $h2, $c2, $l2 ) = @$t2;

    my $Ah = abs( $h1 - $h2 ) + Ah_inc;
    my( $Dl, $Dh ) = ( abs( $l1 - $l2 ), abs( $h1 - $h2 ) );
    # here it used to use <x> ** 2 to compute squares, but this causes
    # some rounding problems
    my $AlDl = Al * $Dl;
    return sqrt(   $AlDl * $AlDl
                 + $Ah * (   $c1 * $c1
                           + $c2 * $c2
                           - 2 * $c1 * $c2 * cos( deg2rad( $Dh ) )
                           )
                 );
}

=head1 SEE ALSO

L<http://w3.uqo.ca/missaoui/Publications/TRColorSpace.zip>

Corrected the RGB -> HCL transformation (see C<rgb2hcl>) as per the
research report by the same authors (thanks to David Hoerl for finding
the document with the corrected formula).

L<Color::Similarity>, L<Color::Similarity::RGB>, L<Color::Similarity::Lab>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

sub _vtable {
    return { distance_rgb => \&distance,
             convert_rgb  => \&rgb2hcl,
             distance     => \&distance_hcl,
             };
}

1;
