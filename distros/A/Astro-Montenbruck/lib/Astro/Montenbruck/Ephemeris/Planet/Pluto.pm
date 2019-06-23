package Astro::Montenbruck::Ephemeris::Planet::Pluto;

use strict;
use warnings;

use POSIX qw/atan/;
use Math::Trig qw/:pi deg2rad/;
use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Astro::Montenbruck::Ephemeris::Planet qw/$PL/;

use Astro::Montenbruck::Ephemeris::Pert qw/pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $PL );
}


sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m5 = pi2 * frac( 0.0565314 + 8.4302963 * $t );
    my $m6 = pi2 * frac( 0.8829867 + 3.3947688 * $t );
    my $m9 = pi2 * frac( 0.0385795 + 0.4026667 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Perturbations by Pluto
    my $term = pert(
        T        => $t,
        M        => $m9,
        m        => $m5,
        I_min    => 0,
        I_max    => 6,
        i_min    => -2,
        i_max    => 1,
        callback => $pert_cb
    );

    $term->( 1, 0, 0, 0.06, 100924.08, -960396.0, 15965.1, 51987.68, -24288.76 );
    $term->( 2, 0, 0, 3274.74, 17835.12, -118252.2, 3632.4, 12687.49, -6049.72 );
    $term->( 3, 0,  0, 1543.52, 4631.99, -21446.6, 1167.0, 3504.00, -1853.10 );
    $term->( 4, 0,  0, 688.99,  1227.08, -4823.4,  213.5,  1048.19, -648.26 );
    $term->( 5, 0,  0, 242.27,  415.93,  -1075.4,  140.6,  302.33,  -209.76 );
    $term->( 6, 0,  0, 138.41,  110.91,  -308.8,   -55.3,  109.52,  -93.82 );
    $term->( 3, -1, 0, -0.99,   5.06,    -25.6,    19.8,   1.26,    -1.96 );
    $term->( 2, -1, 0, 7.15,    5.61,    -96.7,    57.2,   1.64,    -2.16 );
    $term->( 1, -1, 0, 10.79,   23.13,   -390.4,   236.4,  -0.33,   0.86 );
    $term->( 0, 1,  0, -0.23,   4.43,    102.8,    63.2,   3.15,    0.34 );
    $term->( 1, 1,  0, -1.10,   -0.92,   11.8,     -2.3,   0.43,    0.14 );
    $term->( 2, 1,  0, 0.62,    0.84,    2.3,      0.7,    0.05,    -0.04 );
    $term->( 3, 1,  0, -0.38,   -0.45,   1.2,      -0.8,   0.04,    0.05 );
    $term->( 4, 1,  0, 0.17,    0.25,    0.0,      0.2,    -0.01,   -0.01 );
    $term->( 3, -2, 0, 0.06,    0.07,    -0.6,     0.3,    0.03,    -0.03 );
    $term->( 2, -2, 0, 0.13,    0.20,    -2.2,     1.5,    0.03,    -0.07 );
    $term->( 1, -2, 0, 0.32,    0.49,    -9.4,     5.7,    -0.01,   0.03 );
    $term->( 0, -2, 0, -0.04,   -0.07,   2.6,      -1.5,   0.07,    -0.02 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m9,
        m        => $m6,
        I_min    => 0,
        I_max    => 3,
        i_min    => -2,
        i_max    => 1,
        callback => $pert_cb
    );

    $term->( 1, -1, 0, -29.47, 75.97,  -106.4, -204.9, -40.71, -17.55 );
    $term->( 0, 1,  0, -13.88, 18.20,  42.6,   -46.1,  1.13,   0.43 );
    $term->( 1, 1,  0, 5.81,   -23.48, 15.0,   -6.8,   -7.48,  3.07 );
    $term->( 2, 1,  0, -10.27, 14.16,  -7.9,   0.4,    2.43,   -0.09 );
    $term->( 3, 1,  0, 6.86,   -10.66, 7.3,    -0.3,   -2.25,  0.69 );
    $term->( 2, -2, 0, 4.32,   2.00,   0.0,    -2.2,   -0.24,  0.12 );
    $term->( 1, -2, 0, -5.04,  -0.83,  -9.2,   -3.1,   0.79,   -0.24 );
    $term->( 0, -2, 0, 4.25,   2.48,   -5.9,   -3.3,   0.58,   0.02 );

    # Perturbations by Pluto and Saturn
    my $phi = ( $m5 - $m6 );
    my $c   = cos($phi);
    my $s   = sin($phi);
    $dl += -9.11 * $c + 0.12 * $s;
    $dr += -3.4 * $c - 3.3 * $s;
    $db += +0.81 * $c + 0.78 * $s;

    $phi = ( $m5 - $m6 + $m9 );
    $c   = cos($phi);
    $s   = sin($phi);
    $dl += +5.92 * $c + 0.25 * $s;
    $dr += +2.3 * $c - 3.8 * $s;
    $db += -0.67 * $c - 0.51 * $s;

    # Ecliptic coordinates ([rad],[AU])
    my $l = pi2 * frac( 0.6232469 + $m9 / pi2 + $dl / 1296.0E3 );
    my $r = 40.7247248 + $dr * 1.0E-5;
    my $b = deg2rad(-3.909434) + $db / ARCS;

    # Position vector; ecliptic and equinox of B1950.0
    ( $l, $b ) = _prec( $t, $l, $b );

    $l, $b, $r;
}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m = pi2 * frac( 0.0385795 + 0.4026667 * $t );
    my $dl =
      0.69 + 0.34 * cos($m) + 0.12 * cos( 2 * $m ) + 0.05 * cos( 3 * $m );
    my $dr = 6.66 * sin($m) + 1.64 * sin( 2 * $m );
    my $db = -0.08 * cos($m) - 0.17 * sin($m) - 0.09 * sin( 2 * $m );

    $dl, $db, $dr;
}

sub _prec {
    my ( $t, $l, $b ) = @_;

    my $d   = $t + 0.5;
    my $ppi = 3.044;

    my $pk = 2.28E-4 * $d;
    my $p  = ( 0.0243764 + 5.39E-6 * $d ) * $d;
    my $c1 = cos($pk);
    my $c2 = cos($b);
    my $c3 = cos( $ppi - $l );
    my $s1 = sin($pk);
    my $s2 = sin($b);
    my $s3 = sin( $ppi - $l );
    my $x  = $c2 * $c3;
    my $y  = $c1 * $c2 * $s3 - $s1 * $s2;
    my $z  = $s1 * $c2 * $s3 + $c1 * $s2;

    $b = atan( $z / sqrt( ( 1.0 - $z ) * ( 1.0 + $z ) ) );
    if ( $x > 0 ) {
        $l = pi2 * frac( ( $ppi + $p - atan( $y / $x ) ) / pi2 );
    }
    else {
        $l = pi2 * frac( ( $ppi + $p - atan( $y / $x ) ) / pi2 + 0.5 );
    }

    $l, $b;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Pluto - Pluto.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Pluto;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Pluto->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Pluto> position.

The coordinates are first calculated relative to the fixed ecliptic of 1950, and
then transformed to the equinox of date. This method is nesessary because of
the high inclination of Pluto's orbit.

=head1 CAVEATS

The routine is applicable only between years B<1890> and B<2100>.

  The reason for this is that the series expansion used was not derived from
  perturbation theory, but from a Fourier analysis of a numerically integrated
  ephemeris covering this period of time. Even a few years before 1890 or after
  2100, the errors in the calculated coordinates grow very sharply, reaqching
  values of more than 0.5 arc-degrees.

  — O.Montenbruck, Th.Pfleger "Astronomy on the Personal Computer"

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Pluto->new

Constructor.

=head2 $self->heliocentric($t)

See description in L<Astro::Montenbruck::Ephemeris::Planet>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
