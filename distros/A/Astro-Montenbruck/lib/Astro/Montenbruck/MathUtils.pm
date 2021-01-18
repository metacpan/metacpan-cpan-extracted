package Astro::Montenbruck::MathUtils;

use 5.22.0;
use feature qw/signatures/;
no warnings qw/experimental::signatures/;
# The line below disables wrong perlcritic warnings
## no critic qw/Subroutines::ProhibitSubroutinePrototypes/

use Exporter qw/import/;
use POSIX qw (floor ceil acos modf fmod);
use List::Util qw/any reduce/;

use Math::Trig qw/:pi :radial deg2rad rad2deg/;
use constant { ARCS => 3600.0 * 180.0 / pi };

our %EXPORT_TAGS = (
    all => [
        qw/frac frac360 dms hms zdms ddd polynome sine
          reduce_deg reduce_rad to_range opposite_deg opposite_rad
          angle_s angle_c angle_c_rad diff_angle polar cart quad
          ARCS/
    ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.02;

sub frac($x) { ( modf($x) )[0] }

sub frac360($x) { frac($x) * 360 }

sub dms ( $x, $places = 3 ) {
    return $x if $places == 1;

    my ( $f, $i ) = modf($x);
    $f = -$f if $i != 0 && $f < 0;

    ( $i, dms( $f * 60, $places - 1 ) );
}

sub hms { dms @_ }

sub zdms($x) {
    my ( $d, $m, $s ) = dms($x);
    my $z = int( $d / 30 );
    $d %= 30;

    $z, $d, $m, $s;
}

sub ddd(@args) {
    my $b = any { $_ < 0 } @args;
    my $sgn = $b ? -1 : 1;
    my ( $d, $m, $s ) = map { abs( $args[$_] || 0 ) } ( 0 .. 2 );
    return $sgn * ( $d + ( $m + $s / 60.0 ) / 60.0 );
}

sub polynome ( $t, @terms ) {
    reduce { $a * $t + $b } reverse @terms;
}

sub to_range ( $x, $limit ) {
    $x = fmod( $x, $limit );
    $x < 0 ? $x + $limit : $x;
}

#sub reduce_deg($x) { to_range( $x, 360 ) }

sub reduce_deg($x) {
    my $res = Math::Trig::deg2deg($x);
    $res < 0 ? $res + 360 : $res;
}

#sub reduce_rad($x) { to_range( $x, pi2 ) }

sub reduce_rad($x) {
    my $res = Math::Trig::rad2rad($x);
    $res < 0 ? $res + pi2 : $res;
}

sub sine($x) { sin( pi2 * frac($x) ) }

sub opposite_deg($x) { reduce_deg( $x + 180 ) }

sub opposite_rad($x) { reduce_rad( $x + pi ) }

sub angle_c ( $a, $b ) {
    my $x = abs( $a - $b );
    $x > 180 ? 360 - $x : $x;
}

sub angle_c_rad ( $a, $b ) {
    my $x = abs( $a - $b );
    $x > pi ? pi2 - $x : $x;
}

sub angle_s {
    my ( $x1, $y1, $x2, $y2 ) = map { deg2rad $_ } @_;
    rad2deg(
        acos( sin($y1) * sin($y2) + cos($y1) * cos($y2) * cos( $x1 - $x2 ) ) );
}

sub diff_angle($a, $b, $mode = 'degrees') {
    my $m = lc $mode;
    my $whole = $m eq 'degrees' ? 360
                                : $m eq 'radians' ? pi2
                                                  : undef;
    die "Expected 'degrees' or 'radians' mode" unless $whole;
    my $half = $m eq 'degrees' ? 180 : pi;
    my $x = $b < $a ? $b + $whole : $b;
    $x -= $a;
    return $x - $whole if $x > $half;
    return $x;
}


sub cart( $r, $theta, $phi ) {
    my $rcst = $r * cos($theta);
    $rcst * cos($phi), $rcst * sin($phi), $r * sin($theta);
}

# in previous versions was named 'polar'
sub polar ( $x, $y, $z ) {
    my $rho = $x * $x + $y * $y;
    my $r   = sqrt( $rho + $z * $z );
    my $phi = atan2( $y, $x );
    $phi += pi2 if $phi < 0;
    $rho = sqrt($rho);
    my $theta = atan2( $z, $rho );
    $r, $theta, $phi;
}

sub quad {
    my ( $y_minus, $y_0, $y_plus ) = @_;
    my $nz = 0;
    my $a  = 0.5 * ( $y_minus + $y_plus ) - $y_0;
    my $b  = 0.5 * ( $y_plus - $y_minus );
    my $c  = $y_0;

    my $xe  = -$b / ( 2 * $a );
    my $ye  = ( $a * $xe + $b ) * $xe + $c;
    my $dis = $b * $b - 4 * $a * $c;          # discriminant of y = axx+bx+c
    my @zeroes;
    if ( $dis >= 0 ) {

        # parabola intersects x-axis
        my $dx = 0.5 * sqrt($dis) / abs($a);
        @zeroes[ 0, 1 ] = ( $xe - $dx, $xe + $dx );
        $nz++ if abs( $zeroes[0] ) <= 1;
        $nz++ if abs( $zeroes[1] ) <= 1;
        $zeroes[0] = $zeroes[1] if $zeroes[0] < -1;
    }
    $nz, $xe, $ye, @zeroes;
}



1;    # End of Astro::Montenbruck::Core::MathUtils

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Core::MathUtils - Core mathematical routines used by Astro::Montenbruck modules.

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

  use Astro::Montenbruck::Core::MathUtils qw/dms/;

  my ($d, $m, $s) = dms(55.75); # (55, 45, 0)
  ...

=head1 EXPORT

=over

=item * L</frac($x)>

=item * L</frac360($x)>

=item * L</dms($x)>

=item * L</hms($x)>

=item * L</zdms($x)>

=item * L</ddd($deg[, $min[, $sec]])>

=item * L</polynome($t, @terms)>

=item * L</to_range($x, $range)>

=item * L</reduce_deg($x)>

=item * L</reduce_rad($x)>

=item * L</opposite_deg($x)>

=item * L</opposite_rad($x)>

=item * L</angle_c($x, $y)>

=item * L</angle_c_rad($x, $y)>

=item * L</angle_c_rad($x, $y)>

=item * L</angle_s($x1, $y1, $x2, $y2)>

=item * L</diff_angle($a, $b, $mode='degrees')>

=item * L</diff_angle($a, $b, $mode='degrees')>

=item * L</cart($r, $theta, $phi)>

=item * L</polar($x, $y, $z)>

=back


=head1 SUBROUTINES


=head2 frac($x)

Fractional part of a decimal number.


=head2 frac360($x)

Range function, similar to L<to_range($x, $range)>, used with polinomial function for better accuracy.


=head2 dms($x)

Given decimal hours (or degrees), return nearest hours (or degrees), int,
minutes, int, and seconds, float.

=head3 Positional arguments:

=over

=item * decimal value, 0..360 for angular mode, 0..24 for time

=back

=head3 Named arguments:

=over

=item * B<places> (optional) amount of required sexadecimal values to be returned (1-3);
                  default = 3 (degrees/hours, minutes, seconds)

=back

=head3 Returns:

=over

=item * array of degrees (int), minutes (int), seconds (float)

=back


=head2 hms($x)

Alias for L</dms>

=head2 zdms($x)

Converts decimal degrees to zodiac sign number (zero based), zodiac degrees, minutes and seconds.

=head3 Positional arguments:

=over

=item * decimal value, 0..360 for angular mode, 0..24 for time

=back

=head3 Returns:

=over

=item * array of zodiac sign (0-11), degrees (int), minutes (int), seconds (float)

=back


=head2 ddd($deg[, $min[, $sec]])

Converts sexadecimal values to decimal.

=head3 Arguments

=over

1 to 3 sexadecimal values, such as: degrees, minutes and
seconds, or degrees and minutes, or just degrees:

=over

=item * C<ddd(11)>

=item * C<ddd(11, 46)>

=item * C<ddd(11, 46, 20)>

=back

If any non-zero argument is negative, the result is negative.

=over

=item * C<ddd(-11, 46, 0) = -11.766666666666667>

=item * C<ddd(11, -46, 0) = 11.766666666666667>

=back

Negative sign in wrong position is ignored.

=back

=head3 Returns:

=over

=item * decimal (degrees or hours)

=back


=head2 polynome($t, @terms)

Calculates polynome: $a1 + $a2*$t + $a3*$t*$t + $a4*$t*$t*$t...

=head3 Arguments

=over

=item * $t coefficient, in astronomical routines usually time in centuries

=item * any number of decimal values

=back

=head3 Returns:

=over

=item * decimal number

=back



=head2 to_range($x, $range)

Reduces $x to 0 >= $x < $range

=head3 Arguments

=over

=item * number to reduce

=item * limit (non-inclusive), e.g: 360 for degrees, 24 for hours

=back

=head3 Returns

=over

=item * number

=back



=head2 reduce_deg($x)

Reduces $x to 0 >= $x < 360


=head2 reduce_rad($x)

Reduces $x to 0 >= $x < pi2

=head2 opposite_deg($x)

Returns opposite degree.


=head2 opposite_rad($x)

Returns opposite radian.

=head2 angle_c($x, $y)

Calculate shortest arc in dergees between $x and $y.

=head2 angle_c_rad($x, $y)

Calculates shortest arc in radians between $x and $y.

=head2 angle_s($x1, $y1, $x2, $y2)

Calculates arc between 2 points on a sphera.
Expected arguments: 2 pairs of coordinates (X, Y) of the 2 points.

The coordinates may be ecliptic, equatorial or horizontal.

=head2 diff_angle($a, $b, $mode='degrees')

Return angle C<$b - $a>, accounting for circular values.

Parameters $a and $b should be in the range 0..pi*2 or 0..360, depending on
optional B<$mode> argument. The result will be in the range I<-pi..pi> or I<-180..180>.
This allows us to directly compare angles which cross through 0:
I<359 degress... 0 degrees... 1 degree...> etc.

=head3 Positional Arguments

=over

=item * B<$a> first angle, in radians or degrees

=item * B<$b> second angle, in radians or degrees

=back

=head3 Named Arguments

=over

=item * B<$mode> C<"degrees"> (default) or C<"radians">, case insensitive.

=back


=head2 sine($x)

Calculate sin(phi); phi in units of 1 revolution = 360 degrees

=head2 cart($r, $theta, $phi)

Conversion of polar coordinates (r,theta,phi) into cartesian (x,y,z).

=head3 Arguments

=over

=item * B<$r>, distance from the origin;

=item * B<$theta> (in radians) corresponding to [-90 deg, +90 deg];

=item * B<$phi> (in radians) corresponding to [-360 deg, +360 deg])

=back

=head3 Returns

Rectangular coordinates:

=over

=item * B<$x>, X

=item * B<$y>, Y

=item * B<$z>, Z


=back

=head2 polar($x, $y, $z)

Conversion of cartesian coordinates (x,y,z) into polar (r,theta,phi).

=head3 Arguments

=over

=item * B<$x>, X

=item * B<$y>, Y

=item * B<$z>, Z

=back

=head3 Returns

=over

=item * B<$r>, distance from the origin;

=item * B<$theta> (in radians) corresponding to [-90 deg, +90 deg];

=item * B<$phi> (in radians) corresponding to [-360 deg, +360 deg])

=back

=head2 quad($y_minus, $y_0, $y_plus)

Quadratic interpolation

Finds a parabola through 3 points C<(-1 , y_minus), (0, Y_0), (1, y_plus)>,
that do not lie on a straight line.   

=head3 Arguments

Three y-values:

=over

=item * B<$y_minus> value of function at x = -1

=item * B<$y_0> value of function at x = 0

=item * B<$y_plus> value of function at x = 1

=back

=head3 Returns

=over

=item * B<$xe>, abscissa of extremum (may be outside C<[-1, 1]>)

=item * B<$ye>, Value of function at xe

=item * B<$root1>, first root found

=item * B<$root2>, second root found

=item * B<$n_root>, number of roots within the interval C<[-1, +1]>

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2021 Sergey Krushinsky.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
