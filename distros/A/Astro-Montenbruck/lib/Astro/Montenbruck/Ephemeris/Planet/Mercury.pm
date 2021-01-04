package Astro::Montenbruck::Ephemeris::Planet::Mercury;

use strict;
use warnings;

use Math::Trig qw/:pi/;
use base qw/Astro::Montenbruck::Ephemeris::Planet/;

use Astro::Montenbruck::Ephemeris::Pert qw /pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$ME/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $ME );
}

sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m1 = pi2 * frac( 0.4855407 + 415.2014314 * $t );
    my $m2 = pi2 * frac( 0.1394222 + 162.5490444 * $t );
    my $m3 = pi2 * frac( 0.9937861 + 99.9978139 * $t );
    my $m5 = pi2 * frac( 0.0558417 + 8.4298417 * $t );
    my $m6 = pi2 * frac( 0.8823333 + 3.3943333 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Keplerian motion and perturbations by Venus
    my $term = pert(
        T        => $t,
        M        => $m1,
        m        => $m2,
        I_min    => -1,
        I_max    => 9,
        i_min    => -5,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 1, 0, 0, 259.74,  84547.39, -78342.34, 0.01, 11683.22, 21203.79 );
    $term->( 1, 0, 1, 2.30,    5.04,     -7.52,     0.02, 138.55,   -71.01 );
    $term->( 1, 0, 2, 0.01,    -0.01,    0.01,      0.01, -0.19,    -0.54 );
    $term->( 2, 0, 0, -549.71, 10394.44, -7955.45,  0.00, 2390.29,  4306.79 );
    $term->( 2, 0, 1, -4.77,   8.97,     -1.53,     0.00, 28.49,    -14.18 );
    $term->( 2, 0, 2, 0.00,    0.00,     0.00,      0.00, -0.04,    -0.11 );
    $term->( 3, 0, 0, -234.04, 1748.74,  -1212.86,  0.00, 535.41,   984.33 );
    $term->( 3, 0, 1, -2.03,   3.48,     -0.35,     0.00, 6.56,     -2.91 );
    $term->( 4, 0, 0, -77.64,  332.63,   -219.23,   0.00, 124.40,   237.03 );
    $term->( 4, 0, 1, -0.70,   1.10,     -0.08,     0.00, 1.59,     -0.59 );
    $term->( 5, 0, 0, -23.59,  67.28,    -43.54,    0.00, 29.44,    58.77 );
    $term->( 5, 0, 1, -0.23,   0.32,     -0.02,     0.00, 0.39,     -0.11 );
    $term->( 6, 0, 0, -6.86,   14.06,    -9.18,     0.00, 7.03,     14.84 );
    $term->( 6, 0, 1, -0.07,   0.09,     -0.01,     0.00, 0.10,     -0.02 );
    $term->( 7, 0, 0, -1.94,   2.98,     -2.02,     0.00, 1.69,     3.80 );
    $term->( 8, 0, 0, -0.54,   0.63,     -0.46,     0.00, 0.41,     0.98 );
    $term->( 9, 0, 0, -0.15,   0.13,     -0.11,     0.00, 0.10,     0.25 );
    $term->( -1, -2, 0, -0.17, -0.06, -0.05, 0.14,  -0.06, -0.07 );
    $term->( 0,  -1, 0, 0.24,  -0.16, -0.11, -0.16, 0.04,  -0.01 );
    $term->( 0,  -2, 0, -0.68, -0.25, -0.26, 0.73,  -0.16, -0.18 );
    $term->( 0,  -5, 0, 0.37,  0.08,  0.06,  -0.28, 0.13,  0.12 );
    $term->( 1,  -1, 0, 0.58,  -0.41, 0.26,  0.36,  0.01,  -0.01 );
    $term->( 1,  -2, 0, -3.51, -1.23, 0.23,  -0.63, -0.05, -0.06 );
    $term->( 1,  -3, 0, 0.08,  0.53,  -0.11, 0.04,  0.02,  -0.09 );
    $term->( 1,  -5, 0, 1.44,  0.31,  0.30,  -1.39, 0.34,  0.29 );
    $term->( 2,  -1, 0, 0.15,  -0.11, 0.09,  0.12,  0.02,  -0.04 );
    $term->( 2,  -2, 0, -1.99, -0.68, 0.65,  -1.91, -0.20, 0.03 );
    $term->( 2,  -3, 0, -0.34, -1.28, 0.97,  -0.26, 0.03,  0.03 );
    $term->( 2,  -4, 0, -0.33, 0.35,  -0.13, -0.13, -0.01, 0.00 );
    $term->( 2,  -5, 0, 7.19,  1.56,  -0.05, 0.12,  0.06,  0.05 );
    $term->( 3,  -2, 0, -0.52, -0.18, 0.13,  -0.39, -0.16, 0.03 );
    $term->( 3,  -3, 0, -0.11, -0.42, 0.36,  -0.10, -0.05, -0.05 );
    $term->( 3,  -4, 0, -0.19, 0.22,  -0.23, -0.20, -0.01, 0.02 );
    $term->( 3,  -5, 0, 2.77,  0.49,  -0.45, 2.56,  0.40,  -0.12 );
    $term->( 4,  -5, 0, 0.67,  0.12,  -0.09, 0.47,  0.24,  -0.08 );
    $term->( 5,  -5, 0, 0.18,  0.03,  -0.02, 0.12,  0.09,  -0.03 );

    # Perturbations by the Earth
    $term = pert(
        T        => $t,
        M        => $m1,
        m        => $m3,
        I_min    => 0,
        I_max    => 2,
        i_min    => -4,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 0, -4, 0, -0.11, -0.07, -0.08, 0.11,  -0.02, -0.04 );
    $term->( 1, -1, 0, 0.10,  -0.20, 0.15,  0.07,  0.00,  0.00 );
    $term->( 1, -2, 0, -0.35, 0.28,  -0.13, -0.17, -0.01, 0.00 );
    $term->( 1, -4, 0, -0.67, -0.45, 0.00,  0.01,  -0.01, -0.01 );
    $term->( 2, -2, 0, -0.20, 0.16,  -0.16, -0.20, -0.01, 0.02 );
    $term->( 2, -3, 0, 0.13,  -0.02, 0.02,  0.14,  0.01,  0.00 );
    $term->( 2, -4, 0, -0.33, -0.18, 0.17,  -0.31, -0.04, 0.00 );

    # Perturbations by Mercury
    $term = pert(
        T        => $t,
        M        => $m1,
        m        => $m5,
        I_min    => -1,
        I_max    => 3,
        i_min    => -3,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( -1, -1, 0, -0.08, 0.16,  0.15,  0.08,  -0.04, 0.01 );
    $term->( -1, -2, 0, 0.10,  -0.06, -0.07, -0.12, 0.07,  -0.01 );
    $term->( 0,  -1, 0, -0.31, 0.48,  -0.02, 0.13,  -0.03, -0.02 );
    $term->( 0,  -2, 0, 0.42,  -0.26, -0.38, -0.50, 0.20,  -0.03 );
    $term->( 1,  -1, 0, -0.70, 0.01,  -0.02, -0.63, 0.00,  0.03 );
    $term->( 1,  -2, 0, 2.61,  -1.97, 1.74,  2.32,  0.01,  0.01 );
    $term->( 1,  -3, 0, 0.32,  -0.15, 0.13,  0.28,  0.00,  0.00 );
    $term->( 2,  -1, 0, -0.18, 0.01,  0.00,  -0.13, -0.03, 0.03 );
    $term->( 2,  -2, 0, 0.75,  -0.56, 0.45,  0.60,  0.08,  -0.17 );
    $term->( 3,  -2, 0, 0.20,  -0.15, 0.10,  0.14,  0.04,  -0.08 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m1,
        m        => $m6,
        I_min    => 1,
        I_max    => 1,
        i_min    => -2,
        i_max    => -2,
        callback => $pert_cb
    );

    $term->( 1, -2, 0, -0.19, 0.33, 0.0, 0.0, 0.0, 0.0 );
    $dl += 2.8 + 3.2 * $t;

    # Ecliptic coordinates ([rad],[AU])
    my $l =
      pi2 *
      frac( 0.2151379 + $m1 / pi2 +
          ( ( 5601.7 + 1.1 * $t ) * $t + $dl ) / 1296.0e3 );
    my $r = 0.3952829 + 0.0000016 * $t + $dr * 1.0e-6;
    my $b = ( -2522.15 + ( -30.18 + 0.04 * $t ) * $t + $db ) / ARCS;

    $l, $b, $r;
}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m = pi2 * frac( 0.4855407 + 415.2014314 * $t );
    my $dl =
      714.00 + 292.66 * cos($m) +
      71.96 * cos( 2 * $m ) +
      18.16 * cos( 3 * $m ) +
      4.61 * cos( 4 * $m ) +
      3.81 * sin( 2 * $m ) +
      2.43 * sin( 3 * $m ) +
      1.08 * sin( 4 * $m );

    my $dr = 55.94 * sin($m) + 11.36 * sin( 2 * $m ) + 2.60 * sin( 3 * $m );

    my $db =
      73.40 * cos($m) +
      29.82 * cos( 2 * $m ) +
      10.22 * cos( 3 * $m ) +
      3.28 * cos( 4 * $m ) -
      40.44 * sin($m) -
      16.55 * sin( 2 * $m ) -
      5.56 * sin( 3 * $m ) -
      1.72 * sin( 4 * $m );

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Mercury - Mercury.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Mercury;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Mercury->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Mercury> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Mercury->new

Constructor.

=head2 $self->heliocentric($t)

See description in L<Astro::Montenbruck::Ephemeris::Planet>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2020 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
