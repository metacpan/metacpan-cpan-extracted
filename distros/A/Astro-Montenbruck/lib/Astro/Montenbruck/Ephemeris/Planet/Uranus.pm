package Astro::Montenbruck::Ephemeris::Planet::Uranus;

use strict;
use warnings;
use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Math::Trig qw/:pi/;
use Astro::Montenbruck::Ephemeris::Pert qw /pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$UR/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $UR );
}

sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m5 = pi2 * frac( 0.0564472 + 8.4302889 * $t );
    my $m6 = pi2 * frac( 0.8829611 + 3.3947583 * $t );
    my $m7 = pi2 * frac( 0.3967117 + 1.1902849 * $t );
    my $m8 = pi2 * frac( 0.7216833 + 0.6068528 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub {
        $dl += $_[0];
        $dr += $_[1];
        $db += $_[2];
    };

    # Perturbations by Uranus
    my $term = pert(
        T        => $t,
        M        => $m7,
        m        => $m5,
        I_min    => -1,
        I_max    => 3,
        i_min    => -2,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( -1, -1, 0, 0.0,   0.0,  -0.1,   1.7,    -0.1, 0.0 );
    $term->( 0,  -1, 0, 0.5,   -1.2, 18.9,   9.1,    -0.9, 0.1 );
    $term->( 1,  -1, 0, -21.2, 48.7, -455.5, -198.8, 0.0,  0.0 );
    $term->( 1,  -2, 0, -0.5,  1.2,  -10.9,  -4.8,   0.0,  0.0 );
    $term->( 2,  -1, 0, -1.3,  3.2,  -23.2,  -11.1,  0.3,  0.1 );
    $term->( 2,  -2, 0, -0.2,  0.2,  1.1,    1.5,    0.0,  0.0 );
    $term->( 3,  -1, 0, 0.0,   0.2,  -1.8,   0.4,    0.0,  0.0 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m7,
        m        => $m6,
        I_min    => 0,
        I_max    => 11,
        i_min    => -6,
        i_max    => 0,
        callback => $pert_cb
    );
    $term->( 0, -1, 0, 1.4,   -0.5,   -6.4,   9.0,    -0.4, -0.8 );
    $term->( 1, -1, 0, -18.6, -12.6,  36.7,   -336.8, 1.0,  0.3 );
    $term->( 1, -2, 0, -0.7,  -0.3,   0.5,    -7.5,   0.1,  0.0 );
    $term->( 2, -1, 0, 20.0,  -141.6, -587.1, -107.0, 3.1,  -0.8 );
    $term->( 2, -1, 1, 1.0,   1.4,    5.8,    -4.0,   0.0,  0.0 );
    $term->( 2, -2, 0, 1.6,   -3.8,   -35.6,  -16.0,  0.0,  0.0 );
    $term->( 3, -1, 0, 75.3,  -100.9, 128.9,  77.5,   -0.8, 0.1 );
    $term->( 3, -1, 1, 0.2,   1.8,    -1.9,   0.3,    0.0,  0.0 );
    $term->( 3, -2, 0, 2.3,   -1.3,   -9.5,   -17.9,  0.0,  0.1 );
    $term->( 3, -3, 0, -0.7,  -0.5,   -4.9,   6.8,    0.0,  0.0 );
    $term->( 4, -1, 0, 3.4,   -5.0,   21.6,   14.3,   -0.8, -0.5 );
    $term->( 4, -2, 0, 1.9,   0.1,    1.2,    -12.1,  0.0,  0.0 );
    $term->( 4, -3, 0, -0.1,  -0.4,   -3.9,   1.2,    0.0,  0.0 );
    $term->( 4, -4, 0, -0.2,  0.1,    1.6,    1.8,    0.0,  0.0 );
    $term->( 5, -1, 0, 0.2,   -0.3,   1.0,    0.6,    -0.1, 0.0 );
    $term->( 5, -2, 0, -2.2,  -2.2,   -7.7,   8.5,    0.0,  0.0 );
    $term->( 5, -3, 0, 0.1,   -0.2,   -1.4,   -0.4,   0.0,  0.0 );
    $term->( 5, -4, 0, -0.1,  0.0,    0.1,    1.2,    0.0,  0.0 );
    $term->( 6, -2, 0, -0.2,  -0.6,   1.4,    -0.7,   0.0,  0.0 );

    # Keplerian motion and perturbations by Neptune
    $term = pert(
        T        => $t,
        M        => $m7,
        m        => $m8,
        I_min    => -1,
        I_max    => 7,
        i_min    => -8,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 1,  0,  0, -78.1, 19518.1, -90718.2, -334.7, 2759.5, -311.9 );
    $term->( 1,  0,  1, -81.6, 107.7,   -497.4,   -379.5, -2.8,   -43.7 );
    $term->( 1,  0,  2, -6.6,  -3.1,    14.4,     -30.6,  -0.4,   -0.5 );
    $term->( 1,  0,  3, 0.0,   -0.5,    2.4,      0.0,    0.0,    0.0 );
    $term->( 2,  0,  0, -2.4,  586.1,   -2145.2,  -15.3,  130.6,  -14.3 );
    $term->( 2,  0,  1, -4.5,  6.6,     -24.2,    -17.8,  0.7,    -1.6 );
    $term->( 2,  0,  2, -0.4,  0.0,     0.1,      -1.4,   0.0,    0.0 );
    $term->( 3,  0,  0, 0.0,   24.5,    -76.2,    -0.6,   7.0,    -0.7 );
    $term->( 3,  0,  1, -0.2,  0.4,     -1.4,     -0.8,   0.1,    -0.1 );
    $term->( 4,  0,  0, 0.0,   1.1,     -3.0,     0.1,    0.4,    0.0 );
    $term->( -1, -1, 0, -0.2,  0.2,     0.7,      0.7,    -0.1,   0.0 );
    $term->( 0,  -1, 0, -2.8,  2.5,     8.7,      10.5,   -0.4,   -0.1 );
    $term->( 1,  -1, 0, -28.4, 20.3,    -51.4,    -72.0,  0.0,    0.0 );
    $term->( 1,  -2, 0, -0.6,  -0.1,    4.2,      -14.6,  0.2,    0.4 );
    $term->( 1,  -3, 0, 0.2,   0.5,     3.4,      -1.6,   -0.1,   0.1 );
    $term->( 2,  -1, 0, -1.8,  1.3,     -5.5,     -7.7,   0.0,    0.3 );
    $term->( 2,  -2, 0, 29.4,  10.2,    -29.0,    83.2,   0.0,    0.0 );
    $term->( 2,  -3, 0, 8.8,   17.8,    -41.9,    21.5,   -0.1,   -0.3 );
    $term->( 2,  -4, 0, 0.0,   0.1,     -2.1,     -0.9,   0.1,    0.0 );
    $term->( 3,  -2, 0, 1.5,   0.5,     -1.7,     5.1,    0.1,    -0.2 );
    $term->( 3,  -3, 0, 4.4,   14.6,    -84.3,    25.2,   0.1,    -0.1 );
    $term->( 3,  -4, 0, 2.4,   -4.5,    12.0,     6.2,    0.0,    0.0 );
    $term->( 3,  -5, 0, 2.9,   -0.9,    2.1,      6.2,    0.0,    0.0 );
    $term->( 4,  -3, 0, 0.3,   1.0,     -4.0,     1.1,    0.1,    -0.1 );
    $term->( 4,  -4, 0, 2.1,   -2.7,    17.9,     14.0,   0.0,    0.0 );
    $term->( 4,  -5, 0, 3.0,   -0.4,    2.3,      17.6,   -0.1,   -0.1 );
    $term->( 4,  -6, 0, -0.6,  -0.5,    1.1,      -1.6,   0.0,    0.0 );
    $term->( 5,  -4, 0, 0.2,   -0.2,    1.0,      0.8,    0.0,    0.0 );
    $term->( 5,  -5, 0, -0.9,  -0.1,    0.6,      -7.1,   0.0,    0.0 );
    $term->( 5,  -6, 0, -0.5,  -0.6,    3.8,      -3.6,   0.0,    0.0 );
    $term->( 5,  -7, 0, 0.0,   -0.5,    3.0,      0.1,    0.0,    0.0 );
    $term->( 6,  -6, 0, 0.2,   0.3,     -2.7,     1.6,    0.0,    0.0 );
    $term->( 6,  -7, 0, -0.1,  0.2,     -2.0,     -0.4,   0.0,    0.0 );
    $term->( 7,  -7, 0, 0.1,   -0.2,    1.3,      0.5,    0.0,    0.0 );
    $term->( 7,  -8, 0, 0.1,   0.0,     0.4,      0.9,    0.0,    0.0 );

    # Perturbations by Uranus and Uranus
    $term = pert(
        T        => $t,
        M        => $m7,
        m        => $m6,
        I_min    => -2,
        I_max    => 4,
        i_min    => -6,
        i_max    => -4,
        phi      => 2 * $m5,
        callback => $pert_cb
    );

    $term->( -2, -4, 0, -0.7, 0.4,  -1.5,  -2.5,  0.0, 0.0 );
    $term->( -1, -4, 0, -0.1, -0.1, -2.2,  1.0,   0.0, 0.0 );
    $term->( 1,  -5, 0, 0.1,  -0.4, 1.4,   0.2,   0.0, 0.0 );
    $term->( 1,  -6, 0, 0.4,  0.5,  -0.8,  -0.8,  0.0, 0.0 );
    $term->( 2,  -6, 0, 5.7,  6.3,  28.5,  -25.5, 0.0, 0.0 );
    $term->( 2,  -6, 1, 0.1,  -0.2, -1.1,  -0.6,  0.0, 0.0 );
    $term->( 3,  -6, 0, -1.4, 29.2, -11.4, 1.1,   0.0, 0.0 );
    $term->( 3,  -6, 1, 0.8,  -0.4, 0.2,   0.3,   0.0, 0.0 );
    $term->( 4,  -6, 0, 0.0,  1.3,  -6.0,  -0.1,  0.0, 0.0 );

    # Ecliptic coordinates ([rad],[AU])

    my $l =
      pi2 *
      frac( 0.4734843 + $m7 / pi2 +
          ( ( 5082.3 + 34.2 * $t ) * $t + $dl ) / 1296.0e3 );
    my $r = 19.211991 + ( -0.000333 - 0.000005 * $t ) * $t + $dr * 1.0e-5;
    my $b = ( -130.61 + ( -0.54 + 0.04 * $t ) * $t + $db ) / ARCS;

    $l, $b, $r;

}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m  = pi2 * frac( 0.3967117 + 1.1902849 * $t );
    my $sm = sin($m);
    my $dl = 2.05 + 0.19 * cos($m);
    my $dr = 1.86 * $sm;
    my $db = -0.03 * $sm;

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Uranus - Uranus.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Uranus;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Uranus->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Uranus> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Uranus->new

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
