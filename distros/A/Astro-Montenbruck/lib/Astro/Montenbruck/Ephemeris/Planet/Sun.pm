package Astro::Montenbruck::Ephemeris::Planet::Sun;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Math::Trig qw/:pi rad2deg deg2rad/;
use Astro::Montenbruck::MathUtils qw /frac ARCS reduce_rad cart polar/;
use Astro::Montenbruck::Ephemeris::Pert qw/pert/;
use Astro::Montenbruck::Ephemeris::Planet qw/$SU/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $SU );
}

sub sunpos {
  my ( $self, $t ) = @_;

  # mean anomalies of planets and mean arguments of lunar orbit [rad]
  my $m2 = pi2 * frac( 0.1387306 + 162.5485917 * $t );
  my $m3 = pi2 * frac( 0.9931266 + 99.9973604 * $t );
  my $m4 = pi2 * frac( 0.0543250 + 53.1666028 * $t );
  my $m5 = pi2 * frac( 0.0551750 + 8.4293972 * $t );
  my $m6 = pi2 * frac( 0.8816500 + 3.3938722 * $t );

  my $d = pi2 * frac( 0.8274 + 1236.8531 * $t );
  my $a = pi2 * frac( 0.3749 + 1325.5524 * $t );
  my $u = pi2 * frac( 0.2591 + 1342.2278 * $t );

  my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
  my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

  # Keplerian terms and perturbations by Venus
  my $term = pert(
      T        => $t,
      M        => $m3,
      m        => $m2,
      I_min    => 0,
      I_max    => 7,
      i_min    => -6,
      i_max    => 0,
      callback => $pert_cb
  );

  $term->( 1, 0,  0, -0.22, 6892.76, -16707.37, -0.54, 0,     0 );
  $term->( 1, 0,  1, -0.06, -17.35,  42.04,     -0.15, 0.00,  0.00 );
  $term->( 1, 0,  2, -0.01, -0.05,   0.13,      -0.02, 0.00,  0.00 );
  $term->( 2, 0,  0, 0.00,  71.98,   -139.57,   0.00,  0.00,  0.00 );
  $term->( 2, 0,  1, 0.00,  -0.36,   0.70,      0.00,  0.00,  0.00 );
  $term->( 3, 0,  0, 0.00,  1.04,    -1.75,     0.00,  0.00,  0.00 );
  $term->( 0, -1, 0, 0.03,  -0.07,   -0.16,     -0.07, 0.02,  -0.02 );
  $term->( 1, -1, 0, 2.35,  -4.23,   -4.75,     -2.64, 0.00,  0.00 );
  $term->( 1, -2, 0, -0.10, 0.06,    0.12,      0.20,  0.02,  0.00 );
  $term->( 2, -1, 0, -0.06, -0.03,   0.20,      -0.01, 0.01,  -0.09 );
  $term->( 2, -2, 0, -4.70, 2.90,    8.28,      13.42, 0.01,  -0.01 );
  $term->( 3, -2, 0, 1.80,  -1.74,   -1.44,     -1.57, 0.04,  -0.06 );
  $term->( 3, -3, 0, -0.67, 0.03,    0.11,      2.43,  0.01,  0.00 );
  $term->( 4, -2, 0, 0.03,  -0.03,   0.10,      0.09,  0.01,  -0.01 );
  $term->( 4, -3, 0, 1.51,  -0.40,   -0.88,     -3.36, 0.18,  -0.10 );
  $term->( 4, -4, 0, -0.19, -0.09,   -0.38,     0.77,  0.00,  0.00 );
  $term->( 5, -3, 0, 0.76,  -0.68,   0.30,      0.37,  0.01,  0.00 );
  $term->( 5, -4, 0, -0.14, -0.04,   -0.11,     0.43,  -0.03, 0.00 );
  $term->( 5, -5, 0, -0.05, -0.07,   -0.31,     0.21,  0.00,  0.00 );
  $term->( 6, -4, 0, 0.15,  -0.04,   -0.06,     -0.21, 0.01,  0.00 );
  $term->( 6, -5, 0, -0.03, -0.03,   -0.09,     0.09,  -0.01, 0.00 );
  $term->( 6, -6, 0, 0.00,  -0.04,   -0.18,     0.02,  0.00,  0.00 );
  $term->( 7, -5, 0, -0.12, -0.03,   -0.08,     0.31,  -0.02, -0.01 );

  # perturbations by Mars
  $term = pert(
      T        => $t,
      M        => $m3,
      m        => $m4,
      I_min    => 1,
      I_max    => 5,
      i_min    => -8,
      i_max    => -1,
      callback => $pert_cb
  );
  $term->( 1, -1, 0, -0.22, 0.17,  -0.21, -0.27, 0.00, 0.00 );
  $term->( 1, -2, 0, -1.66, 0.62,  0.16,  0.28,  0.00, 0.00 );
  $term->( 2, -2, 0, 1.96,  0.57,  -1.32, 4.55,  0.00, 0.01 );
  $term->( 2, -3, 0, 0.40,  0.15,  -0.17, 0.46,  0.00, 0.00 );
  $term->( 2, -4, 0, 0.53,  0.26,  0.09,  -0.22, 0.00, 0.00 );
  $term->( 3, -3, 0, 0.05,  0.12,  -0.35, 0.15,  0.00, 0.00 );
  $term->( 3, -4, 0, -0.13, -0.48, 1.06,  -0.29, 0.01, 0.00 );
  $term->( 3, -5, 0, -0.04, -0.20, 0.20,  -0.04, 0.00, 0.00 );
  $term->( 4, -4, 0, 0.00,  -0.03, 0.10,  0.04,  0.00, 0.00 );
  $term->( 4, -5, 0, 0.05,  -0.07, 0.20,  0.14,  0.00, 0.00 );
  $term->( 4, -6, 0, -0.10, 0.11,  -0.23, -0.22, 0.00, 0.00 );
  $term->( 5, -7, 0, -0.05, 0.00,  0.01,  -0.14, 0.00, 0.00 );
  $term->( 5, -8, 0, 0.05,  0.01,  -0.02, 0.10,  0.00, 0.00 );

  # perturbations by Sun
  $term = pert(
      T        => $t,
      M        => $m3,
      m        => $m5,
      I_min    => -1,
      I_max    => 3,
      i_min    => -4,
      i_max    => -1,
      callback => $pert_cb
  );
  $term->( -1, -1, 0, 0.01,  0.07,  0.18,  -0.02,  0.00, -0.02 );
  $term->( 0,  -1, 0, -0.31, 2.58,  0.52,  0.34,   0.02, 0.00 );
  $term->( 1,  -1, 0, -7.21, -0.06, 0.13,  -16.27, 0.00, -0.02 );
  $term->( 1,  -2, 0, -0.54, -1.52, 3.09,  -1.12,  0.01, -0.17 );
  $term->( 1,  -3, 0, -0.03, -0.21, 0.38,  -0.06,  0.00, -0.02 );
  $term->( 2,  -1, 0, -0.16, 0.05,  -0.18, -0.31,  0.01, 0.00 );
  $term->( 2,  -2, 0, 0.14,  -2.73, 9.23,  0.48,   0.00, 0.00 );
  $term->( 2,  -3, 0, 0.07,  -0.55, 1.83,  0.25,   0.01, 0.00 );
  $term->( 2,  -4, 0, 0.02,  -0.08, 0.25,  0.06,   0.00, 0.00 );
  $term->( 3,  -2, 0, 0.01,  -0.07, 0.16,  0.04,   0.00, 0.00 );
  $term->( 3,  -3, 0, -0.16, -0.03, 0.08,  -0.64,  0.00, 0.00 );
  $term->( 3,  -4, 0, -0.04, -0.01, 0.03,  -0.17,  0.00, 0.00 );

  # perturbations by Saturn
  $term = pert(
      T        => $t,
      M        => $m3,
      m        => $m6,
      I_min    => -0,
      I_max    => 2,
      i_min    => -2,
      i_max    => -1,
      callback => $pert_cb
  );
  $term->( 0, -1, 0, 0.00,  0.32,  0.01,  0.00,  0.00, 0.00 );
  $term->( 1, -1, 0, -0.08, -0.41, 0.97,  -0.18, 0.00, -0.01 );
  $term->( 1, -2, 0, 0.04,  0.10,  -0.23, 0.10,  0.00, 0.00 );
  $term->( 2, -2, 0, 0.04,  0.10,  -0.35, 0.13,  0.00, 0.00 );

  # difference of Earth-Moon-barycentre and centre of the Earth
  my $dpa = $d + $a;
  my $dma = $d - $a;
  $dl +=
    +6.45 * sin($d) -
    0.42 * sin($dma) +
    0.18 * sin($dpa) +
    0.17 * sin( $d - $m3 ) -
    0.06 * sin( $d + $m3 );

  $dr +=
    +30.76 * cos($d) -
    3.06 * cos($dma) +
    0.85 * cos($dpa) -
    0.58 * cos( $d + $m3 ) +
    0.57 * cos( $d - $m3 );

  $db += 0.576 * sin($u);

  # long-periodic perturbations
  $dl +=
    +6.40 * sin( pi2 * ( 0.6983 + 0.0561 * $t ) ) +
    1.87 * sin( pi2 *  ( 0.5764 + 0.4174 * $t ) ) +
    0.27 * sin( pi2 *  ( 0.4189 + 0.3306 * $t ) ) +
    0.20 * sin( pi2 *  ( 0.3581 + 2.4814 * $t ) );

  # ecliptic coordinates ([rad],[AU])
  my $l = reduce_rad(
      pi2 * frac(
          0.7859453 + $m3 / pi2 +
            ( ( 6191.2 + 1.1 * $t ) * $t + $dl ) / 1296.0e3
      )
  );
  my $r = 1.0001398 - 0.0000007 * $t + $dr * 1e-6;
  my $b = $db / 3600;

  rad2deg($l), $b,  $r;
}


sub _lbr_geo { 0, 0, 0 }


sub apparent {
  my $self = shift;
  my ($t, $lbr, $nut_func) = @_;
  my ($l, $b, $r) = @$lbr;
  # geocentric ecliptic coordinates (light-time corrected, referred to the mean equinox of date)
  my @mean = $self->_geocentric(
    $t, 
    { l => 0, b => 0, r => 0 }, 
    { l => deg2rad($l), b => deg2rad($b), r => $r }
  );   
  # true equinox of date
  my @date = $nut_func->(\@mean);
  # rectangular -> polar
  ($r, $b, $l) = polar(@date);
  rad2deg($l), rad2deg($b), $r  
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Sun - Sun.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Sun;
  Astro::Montenbruck::NutEqu qw/mean2true/;

  my $sun = Astro::Montenbruck::Ephemeris::Planet::Sun->new();
  my ($l, $b, $r) = $sun->sunpos($t); # true geocentric ecliptical coordinates

  my $nut_func = mean2true($t);
  # apparent geocentric ecliptical coordinates
  my ($lambda, $beta, $delta) = $sun->apparent($t, [$l, $b, $r], $nut_func); 

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Sun> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Sun->new

Constructor.

=head2 $self->sunpos($t)

Ecliptic coordinates L, B, R (in deg and AU) of the Sun referred to the I<mean equinox of date>.  

=head3 Arguments

=over

=item B<$t> — time in Julian centuries since J2000: (JD-2451545.0)/36525.0

=back

=head3 Returns

Array of geocentric ecliptical coordinates.

=over

=item * B<x> — geocentric longitude, arc-degrees

=item * B<y> — geocentric latitude, arc-degrees

=item * B<z> — distance from Earth, AU

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
