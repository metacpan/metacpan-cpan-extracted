package Astro::Montenbruck::Ephemeris::Planet::Moon;

use strict;
use warnings;

use Readonly;
use Math::Trig qw/:pi rad2deg deg2rad/;
use Astro::Montenbruck::Ephemeris::Planet;
use base qw/Astro::Montenbruck::Ephemeris::Planet/;
use Astro::Montenbruck::Ephemeris::Planet qw/$MO/;
use Astro::Montenbruck::MathUtils qw /frac sine ARCS reduce_deg cart polar/;
use Astro::Montenbruck::Ephemeris::Pert qw /addthe/;

our $VERSION = 0.02;

Readonly our $ARC => 206264.81; # 3600 * 180 / PI = arcsec per radian
Readonly our $RADII_TO_AU => 4.26354E-5;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $MO );
}

# calculate long-periodic changes of the mean elements
# l,l',F,D and L0 as well as dgamma
sub _long_periodic {
    my $t = shift;

    my $s1 = sine( 0.19833 + 0.05611 * $t );
    my $s2 = sine( 0.27869 + 0.04508 * $t );
    my $s3 = sine( 0.16827 - 0.36903 * $t );
    my $s4 = sine( 0.34734 - 5.37261 * $t );
    my $s5 = sine( 0.10498 - 5.37899 * $t );
    my $s6 = sine( 0.42681 - 0.41855 * $t );
    my $s7 = sine( 0.14943 - 5.37511 * $t );
    my $dl0 =
      0.84 * $s1 +
      0.31 * $s2 +
      14.27 * $s3 +
      7.26 * $s4 +
      0.28 * $s5 +
      0.24 * $s6;
    my $dl =
      2.94 * $s1 +
      0.31 * $s2 +
      14.27 * $s3 +
      9.34 * $s4 +
      1.12 * $s5 +
      0.83 * $s6;
    my $dls = -6.40 * $s1 - 1.89 * $s6;
    my $df =
      0.21 * $s1 +
      0.31 * $s2 +
      14.27 * $s3 -
      88.70 * $s4 -
      15.30 * $s5 +
      0.24 * $s6 -
      1.86 * $s7;
    my $dd = $dl0 - $dls;
    my $dgam =
      -3332e-9 * sine( 0.59734 - 5.37261 * $t ) -
      539e-9 * sine( 0.35498 - 5.37899 * $t ) -
      64e-9 * sine( 0.39943 - 5.37511 * $t );

    $dl0, $dl, $dls, $df, $dd, $dgam;
}

sub moonpos {
    my ( $self, $t ) = @_;
    my ( %co, %si );
    my ( $dlam, $ds, $gam1c, $n );
    my $sinpi = 3422.7;
    my ( $dl0, $dl, $dls, $df, $dd, $dgam, $l, $l0, $ls, $f, $d );

    # INIT: calculates the mean elements and their sine and cosine
    # l mean anomaly of the Moon
    # l' mean anomaly of the Sun
    # F mean distance from the node
    # D  mean elongation from the Sun
    my $init = sub {
        my $t2 = $t * $t;

        ( $dl0, $dl, $dls, $df, $dd, $dgam ) = _long_periodic($t);

        $l0 = pi2 * frac( 0.60643382 + 1336.85522467 * $t - 0.00000313 * $t2 ) +
          $dl0 / ARCS;
        $l = pi2 * frac( 0.37489701 + 1325.55240982 * $t + 0.00002565 * $t2 ) +
          $dl / ARCS;
        $ls = pi2 * frac( 0.99312619 + 99.99735956 * $t - 0.00000044 * $t2 ) +
          $dls / ARCS;
        $f = pi2 * frac( 0.25909118 + 1342.22782980 * $t - 0.00000892 * $t2 ) +
          $df / ARCS;
        $d = pi2 * frac( 0.82736186 + 1236.85308708 * $t - 0.00000397 * $t2 ) +
          $dd / ARCS;

        for my $i ( 1 .. 4 ) {

            my ( $arg, $max, $fac ) = (
                sub { $l,  4, 1.000002208 },
                sub { $ls, 3, 0.997504612 - 0.002495388 * $t },
                sub { $f,  4, 1.000002708 + 139.978 * $dgam },
                sub { $d,  6, 1.0 }
            )[ $i - 1 ]->();

            $co{0}->{$i} = 1.0;
            $co{1}->{$i} = cos($arg) * $fac;
            $si{0}->{$i} = 0.0;
            $si{1}->{$i} = sin($arg) * $fac;

            for ( 2 .. $max ) {
                my $k = $_ - 1;
                ( $co{$_}->{$i}, $si{$_}->{$i} ) = addthe(
                    $co{$k}->{$i}, $si{$k}->{$i},
                    $co{1}->{$i},  $si{1}->{$i}
                );
            }
            for ( 1 .. $max ) {
                $co{ -$_ }->{$i} = $co{$_}->{$i};
                $si{ -$_ }->{$i} = -$si{$_}->{$i};
            }
        }
    };

    # TERM calculates X = cos(p * arg1 + q * arg2 + r * arg3 + s * arg4)
    #             and Y = sin(p * arg1 + q * arg2 + r * arg3 + s * arg4)
    my $term = sub {
        my @pqrs = @_;
        my %i    = map { $_ + 1, $pqrs[$_] } ( 0 .. 3 );
        my $x    = 1.0;
        my $y    = 0.0;

        for ( 1 .. 4 ) {
            if ( $i{$_} != 0 ) {
                my $j = $i{$_};
                ( $x, $y ) = addthe( $x, $y, $co{$j}->{$_}, $si{$j}->{$_} );
            }
        }
        $x, $y;
    };

    my $addsol = sub {
        my ( $coeffl, $coeffs, $coeffg, $coeffp, $p, $q, $r, $s ) = @_;
        my ( $x, $y ) = $term->( $p, $q, $r, $s );

        $dlam  += $coeffl * $y;
        $ds    += $coeffs * $y;
        $gam1c += $coeffg * $x;
        $sinpi += $coeffp * $x;
    };

    my $solar_1 = sub {
        $addsol->( 13.902,    14.06,    -0.001, 0.2607,   0, 0, 0, 4 );
        $addsol->( 0.403,     -4.01,    +0.394, 0.0023,   0, 0, 0, 3 );
        $addsol->( 2369.912,  2373.36,  +0.601, 28.2333,  0, 0, 0, 2 );
        $addsol->( -125.154,  -112.79,  -0.725, -0.9781,  0, 0, 0, 1 );
        $addsol->( 1.979,     6.98,     -0.445, 0.0433,   1, 0, 0, 4 );
        $addsol->( 191.953,   192.72,   +0.029, 3.0861,   1, 0, 0, 2 );
        $addsol->( -8.466,    -13.51,   +0.455, -0.1093,  1, 0, 0, 1 );
        $addsol->( 22639.500, 22609.07, +0.079, 186.5398, 1, 0, 0, 0 );
        $addsol->( 18.609,    3.59,     -0.094, 0.0118,   1, 0, 0, -1 );
        $addsol->( -4586.465, -4578.13, -0.077, 34.3117,  1, 0, 0, -2 );
        $addsol->( +3.215,    5.44,     +0.192, -0.0386,  1, 0, 0, -3 );
        $addsol->( -38.428,   -38.64,   +0.001, 0.6008,   1, 0, 0, -4 );
        $addsol->( -0.393,    -1.43,    -0.092, 0.0086,   1, 0, 0, -6 );
        $addsol->( -0.289,    -1.59,    +0.123, -0.0053,  0, 1, 0, 4 );
        $addsol->( -24.420,   -25.10,   +0.040, -0.3000,  0, 1, 0, 2 );
        $addsol->( 18.023,    17.93,    +0.007, 0.1494,   0, 1, 0, 1 );
        $addsol->( -668.146,  -126.98,  -1.302, -0.3997,  0, 1, 0, 0 );
        $addsol->( 0.560,     0.32,     -0.001, -0.0037,  0, 1, 0, -1 );
        $addsol->( -165.145,  -165.06,  +0.054, 1.9178,   0, 1, 0, -2 );
        $addsol->( -1.877,    -6.46,    -0.416, 0.0339,   0, 1, 0, -4 );
        $addsol->( 0.213,     1.02,     -0.074, 0.0054,   2, 0, 0, 4 );
        $addsol->( 14.387,    14.78,    -0.017, 0.2833,   2, 0, 0, 2 );
        $addsol->( -0.586,    -1.20,    +0.054, -0.0100,  2, 0, 0, 1 );
        $addsol->( 769.016,   767.96,   +0.107, 10.1657,  2, 0, 0, 0 );
        $addsol->( +1.750,    2.01,     -0.018, 0.0155,   2, 0, 0, -1 );
        $addsol->( -211.656,  -152.53,  +5.679, -0.3039,  2, 0, 0, -2 );
        $addsol->( +1.225,    0.91,     -0.030, -0.0088,  2, 0, 0, -3 );
        $addsol->( -30.773,   -34.07,   -0.308, 0.3722,   2, 0, 0, -4 );
        $addsol->( -0.570,    -1.40,    -0.074, 0.0109,   2, 0, 0, -6 );
        $addsol->( -2.921,    -11.75,   +0.787, -0.0484,  1, 1, 0, 2 );
        $addsol->( +1.267,    1.52,     -0.022, 0.0164,   1, 1, 0, 1 );
        $addsol->( -109.673,  -115.18,  +0.461, -0.9490,  1, 1, 0, 0 );
        $addsol->( -205.962,  -182.36,  +2.056, +1.4437,  1, 1, 0, -2 );
        $addsol->( 0.233,     0.36,     0.012,  -0.0025,  1, 1, 0, -3 );
        $addsol->( -4.391,    -9.66,    -0.471, 0.0673,   1, 1, 0, -4 );
    };

    my $solar_2 = sub {
        $addsol->( 0.283,    1.53,   -0.111, +0.0060, 1, -1, 0,  +4 );
        $addsol->( 14.577,   31.70,  -1.540, +0.2302, 1, -1, 0,  2 );
        $addsol->( 147.687,  138.76, +0.679, +1.1528, 1, -1, 0,  0 );
        $addsol->( -1.089,   0.55,   +0.021, 0.0,     1, -1, 0,  -1 );
        $addsol->( 28.475,   23.59,  -0.443, -0.2257, 1, -1, 0,  -2 );
        $addsol->( -0.276,   -0.38,  -0.006, -0.0036, 1, -1, 0,  -3 );
        $addsol->( 0.636,    2.27,   +0.146, -0.0102, 1, -1, 0,  -4 );
        $addsol->( -0.189,   -1.68,  +0.131, -0.0028, 0, 2,  0,  2 );
        $addsol->( -7.486,   -0.66,  -0.037, -0.0086, 0, 2,  0,  0 );
        $addsol->( -8.096,   -16.35, -0.740, 0.0918,  0, 2,  0,  -2 );
        $addsol->( -5.741,   -0.04,  0.0,    -0.0009, 0, 0,  2,  2 );
        $addsol->( 0.255,    0.0,    0.0,    0.0,     0, 0,  2,  1 );
        $addsol->( -411.608, -0.20,  0.0,    -0.0124, 0, 0,  2,  0 );
        $addsol->( 0.584,    0.84,   0.0,    +0.0071, 0, 0,  2,  -1 );
        $addsol->( -55.173,  -52.14, 0.0,    -0.1052, 0, 0,  2,  -2 );
        $addsol->( 0.254,    0.25,   0.0,    -0.0017, 0, 0,  2,  -3 );
        $addsol->( +0.025,   -1.67,  0.0,    +0.0031, 0, 0,  2,  -4 );
        $addsol->( 1.060,    2.96,   -0.166, 0.0243,  3, 0,  0,  +2 );
        $addsol->( 36.124,   50.64,  -1.300, 0.6215,  3, 0,  0,  0 );
        $addsol->( -13.193,  -16.40, +0.258, -0.1187, 3, 0,  0,  -2 );
        $addsol->( -1.187,   -0.74,  +0.042, 0.0074,  3, 0,  0,  -4 );
        $addsol->( -0.293,   -0.31,  -0.002, 0.0046,  3, 0,  0,  -6 );
        $addsol->( -0.290,   -1.45,  +0.116, -0.0051, 2, 1,  0,  2 );
        $addsol->( -7.649,   -10.56, +0.259, -0.1038, 2, 1,  0,  0 );
        $addsol->( -8.627,   -7.59,  +0.078, -0.0192, 2, 1,  0,  -2 );
        $addsol->( -2.740,   -2.54,  +0.022, 0.0324,  2, 1,  0,  -4 );
        $addsol->( 1.181,    3.32,   -0.212, 0.0213,  2, -1, 0,  +2 );
        $addsol->( 9.703,    11.67,  -0.151, 0.1268,  2, -1, 0,  0 );
        $addsol->( -0.352,   -0.37,  +0.001, -0.0028, 2, -1, 0,  -1 );
        $addsol->( -2.494,   -1.17,  -0.003, -0.0017, 2, -1, 0,  -2 );
        $addsol->( 0.360,    0.20,   -0.012, -0.0043, 2, -1, 0,  -4 );
        $addsol->( -1.167,   -1.25,  +0.008, -0.0106, 1, 2,  0,  0 );
        $addsol->( -7.412,   -6.12,  +0.117, 0.0484,  1, 2,  0,  -2 );
        $addsol->( -0.311,   -0.65,  -0.032, 0.0044,  1, 2,  0,  -4 );
        $addsol->( +0.757,   1.82,   -0.105, 0.0112,  1, -2, 0,  2 );
        $addsol->( +2.580,   2.32,   +0.027, 0.0196,  1, -2, 0,  0 );
        $addsol->( +2.533,   2.40,   -0.014, -0.0212, 1, -2, 0,  -2 );
        $addsol->( -0.344,   -0.57,  -0.025, +0.0036, 0, 3,  0,  -2 );
        $addsol->( -0.992,   -0.02,  0.0,    0.0,     1, 0,  2,  2 );
        $addsol->( -45.099,  -0.02,  0.0,    -0.0010, 1, 0,  2,  0 );
        $addsol->( -0.179,   -9.52,  0.0,    -0.0833, 1, 0,  2,  -2 );
        $addsol->( -0.301,   -0.33,  0.0,    0.0014,  1, 0,  2,  -4 );
        $addsol->( -6.382,   -3.37,  0.0,    -0.0481, 1, 0,  -2, 2 );
        $addsol->( 39.528,   85.13,  0.0,    -0.7136, 1, 0,  -2, 0 );
        $addsol->( 9.366,    0.71,   0.0,    -0.0112, 1, 0,  -2, -2 );
        $addsol->( 0.202,    0.02,   0.0,    0.0,     1, 0,  -2, -4 );
    };

    my $solar_3 = sub {
        $addsol->( 0.415,  0.10,  0.0,    0.0013,  0, 1,  2,  0 );
        $addsol->( -2.152, -2.26, 0.0,    -0.0066, 0, 1,  2,  -2 );
        $addsol->( -1.440, -1.30, 0.0,    +0.0014, 0, 1,  -2, 2 );
        $addsol->( 0.384,  -0.04, 0.0,    0.0,     0, 1,  -2, -2 );
        $addsol->( +1.938, +3.60, -0.145, +0.0401, 4, 0,  0,  0 );
        $addsol->( -0.952, -1.58, +0.052, -0.0130, 4, 0,  0,  -2 );
        $addsol->( -0.551, -0.94, +0.032, -0.0097, 3, 1,  0,  0 );
        $addsol->( -0.482, -0.57, +0.005, -0.0045, 3, 1,  0,  -2 );
        $addsol->( 0.681,  0.96,  -0.026, 0.0115,  3, -1, 0,  0 );
        $addsol->( -0.297, -0.27, 0.002,  -0.0009, 2, 2,  0,  -2 );
        $addsol->( 0.254,  +0.21, -0.003, 0.0,     2, -2, 0,  -2 );
        $addsol->( -0.250, -0.22, 0.004,  0.0014,  1, 3,  0,  -2 );
        $addsol->( -3.996, 0.0,   0.0,    +0.0004, 2, 0,  2,  0 );
        $addsol->( 0.557,  -0.75, 0.0,    -0.0090, 2, 0,  2,  -2 );
        $addsol->( -0.459, -0.38, 0.0,    -0.0053, 2, 0,  -2, 2 );
        $addsol->( -1.298, 0.74,  0.0,    +0.0004, 2, 0,  -2, 0 );
        $addsol->( 0.538,  1.14,  0.0,    -0.0141, 2, 0,  -2, -2 );
        $addsol->( 0.263,  0.02,  0.0,    0.0,     1, 1,  2,  0 );
        $addsol->( 0.426,  +0.07, 0.0,    -0.0006, 1, 1,  -2, -2 );
        $addsol->( -0.304, +0.03, 0.0,    +0.0003, 1, -1, 2,  0 );
        $addsol->( -0.372, -0.19, 0.0,    -0.0027, 1, -1, -2, 2 );
        $addsol->( +0.418, 0.0,   0.0,    0.0,     0, 0,  4,  0 );
        $addsol->( -0.330, -0.04, 0.0,    0.0,     3, 0,  2,  0 );
    };

    # part N of the perturbations of ecliptic latitude
    my $solar_n = sub {
        my $addn = sub {
            my $coeffn = shift;
            my ( $x, $y ) = $term->(@_);
            $n += $coeffn * $y;
        };

        $addn->( -526.069, 0,  0,  1, -2 );
        $addn->( -3.352,   0,  0,  1, -4 );
        $addn->( +44.297,  +1, 0,  1, -2 );
        $addn->( -6.000,   +1, 0,  1, -4 );
        $addn->( +20.599,  -1, 0,  1, 0 );
        $addn->( -30.598,  -1, 0,  1, -2 );
        $addn->( -24.649,  -2, 0,  1, 0 );
        $addn->( -2.000,   -2, 0,  1, -2 );
        $addn->( -22.571,  0,  +1, 1, -2 );
    };

    # perturbations of ecliptic latitude by Venus and Moon
    my $planetary = sub {
        $dlam +=
          +0.82 * sine( 0.7736 - 62.5512 * $t ) +
          0.31 * sine( 0.0466 - 125.1025 * $t ) +
          0.35 * sine( 0.5785 - 25.1042 * $t ) +
          0.66 * sine( 0.4591 + 1335.8075 * $t ) +
          0.64 * sine( 0.3130 - 91.5680 * $t ) +
          1.14 * sine( 0.1480 + 1331.2898 * $t ) +
          0.21 * sine( 0.5918 + 1056.5859 * $t ) +
          0.44 * sine( 0.5784 + 1322.8595 * $t ) +
          0.24 * sine( 0.2275 - 5.7374 * $t ) +
          0.28 * sine( 0.2965 + 2.6929 * $t ) +
          0.33 * sine( 0.3132 + 6.3368 * $t );
    };

    #
    # start
    #
    $init->();
    $solar_1->();
    $solar_2->();
    $solar_3->();
    $solar_n->();
    $planetary->();

    my $lambda = reduce_deg( rad2deg( $l0 + $dlam / ARCS ) );
    my $s      = $f + $ds / ARCS;
    my $fac    = 1.000002708 + 139.978 * $dgam;
    my $beta =
      ( $fac * ( 18518.511 + 1.189 + $gam1c ) * sin($s) -
          6.24 * sin( 3 * $s ) +
          $n ) / 3600.0;

    # equatorial horizontal parallax
    $sinpi *= 0.999953253;
    # my $delta = 8.794 / $sinpi;
    my $delta = $ARC /  $sinpi * $RADII_TO_AU;

    $lambda, $beta, $delta
}


sub apparent {
  my $self = shift;
  my ($mean, $nut_func) = @_;
  my ($l, $b, $r) = @$mean;
  # polar -> rectangular
  my ($x, $y, $z) = cart($r, deg2rad($b), deg2rad($l));
  # true equinox of date
  my @date = $nut_func->([$x, $y, $z]);
  # rectangular -> polar
  ($r, $b, $l) = polar(@date);
  rad2deg($l), rad2deg($b), $r  
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Moon - Moon.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Moon;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Moon->new();
  my @geo = $planet->moonpos($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Moon> position for the I<mean equinox of date>.

Formulae are based on analytical theory of by E.E.Brown (Improved Lunar Ephemeris)
with accuracy of approx. 1 arc-second.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Moon->new

Constructor.

=head2 $self->moonpos($t)

Geocentric ecliptic coordinates of the Moon. The coordinates are referred to the I<mean equinox od date>

=head3 Arguments

=over

=item B<$t> — time in Julian centuries since J2000: C<(JD-2451545.0)/36525.0>

=back

=head3 Returns

Hash of geocentric ecliptical coordinates.

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
