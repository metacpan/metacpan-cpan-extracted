# Moon.pm,v 1.5 2005/01/07 12:18:59 lestrrat Exp
#
# Copyright (c) 2004-2007 Daisuke Maki <daisuke@endeworks.jp>

package DateTime::Util::Astro::Moon;
use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK $CACHE);
use base qw(Class::Data::Inheritable);
use DateTime::Util::Astro;
use Exporter;
BEGIN
{
    *import = \&Exporter::import;

    $VERSION = $DateTime::Util::Astro::VERSION;
    @EXPORT_OK = qw(
        MEAN_SYNODIC_MONTH
        lunar_longitude
        lunar_phase
        nth_new_moon
    );
}

use DateTime::Util::Calc
    qw(polynomial mod sin_deg bf_downgrade bigfloat moment dt_from_moment search_next);
use DateTime::Util::Astro::Common
    qw(julian_centuries nutation dt_from_dynamical);
use DateTime::Util::Astro::Sun;
use Math::BigFloat ('lib'     => 'GMP,Pari');
use Math::BigInt   ('upgrade' => 'Math::BigFloat');

use constant MEAN_SYNODIC_MONTH => 29.530588853;
use constant LUNAR_LONGITUDE_ARGS => [
    # left side of table 12.5 , [1] p192
    #       V  W   X   Y   Z
    [ 6288774, 0,  0,  1,  0 ],
    [  658314, 2,  0,  0,  0 ],
    [ -185116, 0,  1,  0,  0 ],
    [   58793, 2,  0, -2,  0 ],
    [   53322, 2,  0,  1,  0 ],
    [  -40923, 0,  1, -1,  0 ],
    [  -30383, 0,  1,  1,  0 ],
    [  -12528, 0,  0,  1,  2 ],
    [   10675, 4,  0, -1,  0 ],
    [    8548, 4,  0, -2,  0 ],
    [   -6766, 2,  1,  0,  0 ],
    [    4987, 1,  1,  0,  0 ],
    [    3994, 2,  0,  2,  0 ],
    [    3665, 2,  0, -3,  0 ],
    [   -2602, 2,  0, -1,  2 ],
    [   -2348, 1,  0,  1,  0 ],
    [   -2120, 0,  1,  2,  0 ],
    [    2048, 2, -2, -1,  0 ],
    [   -1595, 2,  0,  0,  2 ],
    [   -1110, 0,  0,  2,  2 ],
    [    -810, 2,  1,  1,  0 ],
    [    -713, 0,  2, -1,  0 ],
    [     691, 2,  1, -2,  0 ],
    [     549, 4,  0,  1,  0 ],
    [     520, 4, -1,  0,  0 ],
    [    -399, 2,  1,  0, -2 ],
    [     351, 1,  1,  1,  0 ],
    [     330, 4,  0, -3,  0 ],
    [    -323, 0,  2,  1,  0 ],
    [     294, 2,  0,  3,  0 ],

    # right side of table 12.5 , [1] p192
    [ 1274027, 2,  0, -1,  0 ],
    [  213618, 0,  0,  2,  0 ],
    [ -114332, 0,  0,  0,  2 ],
    [   57066, 2, -1, -1,  0 ],
    [   45758, 2, -1,  0,  0 ],
    [  -34720, 1,  0,  0,  0 ],
    [   15327, 2,  0,  0, -2 ],
    [   10980, 0,  0,  1, -2 ],
    [   10034, 0,  0,  3,  0 ],
    [   -7888, 2,  1, -1,  0 ],
    [   -5163, 1,  0, -1,  0 ],
    [    4036, 2, -1,  1,  0 ],
    [    3861, 4,  0,  0,  0 ],
    [   -2689, 0,  1, -2,  0 ],
    [    2390, 2, -1, -2,  0 ],
    [    2236, 2, -2,  0,  0 ],
    [   -2069, 0,  2,  0,  0 ],
    [   -1773, 2,  0,  1, -2 ],
    [    1215, 4, -1, -1,  0 ],
    [    -892, 3,  0, -1,  0 ],
    [     759, 4, -1, -2,  0 ],
    [    -700, 2,  2, -1,  0 ],
    [     596, 2, -1,  0, -2 ],
    [     537, 0,  0,  4,  0 ],
    [    -487, 1,  0, -2,  0 ],
    [    -381, 0,  0,  2, -2 ],
    [    -340, 3,  0, -2,  0 ],
    [     327, 2, -1,  2,  0 ],
    [     299, 1,  1, -1,  0 ]
];

# [1] p.189
use constant NTH_NEW_MOON_CORRECTION_ARGS => [
    #        V  W   X  Y   Z
    [ -0.40720, 0,  0, 1,  0 ],
    [  0.01608, 0,  0, 2,  0 ],
    [  0.00739, 1, -1, 1,  0 ],
    [  0.00208, 2,  2, 0,  0 ],
    [ -0.00057, 0,  0, 1,  2 ],
    [ -0.00042, 0,  0, 3,  0 ],
    [  0.00038, 1,  1, 0, -2 ],
    [ -0.00007, 0,  2, 1,  0 ],
    [  0.00004, 0,  3, 0,  0 ],
    [  0.00003, 0,  0, 2,  2 ],
    [  0.00003, 0, -1, 1,  2 ],
    [ -0.00002, 0,  1, 3,  0 ],

    [  0.17241, 1,  1, 0,  0 ],
    [  0.01039, 0,  0, 0,  2 ],
    [ -0.00514, 1,  1, 1,  0 ],
    [ -0.00111, 0,  0, 1, -2 ],
    [  0.00056, 1,  1, 2,  0 ],
    [  0.00042, 1,  1, 0,  2 ],
    [ -0.00024, 1, -1, 2,  0 ],
    [  0.00004, 0,  0, 2, -2 ],
    [  0.00003, 0,  1, 1, -2 ],
    [ -0.00003, 0,  1, 1,  2 ],
    [ -0.00002, 0, -1, 1, -2 ],
    [  0.00002, 0,  0, 4,  0 ]
];

# [1] p.189
use constant NTH_NEW_MOON_ADDITIONAL_ARGS => [
    #      I          J         L
    [ 251.88,  0.016321, 0.000165 ],
    [ 349.42, 36.412478, 0.000126 ],
    [ 141.74, 53.303771, 0.000062 ],
    [ 154.84,  7.306860, 0.000056 ],
    [ 207.19,  0.121824, 0.000042 ],
    [ 161.72, 24.198154, 0.000037 ],
    [ 331.55,  3.592518, 0.000023 ],

    [ 251.83, 26.641886, 0.000164 ],
    [  84.66, 18.206239, 0.000110 ],
    [ 207.14,  2.453732, 0.000060 ],
    [  34.52, 27.261239, 0.000047 ],
    [ 291.34,  1.844379, 0.000040 ],
    [ 239.56, 25.513099, 0.000035 ]
];

__PACKAGE__->mk_classdata(cache => do {
    if (eval { require Cache::MemoryCache } && !$@) {
        my $namespace = __PACKAGE__;
        $namespace =~ s/::/-/g;
        Cache::MemoryCache->new( {
            namespace => $namespace,
            default_expires_in => $Cache::Cache::EXPIRES_NEVER
        })
    }
});

# [1] p190
sub lunar_longitude
{
    my $dt = shift;

    my $c = julian_centuries($dt);
    my $mean_moon = polynomial($c,
        218.3164591, 481267.88134236, -0.0013268,
        bigfloat(1) / 538841, bigfloat(-1) / 65194000);
    my $elongation = polynomial($c,
        297.8502042, 445267.1115168, -0.00163,
        bigfloat(1) / 545868, bigfloat(-1) / 113065000);
    my $solar_anomaly = polynomial($c,
        357.5291092, 35999.0502909, -0.0001536, bigfloat(1) / 24490000);
    my $lunar_anomaly = polynomial($c,
        134.9634114, 477198.8676313, 0.0008997,
        bigfloat(1) / 69699, bigfloat(-1) / 14712000);
    my $moon_node = polynomial($c,
        93.2720993, 483202.0175273, -0.0034029,
        bigfloat(-1) / 3526000, bigfloat(1) / 863310000);
    my $E = polynomial($c, 1, -0.002516, -0.0000074);

    my $big_ugly_number;
    my($v, $w, $x, $y, $z);
    foreach my $data (@{ LUNAR_LONGITUDE_ARGS() }) {
        ($v, $w, $x, $y, $z) = @$data;
        $big_ugly_number +=
            $v * (bigfloat($E) ** $x) * sin_deg(
                $w * $elongation + $x * $solar_anomaly +
                $y * $lunar_anomaly + $z * $moon_node);
    }

    my $correction = bigfloat(1 / 1000000) * $big_ugly_number;
    my $venus = bigfloat(3958 / 1000000) * sin_deg(119.75 + $c * 131.849);
    my $jupiter = bigfloat(318 / 1000000) * sin_deg(53.09 + $c * 479264.29);
    my $flat_earth = bigfloat(1962 / 1000000) *
        sin_deg($mean_moon - $moon_node);
    return mod(
        $mean_moon + $correction + $venus +
        $jupiter + $flat_earth + nutation($dt),
        360
    );
}

# [1] p.187
sub nth_new_moon
{
    my $n = shift;

    my $cache = __PACKAGE__->cache();
    my $p     = $cache && $cache->get($n);
    if ($p) {
        return $p;
    }

    my $k = $n - 24724;
    my $c = $k / 1236.85;
    my $approx = polynomial($c,
        730125.59765,
        MEAN_SYNODIC_MONTH * 1236.85,
        0.0001337,
        -0.000000150,
        0.00000000073);
    my $E = polynomial($c, 1, -0.002516, -0.0000074);
    my $solar_anomaly = polynomial($c,
        2.5534, 1236.85 * 29.10535669, -0.0000218, -0.00000011);
    my $lunar_anomaly = polynomial($c,
        201.5643, 385.81693528 * 1236.85,
        0.0107438,
        0.00001239,
        -0.000000058);
    my $moon_argument = polynomial($c,
        160.7108, 390.67050274 * 1236.85,
        -0.0016431, -0.00000227, 0.000000011);
    my $omega = polynomial($c,
        124.7746, -1.56375580 * 1236.85,
        0.0020691, 0.00000215);
    my $extra = 0.000325 * sin_deg(
        polynomial($c, 299.77, 132.8475848, -0.009173));
    my $correction = -0.00017 * sin_deg($omega);
    my $additional = 0;

    my($v, $w, $x, $y, $z);
    foreach my $data (@{ NTH_NEW_MOON_CORRECTION_ARGS() }) {
        ($v, $w, $x, $y, $z) = @$data;

        $correction += bigfloat($v) * ($E ** $w) * sin_deg(
            $x * $solar_anomaly +
            $y * $lunar_anomaly +
            $z * $moon_argument);
    }

    my($i, $j, $l);
    foreach my $data (@{ NTH_NEW_MOON_ADDITIONAL_ARGS() }) {
        ($i, $j, $l) = @$data;
        $additional += bigfloat($l) * sin_deg($i + $j * $k);
    }

    $p = dt_from_dynamical($approx + $correction + $extra + $additional);
    $cache->set($n, $p) if $cache;
    return $p;
}

# [1] p.192
sub lunar_phase
{
    my $dt = shift;
    return mod(
        lunar_longitude($dt) - DateTime::Util::Astro::Sun::solar_longitude($dt), 360);
}

1;

__END__

=head1 NAME

DateTime::Util::Astro::Moon - Functions To Calculate Lunar Data

=head1 SYNOPSIS

 use DateTime::Util::Astro::Moon 
       qw(nth_new_moon lunar_phase lunar_longitude);

 my $dt        = nth_new_moon(24773); # should be 2003/12/23 UTC
 my $phase     = lunar_phase($dt);
 my $longitude = lunar_longitude($dt);

=head1 DESCRIPTION

This module provides functions to calculate lunar data, but its main
focus is to provide just enough functionality that allows us to
create lunisolar calendars and other DateTime related modules.

This module is a *straight* port from "Calendrical Calculations" [1] --
and therefore there are places where things can probably be "fixed" so
that they look more like Perl, as well as places where we could
leverage the DateTime functionalities better. If you see things that
doesn't quite look right (in Perl), that's probably because of that.

=head2 Notes On Accuracy

Before you use this module, please be aware that this module was originally
created B<solely> for the purpose of creating a lunisolar calendar for
the DateTime project (http://datetime.perl.org). 

We used [1] as basis for our calculations. While for most purposes the
results are accurate enough, you should note that the calculations from
this book are I<approximations>. 

Obviously we would like to make this module as good as possible, but
there's only so much you can do in the accuracy department. However, having
L<GMP|http://www.swox.com/gmp> and Math::BigInt::GMP may help a little bit.

This module by default uses Perl's arbitrary precision calculation module
Math::BigFloat. However, this adds a fair amount of overhead, and you will
see a noticeable difference in execution speed. This is true even if you
use GMP.

=head2 Caching Results

DateTime::Util::Astro::Moon can use L<Cache::MemoryCache|Cache::MemoryCache> to cache results of certain functions.

This is always turned on. For example, nth_new_moon() is basically a constant
function for the given C<n>, and therefore should not need to recalculate
values ever again.

DateTime::Util::Astro::Moon uses L<Cache::Cache|Cache::Cache> for its cache
intetface, and by defaults to using L<Cache::MemoryCache|Cache::MemoryCache>.
If you would like to use a different type of cache, or tweak its behavior,
you can either assign or call methods on this cache object:

  DateTime::Util::Astro::Moon->cache($cache);
  my $cache = DateTime::Util::Astro::Moon->cache();

For example, if you want to forcibly expire this cache, do this:

  DateTime::Util::Astro::Moon->cache()->purge();

Or for maximum efficiency, you could use a FileCache with EXPIRES_NEVER set
on (new moons don't change from for a given $n, so it's safe to do this --
however, you probably want to clear it when you upgrade this module)

  DateTime::Util::Astro::Moon->cache(
    Cache::MemoryCache->new({
      namespace => 'MoonCache',
      default_expires_in => $Cache::Cache::EXPIRES_NEVER
    })
  );

=head1 CONSTANTS

=head2 MEAN_SYNODIC_MONTH

The mean time between new moons

=head1 FUNCTIONS

=head2 lunar_longitude($dt)

Given a DateTime object $dt, calculates the lunar longitude.

=head2 lunar_phase($dt)

Given a DateTime object $dt, calculates the lunar phase (in degrees)

=head2 nth_new_moon($n)

Given an integer $n, returns a DateTime object representing the moment
of $n-th new moon after R.D. 0. The 0th new moon was on January 11, 1
(Gregorian)

=head1 AUTHOR

Copyright (c) 2004-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

=head1 SEE ALSO

L<DateTime>
L<DateTime::Event::Lunar>
L<DateTime::Event::SolarTerm>
L<DateTime::Util::Astro::Common>
L<DateTime::Util::Astro::Sun>

=cut

