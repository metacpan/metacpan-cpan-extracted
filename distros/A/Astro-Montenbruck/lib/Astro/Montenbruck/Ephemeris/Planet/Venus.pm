package Astro::Montenbruck::Ephemeris::Planet::Venus;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Math::Trig qw/:pi/;

use Astro::Montenbruck::Ephemeris::Pert qw /pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$VE/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $VE );
}

# Venus heliocentric position
sub heliocentric {
    my ( $self, $t ) = @_;

    # mean anomalies of planets in [rad]
    my $m1 = pi2 * frac( 0.4861431 + 415.2018375 * $t );
    my $m2 = pi2 * frac( 0.1400197 + 162.5494552 * $t );
    my $m3 = pi2 * frac( 0.9944153 + 99.9982208 * $t );
    my $m4 = pi2 * frac( 0.0556297 + 53.1674631 * $t );
    my $m5 = pi2 * frac( 0.0567028 + 8.4305083 * $t );
    my $m6 = pi2 * frac( 0.8830539 + 3.3947206 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["]
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Perturbations by Mercury
    my $term = pert(
        T        => $t,
        M        => $m2,
        m        => $m1,
        I_min    => 1,
        I_max    => 5,
        i_min    => -2,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 1, -1, 0, 0.00,  0.00,  0.06,  -0.09, 0.01,  0.00 );
    $term->( 2, -1, 0, 0.25,  -0.09, -0.09, -0.27, 0.00,  0.00 );
    $term->( 4, -2, 0, -0.07, -0.08, -0.14, 0.14,  -0.01, -0.01 );
    $term->( 5, -2, 0, -0.35, 0.08,  0.02,  0.09,  0.00,  0.00 );

    # Keplerian motion and perturbations by the Earth
    $term = pert(
        T        => $t,
        M        => $m2,
        m        => $m3,
        I_min    => 1,
        I_max    => 8,
        i_min    => -8,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 1, 0,  0, 2.37,    2793.23, -4899.07, 0.11,   9995.27, 7027.22 );
    $term->( 1, 0,  1, 0.10,    -19.65,  34.40,    0.22,   64.95,   -86.10 );
    $term->( 1, 0,  2, 0.06,    0.04,    -0.07,    0.11,   -0.55,   -0.07 );
    $term->( 2, 0,  0, -170.42, 73.13,   -16.59,   0.00,   67.71,   47.56 );
    $term->( 2, 0,  1, 0.93,    2.91,    0.23,     0.00,   -0.03,   -0.92 );
    $term->( 3, 0,  0, -2.31,   0.90,    -0.08,    0.00,   0.04,    2.09 );
    $term->( 1, -1, 0, -2.38,   -4.27,   3.27,     -1.82,  0.00,    0.00 );
    $term->( 1, -2, 0, 0.09,    0.00,    -0.08,    0.05,   -0.02,   -0.25 );
    $term->( 2, -2, 0, -9.57,   -5.93,   8.57,     -13.83, -0.01,   -0.01 );
    $term->( 2, -3, 0, -2.47,   -2.40,   0.83,     -0.95,  0.16,    0.24 );
    $term->( 3, -2, 0, -0.09,   -0.05,   0.08,     -0.13,  -0.28,   0.12 );
    $term->( 3, -3, 0, 7.12,    0.32,    -0.62,    13.76,  -0.07,   0.01 );
    $term->( 3, -4, 0, -0.65,   -0.17,   0.18,     -0.73,  0.10,    0.05 );
    $term->( 3, -5, 0, -1.08,   -0.95,   -0.17,    0.22,   -0.03,   -0.03 );
    $term->( 4, -3, 0, 0.06,    0.00,    -0.01,    0.08,   0.14,    -0.18 );
    $term->( 4, -4, 0, 0.93,    -0.46,   1.06,     2.13,   -0.01,   0.01 );
    $term->( 4, -5, 0, -1.53,   0.38,    -0.64,    -2.54,  0.27,    0.00 );
    $term->( 4, -6, 0, -0.17,   -0.05,   0.03,     -0.11,  0.02,    0.00 );
    $term->( 5, -5, 0, 0.18,    -0.28,   0.71,     0.47,   -0.02,   0.04 );
    $term->( 5, -6, 0, 0.15,    -0.14,   0.30,     0.31,   -0.04,   0.03 );
    $term->( 5, -7, 0, -0.08,   0.02,    -0.03,    -0.11,  0.01,    0.00 );
    $term->( 5, -8, 0, -0.23,   0.00,    0.01,     -0.04,  0.00,    0.00 );
    $term->( 6, -6, 0, 0.01,    -0.14,   0.39,     0.04,   0.00,    -0.01 );
    $term->( 6, -7, 0, 0.02,    -0.05,   0.12,     0.04,   -0.01,   0.01 );
    $term->( 6, -8, 0, 0.10,    -0.10,   0.19,     0.19,   -0.02,   0.02 );
    $term->( 7, -7, 0, -0.03,   -0.06,   0.18,     -0.08,  0.00,    0.00 );
    $term->( 8, -8, 0, -0.03,   -0.02,   0.06,     -0.08,  0.00,    0.00 );

    # Perturbations by Mars
    $term = pert(
        T        => $t,
        M        => $m2,
        m        => $m4,
        I_min    => 1,
        I_max    => 2,
        i_min    => -3,
        i_max    => -2,
        callback => $pert_cb
    );

    $term->( 1, -3, 0, -0.65, 1.02, -0.04, -0.02, -0.02, 0.00 );
    $term->( 2, -2, 0, -0.05, 0.04, -0.09, -0.10, 0.00,  0.00 );
    $term->( 2, -3, 0, -0.50, 0.45, -0.79, -0.89, 0.01,  0.03 );

    # Perturbations by Venus
    $term = pert(
        T        => $t,
        M        => $m2,
        m        => $m5,
        I_min    => 0,
        I_max    => 3,
        i_min    => -3,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 0, -1, 0, -0.05, 1.56,  0.16,  0.04,  -0.08, -0.04 );
    $term->( 1, -1, 0, -2.62, 1.40,  -2.35, -4.40, 0.02,  0.03 );
    $term->( 1, -2, 0, -0.47, -0.08, 0.12,  -0.76, 0.04,  -0.18 );
    $term->( 2, -2, 0, -0.73, -0.51, 1.27,  -1.82, -0.01, 0.01 );
    $term->( 2, -3, 0, -0.14, -0.10, 0.25,  -0.34, 0.00,  0.00 );
    $term->( 3, -3, 0, -0.01, 0.04,  -0.11, -0.02, 0.00,  0.00 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m2,
        m        => $m6,
        I_min    => 0,
        I_max    => 1,
        i_min    => -1,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 0, -1, 0, 0.00,  0.21,  0.00, 0.00,  0.00, -0.01 );
    $term->( 1, -1, 0, -0.11, -0.14, 0.24, -0.20, 0.01, 0.00 );

    # Ecliptic coordinates ([rad],[AU])
    $dl +=
      +2.74 * sin( pi2 * ( 0.0764 + 0.4174 * $t ) ) +
      0.27 * sin( pi2 *  ( 0.9201 + 0.3307 * $t ) );
    $dl += +1.9 + 1.8 * $t;

    my $l =
      pi2 *
      frac( 0.3654783 + $m2 / pi2 +
          ( ( 5071.2 + 1.1 * $t ) * $t + $dl ) / 1296.0e3 );
    my $r = 0.7233482 - 0.0000002 * $t + $dr * 1.0e-6;
    my $b = ( -67.70 + ( 0.04 + 0.01 * $t ) * $t + $db ) / ARCS;

    $l, $b, $r;
}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m  = pi2 * frac( 0.1400197 + 162.5494552 * $t );
    my $dl = 280.00 + 3.79 * cos($m);
    my $dr = 1.37 * sin($m);
    my $db = 9.54 * cos($m) - 13.57 * sin($m);

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Venus - Venus.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Venus;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Venus->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Venus> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Venus->new

Constructor.

=head2 $self->heliocentric($t)

See description in L<Astro::Montenbruck::Ephemeris::Planet>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
