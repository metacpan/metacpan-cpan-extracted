package Astro::Montenbruck::NutEqu;

use strict;
use warnings;

use Exporter qw/import/;
use Math::Trig qw/:pi/;
use Astro::Montenbruck::MathUtils qw/frac ARCS polynome/;

our @EXPORT_OK = qw/mean2true obliquity deltas/;
our $VERSION = 0.01;

sub deltas {
    my $t    = shift;

    my $ls   = pi2 * frac( 0.993133 + 99.997306 * $t );    # mean anomaly Sun
    my $d    = pi2 * frac( 0.827362 + 1236.853087 * $t );  # diff. longitude Moon-Sun
    my $f    = pi2 * frac( 0.259089 + 1342.227826 * $t );  # mean argument of latitude
    my $n    = pi2 * frac( 0.347346 - 5.372447 * $t );     # longit. ascending node

    my $dpsi =
      ( -17.200 * sin($n) -
          1.319 * sin( 2 * ( $f - $d + $n ) ) -
          0.227 * sin( 2 * ( $f + $n ) ) +
          0.206 * sin( 2 * $n ) +
          0.143 * sin($ls) ) / ARCS;
    my $deps =
      ( +9.203 * cos($n) +
          0.574 * cos( 2 * ( $f - $d + $n ) ) +
          0.098 * cos( 2 * ( $f + $n ) ) -
          0.090 * cos( 2 * $n ) ) / ARCS;

    $dpsi, $deps
}

sub mean2true {
    my $t = shift;
    my ($dpsi, $deps) = deltas($t);
    my $eps  = 0.4090928 - 2.2696E-4 * $t; # obliquity of the ecliptic
    my $c  = $dpsi * cos($eps);
    my $s  = $dpsi * sin($eps);

    sub {
        my ($x, $y, $z) = @_;
        my $dx = -( $c * $y + $s * $z );
        my $dy =  ( $c * $x - $deps * $z );
        my $dz =  ( $s * $x + $deps * $y );

        $x + $dx, $y + $dy, $z + $dz
    }
}

sub obliquity {
    my $t = shift;
    23.43929111 - (46.815 + (0.00059 - 0.001813 * $t) * $t) * $t / 3600
}


1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet - Base class for a planet.

=head1 SYNOPSIS

 # given mean geocentric coordinates $x0, $y0, $z0,
 # transform them to apparent coordinates $x1, $y1, $z1
 my $func = nutequ( $t );
 ($x1, $y1, $z1) = $func->($x0, $y0, $z0); # true coordinates

=head1 DESCRIPTION

Base class for a planet. Designed to be extended. Used internally in
Astro::Montenbruck::Ephemeris modules. Subclasses must implement B<heliocentric>
method.

=head1 SUBROUTINES

=head2 deltas( $t )

Calculates the effects of nutation on the ecliptic longitude and on the
obliquity of the ecliptic with accuracy of about 1 arcsecond.
Given time in Julian centuries since J200, return delta-psi and delta-eps.

=head3 Arguments

=over

=item * B<$t> — time in Julian centuries since J2000: C<(JD-2451545.0)/36525.0>

=back

=head3 Returns

C<($delta_psi, $delta_eps)>, in arc-degrees.


=head2 mean2true( $t )

Returns function for transforming of mean to true coordinates.

=head3 Arguments

=over

=item * B<$t> — time in Julian centuries since J2000: C<(JD-2451545.0)/36525.0>

=back

=head3 Returns

Function which takes I<mean> ecliptic geocentric coordinates of the planet X, Y, Z
of a planet and returns I<true> coordinates, i.e. corrected for
L<nutation in ecliptic and obliquity>.

=head2 obliquity( $t )

Given time in Julian centuries since J200, return I<mean obliquity of the ecliptic>,
in arc-degrees.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
