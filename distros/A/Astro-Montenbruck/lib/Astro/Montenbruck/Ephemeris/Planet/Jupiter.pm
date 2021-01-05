package Astro::Montenbruck::Ephemeris::Planet::Jupiter;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Math::Trig qw/:pi/;
use Astro::Montenbruck::Ephemeris::Pert qw/pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$JU/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $JU);
}


sub heliocentric {
    my ($self, $t) = @_;

    # Mean anomalies of planets in [rad]
    my $m5 = pi2 * frac ( 0.0565314 + 8.4302963 * $t );
    my $m6 = pi2 * frac ( 0.8829867 + 3.3947688 * $t );
    my $m7 = pi2 * frac ( 0.3969537 + 1.1902586 * $t );

    my ($dl, $dr, $db) = (0, 0, 0); # Corrections in longitude ["],
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Perturbations by Saturn
    my $term = pert(
        T     => $t,
        M     => $m5,
        m     => $m6,
        I_min =>-1,
        I_max => 5,
        i_min =>-10,
        i_max =>-0,
        callback => $pert_cb
    );

    $term->(-1, -1,0,  -0.2,    1.4,     2.0,   0.6,    0.1, -0.2);
    $term->( 0, -1,0,   9.4,    8.9,     3.9,  -8.3,   -0.4, -1.4);
    $term->( 0, -2,0,   5.6,   -3.0,    -5.4,  -5.7,   -2.0,  0.0);
    $term->( 0, -3,0,  -4.0,   -0.1,     0.0,   5.5,    0.0,  0.0);
    $term->( 0, -5,0,   3.3,   -1.6,    -1.6,  -3.1,   -0.5, -1.2);
    $term->( 1,  0,0,-113.1,19998.6,-25208.2,-142.2,-4670.7,288.9);
    $term->( 1,  0,1, -76.1,   66.9,   -84.2, -95.8,   21.6, 29.4);
    $term->( 1,  0,2,  -0.5,   -0.3,     0.4,  -0.7,    0.1, -0.1);
    $term->( 1, -1,0,  78.8,  -14.5,    11.5,  64.4,   -0.2,  0.2);
    $term->( 1, -2,0,  -2.0, -132.4,    28.8,   4.3,   -1.7,  0.4);
    $term->( 1, -2,1,  -1.1,   -0.7,     0.2,  -0.3,    0.0,  0.0);
    $term->( 1, -3,0,  -7.5,   -6.8,    -0.4,  -1.1,    0.6, -0.9);
    $term->( 1, -4,0,   0.7,    0.7,     0.6,  -1.1,    0.0, -0.2);
    $term->( 1, -5,0,  51.5,  -26.0,   -32.5, -64.4,   -4.9,-12.4);
    $term->( 1, -5,1,  -1.2,   -2.2,    -2.7,   1.5,   -0.4,  0.3);
    $term->( 2,  0,0,  -3.4,  632.0,  -610.6,  -6.5, -226.8, 12.7);
    $term->( 2,  0,1,  -4.2,    3.8,    -4.1,  -4.5,    0.2,  0.6);
    $term->( 2, -1,0,   5.3,   -0.7,     0.7,   6.1,    0.2,  1.1);
    $term->( 2, -2,0, -76.4, -185.1,   260.2,-108.0,    1.6,  0.0);
    $term->( 2, -3,0,  66.7,   47.8,   -51.4,  69.8,    0.9,  0.3);
    $term->( 2, -3,1,   0.6,   -1.0,     1.0,   0.6,    0.0,  0.0);
    $term->( 2, -4,0,  17.0,    1.4,    -1.8,   9.6,    0.0, -0.1);
    $term->( 2, -5,0,1066.2, -518.3,    -1.3, -23.9,    1.8, -0.3);
    $term->( 2, -5,1, -25.4,  -40.3,    -0.9,   0.3,    0.0,  0.0);
    $term->( 2, -5,2,  -0.7,    0.5,     0.0,   0.0,    0.0,  0.0);
    $term->( 3,  0,0,  -0.1,   28.0,   -22.1,  -0.2,  -12.5,  0.7);
    $term->( 3, -2,0,  -5.0,  -11.5,    11.7,  -5.4,    2.1, -1.0);
    $term->( 3, -3,0,  16.9,   -6.4,    13.4,  26.9,   -0.5,  0.8);
    $term->( 3, -4,0,   7.2,  -13.3,    20.9,  10.5,    0.1, -0.1);
    $term->( 3, -5,0,  68.5,  134.3,  -166.9,  86.5,    7.1, 15.2);
    $term->( 3, -5,1,   3.5,   -2.7,     3.4,   4.3,    0.5, -0.4);
    $term->( 3, -6,0,   0.6,    1.0,    -0.9,   0.5,    0.0,  0.0);
    $term->( 3, -7,0,  -1.1,    1.7,    -0.4,  -0.2,    0.0,  0.0);
    $term->( 4,  0,0,   0.0,    1.4,    -1.0,   0.0,   -0.6,  0.0);
    $term->( 4, -2,0,  -0.3,   -0.7,     0.4,  -0.2,    0.2, -0.1);
    $term->( 4, -3,0,   1.1,   -0.6,     0.9,   1.2,    0.1,  0.2);
    $term->( 4, -4,0,   3.2,    1.7,    -4.1,   5.8,    0.2,  0.1);
    $term->( 4, -5,0,   6.7,    8.7,    -9.3,   8.7,   -1.1,  1.6);
    $term->( 4, -6,0,   1.5,   -0.3,     0.6,   2.4,    0.0,  0.0);
    $term->( 4, -7,0,  -1.9,    2.3,    -3.2,  -2.7,    0.0, -0.1);
    $term->( 4, -8,0,   0.4,   -1.8,     1.9,   0.5,    0.0,  0.0);
    $term->( 4, -9,0,  -0.2,   -0.5,     0.3,  -0.1,    0.0,  0.0);
    $term->( 4,-10,0,  -8.6,   -6.8,    -0.4,   0.1,    0.0,  0.0);
    $term->( 4,-10,1,  -0.5,    0.6,     0.0,   0.0,    0.0,  0.0);
    $term->( 5, -5,0,  -0.1,    1.5,    -2.5,  -0.8,   -0.1,  0.1);
    $term->( 5, -6,0,   0.1,    0.8,    -1.6,   0.1,    0.0,  0.0);
    $term->( 5, -9,0,  -0.5,   -0.1,     0.1,  -0.8,    0.0,  0.0);
    $term->( 5,-10,0,   2.5,   -2.2,     2.8,   3.1,    0.1, -0.2);

    # Perturbations by Uranus
    $term
        = pert(T     => $t,
               M     => $m5,
               m     => $m7,
               I_min => 1,
               I_max => 1,
               i_min =>-2,
               i_max =>-1,
               callback => $pert_cb);


    $term->( 1, -1,0,   0.4,    0.9,     0.0,   0.0,    0.0,  0.0);
    $term->( 1, -2,0,   0.4,    0.4,    -0.4,   0.3,    0.0,  0.0);


    # Perturbations by Saturn and Uranus
    my $phi = ( 2 * $m5 - 6 * $m6 + 3 * $m7);
    my $c   = cos($phi);
    my $s   = sin($phi);
    $dl += -0.8 * $c + 8.5 * $s;
    $dr += -0.1 * $c;

    $phi = (3 * $m5 - 6 * $m6 + 3 * $m7);
    $c = cos($phi);
    $s = sin($phi);
    $dl += +0.4 * $c + 0.5 * $s;
    $dr += -0.7 * $c + 0.5 * $s;
    $db += -0.1 * $c;

    # Ecliptic coordinates ([rad],[AU])
    my $l = pi2 * frac (0.0388910 + $m5 / pi2 + ( (5025.2+0.8 * $t ) * $t + $dl ) / 1296.0e3);
    my $r = 5.208873 + 0.000041 * $t +  $dr * 1.0E-5;
    my $b = ( 227.3 - 0.3 * $t + $db ) / ARCS;

    $l, $b, $r
}


# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ($self, $t) = @_;

    my $m  = pi2 * frac(0.0565314+8.4302963 * $t);
    my $sm = sin($m);
    my $dl = 14.50 + 1.41 * cos($m);
    my $dr = 3.66 * $sm;
    my $db = 0.33 * $sm;

    $dl, $db, $dr;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Jupiter - Jupiter.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Jupiter;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Jupiter->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Jupiter> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Jupiter->new

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
