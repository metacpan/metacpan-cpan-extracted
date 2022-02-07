package Astro::Montenbruck::Ephemeris::Planet::Neptune;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Math::Trig qw/:pi/;
use Astro::Montenbruck::Ephemeris::Pert qw/pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$NE/;

our $VERSION = 0.02;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $NE );
}

sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m5 = pi2 * frac( 0.0563867 + 8.4298907 * $t );
    my $m6 = pi2 * frac( 0.8825086 + 3.3957748 * $t );
    my $m7 = pi2 * frac( 0.3965358 + 1.1902851 * $t );
    my $m8 = pi2 * frac( 0.7214906 + 0.6068526 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub { 
        $dl += $_[0]; 
        $dr += $_[1]; 
        $db += $_[2] 
    };

    # Perturbations by Jupiter
    my $term = pert(
        T        => $t,
        M        => $m8,
        m        => $m5,
        I_min    => 0,
        I_max    => 2,
        i_min    => -2,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 0, -1, 0, 0.1,   0.1,   -3.0,  1.8,    -0.3, -0.3 );
    $term->( 1, 0,  0, 0.0,   0.0,   -15.9, 9.0,    0.0,  0.0 );
    $term->( 1, -1, 0, -17.6, -29.3, 416.1, -250.0, 0.0,  0.0 );
    $term->( 1, -2, 0, -0.4,  -0.7,  10.4,  -6.2,   0.0,  0.0 );
    $term->( 2, -1, 0, -0.2,  -0.4,  2.4,   -1.4,   0.4,  -0.3 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m8,
        m        => $m6,
        I_min    => 0,
        I_max    => 2,
        i_min    => -2,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 0, -1, 0, -0.1, 0.0,   0.2,   -1.8,  -0.1, -0.5 );
    $term->( 1, 0,  0, 0.0,  0.0,   -8.3,  -10.4, 0.0,  0.0 );
    $term->( 1, -1, 0, 13.6, -12.7, 187.5, 201.1, 0.0,  0.0 );
    $term->( 1, -2, 0, 0.4,  -0.4,  4.5,   4.5,   0.0,  0.0 );
    $term->( 2, -1, 0, 0.4,  -0.1,  1.7,   -3.2,  0.2,  0.2 );
    $term->( 2, -2, 0, -0.1, 0.0,   -0.2,  2.7,   0.0,  0.0 );

    # Perturbations by Uranus
    $term = pert(
        T        => $t,
        M        => $m8,
        m        => $m7,
        I_min    => 1,
        I_max    => 6,
        i_min    => -6,
        i_max    => 0,
        callback => $pert_cb
    );
    $term->( 1, 0,  0, 32.3, 3549.5, -25880.2, 235.8, -6360.5, 374.0 );
    $term->( 1, 0,  1, 31.2, 34.4,   -251.4,   227.4, 34.9,    29.3 );
    $term->( 1, 0,  2, -1.4, 3.9,    -28.6,    -10.1, 0.0,     -0.9 );
    $term->( 2, 0,  0, 6.1,  68.0,   -111.4,   2.0,   -54.7,   3.7 );
    $term->( 2, 0,  1, 0.8,  -0.2,   -2.1,     2.0,   -0.2,    0.8 );
    $term->( 3, 0,  0, 0.1,  1.0,    -0.7,     0.0,   -0.8,    0.1 );
    $term->( 0, -1, 0, -0.1, -0.3,   -3.6,     0.0,   0.0,     0.0 );
    $term->( 1, 0,  0, 0.0,  0.0,    5.5,      -6.9,  0.1,     0.0 );
    $term->( 1, -1, 0, -2.2, -1.6,   -116.3,   163.6, 0.0,     -0.1 );
    $term->( 1, -2, 0, 0.2,  0.1,    -1.2,     0.4,   0.0,     -0.1 );
    $term->( 2, -1, 0, 4.2,  -1.1,   -4.4,     -34.6, -0.2,    0.1 );
    $term->( 2, -2, 0, 8.6,  -2.9,   -33.4,    -97.0, 0.2,     0.1 );
    $term->( 3, -1, 0, 0.1,  -0.2,   2.1,      -1.2,  0.0,     0.1 );
    $term->( 3, -2, 0, -4.6, 9.3,    38.2,     19.8,  0.1,     0.1 );
    $term->( 3, -3, 0, -0.5, 1.7,    23.5,     7.0,   0.0,     0.0 );
    $term->( 4, -2, 0, 0.2,  0.8,    3.3,      -1.5,  -0.2,    -0.1 );
    $term->( 4, -3, 0, 0.9,  1.7,    17.9,     -9.1,  -0.1,    0.0 );
    $term->( 4, -4, 0, -0.4, -0.4,   -6.2,     4.8,   0.0,     0.0 );
    $term->( 5, -3, 0, -1.6, -0.5,   -2.2,     7.0,   0.0,     0.0 );
    $term->( 5, -4, 0, -0.4, -0.1,   -0.7,     5.5,   0.0,     0.0 );
    $term->( 5, -5, 0, 0.2,  0.0,    0.0,      -3.5,  0.0,     0.0 );
    $term->( 6, -4, 0, -0.3, 0.2,    2.1,      2.7,   0.0,     0.0 );
    $term->( 6, -5, 0, 0.1,  -0.1,   -1.4,     -1.4,  0.0,     0.0 );
    $term->( 6, -6, 0, -0.1, 0.1,    1.4,      0.7,   0.0,     0.0 );

    # Ecliptic coordinates ([rad],[AU])
    my $l =
      pi2 *
      frac( 0.1254046 + $m8 / pi2 +
          ( ( 4982.8 - 21.3 * $t ) * $t + $dl ) / 1296.0e3 );
    my $r = 30.072984 + ( 0.001234 + 0.000003 * $t ) * $t + $dr * 1.0e-5;
    my $b = ( 54.77 + ( 0.26 + 0.06 * $t ) * $t + $db ) / ARCS;

    $l, $b, $r;

}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m  = pi2 * frac( 0.7214906 + 0.6068526 * $t );
    my $dl = 1.04 + 0.02 * cos($m);
    my $dr = 0.27 * sin($m);
    my $db = 0.03 * sin($m);

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Neptune - Neptune.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Neptune;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Neptune->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Neptune> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Neptune->new

Constructor.

=head2 $self->heliocentric($t)

See description in L<Astro::Montenbruck::Ephemeris::Planet>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
