package Astro::Montenbruck::Ephemeris::Planet::Saturn;

use strict;
use warnings;
use Math::Trig qw/:pi/;
use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Astro::Montenbruck::Ephemeris::Pert qw/pert/;
use Astro::Montenbruck::MathUtils qw/frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$SA/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $SA );
}

sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m5 = pi2 * frac( 0.0565314 + 8.4302963 * $t );
    my $m6 = pi2 * frac( 0.8829867 + 3.3947688 * $t );
    my $m7 = pi2 * frac( 0.3969537 + 1.1902586 * $t );
    my $m8 = pi2 * frac( 0.7208473 + 0.6068623 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Perturbations by Saturn
    my $term = pert(
        T        => $t,
        M        => $m6,
        m        => $m5,
        I_min    => 0,
        I_max    => 11,
        i_min    => -6,
        i_max    => 0,
        callback => $pert_cb
    );
    $term->( 0,  -1, 0, 12.0,    -1.4,    -13.9,    6.4,    1.2,     -1.8 );
    $term->( 0,  -2, 0, 0.0,     -0.2,    -0.9,     1.0,    0.0,     -0.1 );
    $term->( 1,  1,  0, 0.9,     0.4,     -1.8,     1.9,    0.2,     0.2 );
    $term->( 1,  0,  0, -348.3,  22907.7, -52915.5, -752.2, -3266.5, 8314.4 );
    $term->( 1,  0,  1, -225.2,  -146.2,  337.7,    -521.3, 79.6,    17.4 );
    $term->( 1,  0,  2, 1.3,     -1.4,    3.2,      2.9,    0.1,     -0.4 );
    $term->( 1,  -1, 0, -1.0,    -30.7,   108.6,    -815.0, -3.6,    -9.3 );
    $term->( 1,  -2, 0, -2.0,    -2.7,    -2.1,     -11.9,  -0.1,    -0.4 );
    $term->( 2,  1,  0, 0.1,     0.2,     -1.0,     0.3,    0.0,     0.0 );
    $term->( 2,  0,  0, 44.2,    724.0,   -1464.3,  -34.7,  -188.7,  459.1 );
    $term->( 2,  0,  1, -17.0,   -11.3,   18.9,     -28.6,  1.0,     -3.7 );
    $term->( 2,  -1, 0, -3.5,    -426.6,  -546.5,   -26.5,  -1.6,    -2.7 );
    $term->( 2,  -1, 1, 3.5,     -2.2,    -2.6,     -4.3,   0.0,     0.0 );
    $term->( 2,  -2, 0, 10.5,    -30.9,   -130.5,   -52.3,  -1.9,    0.2 );
    $term->( 2,  -3, 0, -0.2,    -0.4,    -1.2,     -0.1,   -0.1,    0.0 );
    $term->( 3,  0,  0, 6.5,     30.5,    -61.1,    0.4,    -11.6,   28.1 );
    $term->( 3,  0,  1, -1.2,    -0.7,    1.1,      -1.8,   -0.2,    -0.6 );
    $term->( 3,  -1, 0, 29.0,    -40.2,   98.2,     45.3,   3.2,     -9.4 );
    $term->( 3,  -1, 1, 0.6,     0.6,     -1.0,     1.3,    0.0,     0.0 );
    $term->( 3,  -2, 0, -27.0,   -21.1,   -68.5,    8.1,    -19.8,   5.4 );
    $term->( 3,  -2, 1, 0.9,     -0.5,    -0.4,     -2.0,   -0.1,    -0.8 );
    $term->( 3,  -3, 0, -5.4,    -4.1,    -19.1,    26.2,   -0.1,    -0.1 );
    $term->( 4,  0,  0, 0.6,     1.4,     -3.0,     -0.2,   -0.6,    1.6 );
    $term->( 4,  -1, 0, 1.5,     -2.5,    12.4,     4.7,    1.0,     -1.1 );
    $term->( 4,  -2, 0, -821.9,  -9.6,    -26.0,    1873.6, -70.5,   -4.4 );
    $term->( 4,  -2, 1, 4.1,     -21.9,   -50.3,    -9.9,   0.7,     -3.0 );
    $term->( 4,  -3, 0, -2.0,    -4.7,    -19.3,    8.2,    -0.1,    -0.3 );
    $term->( 4,  -4, 0, -1.5,    1.3,     6.5,      7.3,    0.0,     0.0 );
    $term->( 5,  -2, 0, -2627.6, -1277.3, 117.4,    -344.1, -13.8,   -4.3 );
    $term->( 5,  -2, 1, 63.0,    -98.6,   12.7,     6.7,    0.1,     -0.2 );
    $term->( 5,  -2, 2, 1.7,     1.2,     -0.2,     0.3,    0.0,     0.0 );
    $term->( 5,  -3, 0, 0.4,     -3.6,    -11.3,    -1.6,   0.0,     -0.3 );
    $term->( 5,  -4, 0, -1.4,    0.3,     1.5,      6.3,    -0.1,    0.0 );
    $term->( 5,  -5, 0, 0.3,     0.6,     3.0,      -1.7,   0.0,     0.0 );
    $term->( 6,  -2, 0, -146.7,  -73.7,   166.4,    -334.3, -43.6,   -46.7 );
    $term->( 6,  -2, 1, 5.2,     -6.8,    15.1,     11.4,   1.7,     -1.0 );
    $term->( 6,  -3, 0, 1.5,     -2.9,    -2.2,     -1.3,   0.1,     -0.1 );
    $term->( 6,  -4, 0, -0.7,    -0.2,    -0.7,     2.8,    0.0,     0.0 );
    $term->( 6,  -5, 0, 0.0,     0.5,     2.5,      -0.1,   0.0,     0.0 );
    $term->( 6,  -6, 0, 0.3,     -0.1,    -0.3,     -1.2,   0.0,     0.0 );
    $term->( 7,  -2, 0, -9.6,    -3.9,    9.6,      -18.6,  -4.7,    -5.3 );
    $term->( 7,  -2, 1, 0.4,     -0.5,    1.0,      0.9,    0.3,     -0.1 );
    $term->( 7,  -3, 0, 3.0,     5.3,     7.5,      -3.5,   0.0,     0.0 );
    $term->( 7,  -4, 0, 0.2,     0.4,     1.6,      -1.3,   0.0,     0.0 );
    $term->( 7,  -5, 0, -0.1,    0.2,     1.0,      0.5,    0.0,     0.0 );
    $term->( 7,  -6, 0, 0.2,     0.0,     0.2,      -1.0,   0.0,     0.0 );
    $term->( 8,  -2, 0, -0.7,    -0.2,    0.6,      -1.2,   -0.4,    -0.4 );
    $term->( 8,  -3, 0, 0.5,     1.0,     -2.0,     1.5,    0.1,     0.2 );
    $term->( 8,  -4, 0, 0.4,     1.3,     3.6,      -0.9,   0.0,     -0.1 );
    $term->( 9,  -4, 0, 4.0,     -8.7,    -19.9,    -9.9,   0.2,     -0.4 );
    $term->( 9,  -4, 1, 0.5,     0.3,     0.8,      -1.8,   0.0,     0.0 );
    $term->( 10, -4, 0, 21.3,    -16.8,   3.3,      3.3,    0.2,     -0.2 );
    $term->( 10, -4, 1, 1.0,     1.7,     -0.4,     0.4,    0.0,     0.0 );
    $term->( 11, -4, 0, 1.6,     -1.3,    3.0,      3.7,    0.8,     -0.2 );

    # Perturbations by Uranus
    $term = pert(
        T        => $t,
        M        => $m6,
        m        => $m7,
        I_min    => 0,
        I_max    => 3,
        i_min    => -5,
        i_max    => -1,
        callback => $pert_cb
    );
    $term->( 0, -1, 0, 1.0,   0.7,   0.4,   -1.5,  0.1,  0.0 );
    $term->( 0, -2, 0, 0.0,   -0.4,  -1.1,  0.1,   -0.1, -0.1 );
    $term->( 0, -3, 0, -0.9,  -1.2,  -2.7,  2.1,   -0.5, -0.3 );
    $term->( 1, -1, 0, 7.8,   -1.5,  2.3,   12.7,  0.0,  0.0 );
    $term->( 1, -2, 0, -1.1,  -8.1,  5.2,   -0.3,  -0.3, -0.3 );
    $term->( 1, -3, 0, -16.4, -21.0, -2.1,  0.0,   0.4,  0.0 );
    $term->( 2, -1, 0, 0.6,   -0.1,  0.1,   1.2,   0.1,  0.0 );
    $term->( 2, -2, 0, -4.9,  -11.7, 31.5,  -13.3, 0.0,  -0.2 );
    $term->( 2, -3, 0, 19.1,  10.0,  -22.1, 42.1,  0.1,  -1.1 );
    $term->( 2, -4, 0, 0.9,   -0.1,  0.1,   1.4,   0.0,  0.0 );
    $term->( 3, -2, 0, -0.4,  -0.9,  1.7,   -0.8,  0.0,  -0.3 );
    $term->( 3, -3, 0, 2.3,   0.0,   1.0,   5.7,   0.3,  0.3 );
    $term->( 3, -4, 0, 0.3,   -0.7,  2.0,   0.7,   0.0,  0.0 );
    $term->( 3, -5, 0, -0.1,  -0.4,  1.1,   -0.3,  0.0,  0.0 );

    # Perturbations by Neptune
    $term = pert(
        T        => $t,
        M        => $m6,
        m        => $m8,
        I_min    => 1,
        I_max    => 2,
        i_min    => -2,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 1, -1, 0, -1.3, -1.2, 2.3, -2.5, 0.0, 0.0 );
    $term->( 1, -2, 0, 1.0,  -0.1, 0.1, 1.4,  0.0, 0.0 );
    $term->( 2, -2, 0, 1.1,  -0.1, 0.2, 3.3,  0.0, 0.0 );

    # Perturbations by Saturn and Uranus
    my $phi = ( -2 * $m5 + 5 * $m6 - 3 * $m7 );
    my $c   = cos($phi);
    my $s   = sin($phi);

    $dl += -0.8 * $c - 0.1 * $s;
    $dr += -0.2 * $c + 1.8 * $s;
    $db += +0.3 * $c + 0.5 * $s;

    $phi = ( -2 * $m5 + 6 * $m6 - 3 * $m7 );
    $c   = cos($phi);
    $s   = sin($phi);
    $dl += ( +2.4 - 0.7 * $t ) * $c + ( 27.8 - 0.4 * $t ) * $s;
    $dr += +2.1 * $c - 0.2 * $s;

    $phi = ( -2 * $m5 + 7 * $m6 - 3 * $m7 );
    $c   = cos($phi);
    $s   = sin($phi);
    $dl += +0.1 * $c + 1.6 * $s;
    $dr += -3.6 * $c + 0.3 * $s;
    $db += -0.2 * $c + 0.6 * $s;

    # Ecliptic coordinates ([rad],[AU])
    my $l =
      pi2 *
      frac( 0.2561136 + $m6 / pi2 +
          ( ( 5018.6 + $t * 1.9 ) * $t + $dl ) / 1296.0e3 );
    my $r = 9.557584 - 0.000186 * $t + $dr * 1.0e-5;
    my $b = ( 175.1 - 10.2 * $t + $db ) / ARCS;

    $l, $b, $r;

}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m  = pi2 * frac( 0.8829867 + 3.3947688 * $t );
    my $cm = cos($m);
    my $dl = 5.84 + 0.65 * $cm;
    my $dr = 3.09 * sin($m);
    my $db = 0.24 * $cm;

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Saturn - Saturn.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Saturn;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Saturn->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Saturn> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Saturn->new

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
