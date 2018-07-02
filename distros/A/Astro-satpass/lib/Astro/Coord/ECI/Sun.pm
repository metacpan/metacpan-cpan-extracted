=head1 NAME

Astro::Coord::ECI::Sun - Compute the position of the Sun.

=head1 SYNOPSIS

 use Astro::Coord::ECI;
 use Astro::Coord::ECI::Sun;
 use Astro::Coord::ECI::Utils qw{deg2rad};
 
 # 1600 Pennsylvania Ave, Washington DC USA
 # latitude 38.899 N, longitude 77.038 W,
 # altitude 16.68 meters above sea level
 my $lat = deg2rad (38.899);    # Radians
 my $long = deg2rad (-77.038);  # Radians
 my $alt = 16.68 / 1000;        # Kilometers
 my $sun = Astro::Coord::ECI::Sun->new ();
 my $sta = Astro::Coord::ECI->
     universal (time ())->
     geodetic ($lat, $long, $alt);
 my ($time, $rise) = $sta->next_elevation ($sun);
 print "Sun @{[$rise ? 'rise' : 'set']} is ",
     scalar gmtime $time, " UT\n";

Although this example computes the Sun rise or set in Washington D.C.
USA, the time is displayed in Universal Time. This is because I did not
want to complicate the example by adding machinery to convert the time
to the correct zone for Washington D.C. (which is UT - 5 except when
Summer Time is in effect, when it is UT - 4).

=head1 DESCRIPTION

This module implements the position of the Sun as a function of time, as
described in Jean Meeus' "Astronomical Algorithms," second edition. It
is a subclass of B<Astro::Coord::ECI>, with the id, name, and diameter
attributes initialized appropriately, and the time_set() method
overridden to compute the position of the Sun at the given time.


=head2 Methods

The following methods should be considered public:

=over

=cut

package Astro::Coord::ECI::Sun;

use strict;
use warnings;

our $VERSION = '0.099';

use base qw{Astro::Coord::ECI};

use Astro::Coord::ECI::Utils qw{:all};
use Carp;
use POSIX qw{ ceil floor strftime };

use constant MEAN_MAGNITUDE => -26.8;

my %attrib = (
    iterate_for_quarters	=> 1,
);

my %static = (
    id => 'Sun',
    name => 'Sun',
    diameter => 1392000,
    iterate_for_quarters	=> undef,
);

my $weaken = eval {
    require Scalar::Util;
    Scalar::Util->can('weaken');
};
my $object;

our $Singleton = $weaken;

=item $sun = Astro::Coord::ECI::Sun->new();

This method instantiates an object to represent the coordinates of the
Sun. This is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>, with
the id and name attributes set to 'Sun', and the diameter attribute set
to 1392000 km per Jean Meeus' "Astronomical Algorithms", 2nd Edition,
Appendix I, page 407.

Any arguments are passed to the set() method once the object has been
instantiated. Yes, you can override the "hard-wired" id, name, and so
forth in this way.

If $Astro::Coord::ECI::Sun::Singleton is true, you get a singleton
object; that is, only one object is instantiated and subsequent calls
to new() just return that object. This only works if Scalar::Util
exports weaken(). If it does not, the setting of
$Astro::Coord::ECI::Sun::Singleton is silently ignored. The default
is true if Scalar::Util can be loaded and exports weaken(), and false
otherwise.

=cut

sub new {
    my ($class, @args) = @_;
    ref $class and $class = ref $class;
    if ( $Singleton && $weaken && __classisa( $class, __PACKAGE__ ) ) {
	if ($object) {
	    $object->set (@args) if @args;
	    return $object;
	} else {
	    my $self = $object = $class->SUPER::new (%static, @args);
	    $weaken->($object);
	    return $self;
	}
    } else {
	return $class->SUPER::new (%static, @args);
    }
}


=item @almanac = $sun->almanac( $station, $start, $end );

This method produces almanac data for the Sun for the given observing
station, between the given start and end times. The station is assumed
to be Earth-Fixed - that is, you can't do this for something in orbit.

The C<$station> argument may be omitted if the C<station> attribute has
been set. That is, this method can also be called as

 @almanac = $sun->almanac( $start, $end )

The start time defaults to the current time setting of the $sun
object, and the end time defaults to a day after the start time.

The almanac data consists of a list of list references. Each list
reference points to a list containing the following elements:

 [0] => time
 [1] => event (string)
 [2] => detail (integer)
 [3] => description (string)

The @almanac list is returned sorted by time.

The following events, details, and descriptions are at least
potentially returned:

 horizon: 0 = Sunset, 1 = Sunrise;
 transit: 0 = local midnight, 1 = local noon;
 twilight: 0 = end twilight, 1 = begin twilight;
 quarter: 0 = spring equinox, 1 = summer solstice,
          2 = fall equinox, 3 = winter solstice.

Twilight is calculated based on the current value of the twilight
attribute of the $sun object. This attribute is inherited from
L<Astro::Coord::ECI|Astro::Coord::ECI>, and documented there.

=cut

sub __almanac_event_type_iterator {
    my ( $self, $station ) = @_;

    my $inx = 0;

    my $horizon = $station->__get_almanac_horizon();

    my @events = (
	[ $station, next_elevation => [ $self, $horizon, 1 ], 'horizon',
		[ 'Sunset', 'Sunrise' ] ],
	[ $station, next_meridian => [ $self ], 'transit',
		[ 'local midnight', 'local noon' ] ],
	[ $station, next_elevation =>
	    [ $self, $self->get( 'twilight' ) + $horizon, 0 ],
		'twilight', ['end twilight', 'begin twilight'] ],
	[ $self, next_quarter => [], 'quarter', '__quarter_name', ],
    );

    return sub {
	$inx < @events
	    and return @{ $events[$inx++] };
	return;
    };
}

use Astro::Coord::ECI::Mixin qw{ almanac };

=item @almanac = $sun->almanac_hash( $station, $start, $end );

This convenience method wraps $sun->almanac(), but returns a list of
hash references, sort of like Astro::Coord::ECI::TLE->pass()
does. The hashes contain the following keys:

  {almanac} => {
    {event} => the event type;
    {detail} => the event detail (typically 0 or 1);
    {description} => the event description;
  }
  {body} => the original object ($sun);
  {station} => the observing station;
  {time} => the time the quarter occurred.

The {time}, {event}, {detail}, and {description} keys correspond to
elements 0 through 3 of the list returned by almanac().

=cut

use Astro::Coord::ECI::Mixin qw{ almanac_hash };

=item $elevation = $tle->correct_for_refraction( $elevation )

This override of the superclass' method simply returns the elevation
passed to it. I have no algorithm for refraction at the surface of the
photosphere or anywhere else in the environs of the Sun, and explaining
why I make no correction at all seemed easier than explaining why I make
an incorrect correction.

See the L<Astro::Coord::ECI|Astro::Coord::ECI> C<azel()> and
C<azel_offset()> documentation for whether this class'
C<correct_for_refraction()> method is actually called by those methods.

=cut

sub correct_for_refraction {
    my ( undef, $elevation ) = @_;	# Invocant unused
    return $elevation;
}


=item $long = $sun->geometric_longitude ()

This method returns the geometric longitude of the Sun in radians at
the last time set.

=cut

sub geometric_longitude {
    my $self = shift;
    croak <<eod unless defined $self->{_sun_geometric_longitude};
Error - You must set the time of the Sun object before the geometric
        longitude can be returned.
eod

    return $self->{_sun_geometric_longitude};
}

sub get {
    my ( $self, @args ) = @_;
    my @rslt;
    foreach my $name ( @args ) {
	push @rslt, $attrib{$name} ?
	    ref $self ? $self->{$name} : $static{$name} :
	    $self->SUPER::get( $name );
    }
    return wantarray ? @rslt : $rslt[0];
}


=item ($point, $intens, $central) = $sun->magnitude ($theta, $omega);

This method returns the magnitude of the Sun at a point $theta radians
from the center of its disk, given that the disk's angular radius
(B<not> diameter) is $omega radians. The returned $point is the
magnitude at the given point (undef if $theta > $omega), $intens is the
ratio of the intensity at the given point to the central intensity (0
if $theta > $omega), and $central is the central magnitude.

If this method is called in scalar context, it returns $point, the point
magnitude.

If the $omega argument is omitted or undefined, it is calculated based
on the geocentric range to the Sun at the current time setting of the
object.

If the $theta argument is omitted or undefined, the method returns
the average magnitude of the Sun, which is taken to be -26.8.

The limb-darkening algorithm and the associated constants come from
L<http://en.wikipedia.org/wiki/Limb_darkening>.

For consistency's sake, an observing station can optionally be passed as
the first argument (i.e. before C<$theta>). This is currently ignored.

=cut

{	# Begin local symbol block

    my $central_mag;
    my @limb_darkening = (.3, .93, -.23);

    sub magnitude {
	my ( $self, @args ) = @_;
	# We want to accept a station as the second argument for
	# consistency's sake, though we do not (at this point) use it.
	embodies( $args[0], 'Astro::Coord::ECI' )
	    and shift @args;
	my ( $theta, $omega ) = @args;
	return MEAN_MAGNITUDE unless defined $theta;
	unless (defined $omega) {
	    my @eci = $self->eci ();
	    $omega = $self->get ('diameter') / 2 /
		sqrt (distsq (\@eci[0 .. 2], [0, 0, 0]));
	}
	unless (defined $central_mag) {
	    my $sum = 0;
	    my $quotient = 2;
	    foreach my $a (@limb_darkening) {
		$sum += $a / $quotient++;
	    }
	    $central_mag = MEAN_MAGNITUDE - intensity_to_magnitude (2 * $sum);
	}
	my $intens = 0;
	my $point;
	if ($theta < $omega) {
	    my $costheta = cos ($theta);
	    my $cosomega = cos ($omega);
	    my $sinomega = sin ($omega);
	    my $cospsi = sqrt ($costheta * $costheta -
		    $cosomega * $cosomega) / $sinomega;
	    my $psiterm = 1;
	    foreach my $a (@limb_darkening) {
		$intens += $a * $psiterm;
		$psiterm *= $cospsi;
	    }
	    $point = $central_mag + intensity_to_magnitude ($intens);
	}
	return wantarray ? ($point, $intens, $central_mag) : $point;
    }
}	# End local symbol block.

=item ($time, $quarter, $desc) = $sun->next_quarter($want);

This method calculates the time of the next equinox or solstice after
the current time setting of the $sun object. The return is the time,
which equinox or solstice it is as a number from 0 (March equinox) to 3
(December solstice), and a string describing the equinox or solstice. If
called in scalar context, you just get the time.

If the C<station> attribute is not set or set to a location on or north
of the Equator, the descriptor strings are

 0 - Spring equinox
 1 - Summer solstice
 2 - Fall equinox
 3 - Winter solstice

If the C<station> attribute is set to a location south of the Equator,
the descriptor strings are

 0 - Fall equinox
 1 - Winter solstice
 2 - Spring equinox
 3 - Summer solstice

The optional $want argument says which equinox or solstice you want, as
a number from 0 through 3.

As a side effect, the time of the $sun object ends up set to the
returned time.

As of version 0.088_01, the algorithm given in Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 27 ("Equinoxes and Solstices"), pages
278ff is used. This should be good for the range -1000 to 3000
Gregorian, and good to within a minute or so within the range 1951 to
2050 Gregorian, but the longitude of the Sun at the calculated time may
be as much as 0.01 degree off the exact time for the event.

If you take the United States Naval Observatory's times (given to the
nearest minute) as the standard, the maximum deviation from that
standard in the range 1700 to 2100 is 226 seconds. I have no information
on this algorithm's accuracy outside that range. I<Caveat user.>.

In version 0.088 and before, this calculation was done by successive
approximation based on the position of the Sun, and was good to about 15
minutes.

If you want the old iterative version back, set attribute
C<iterate_for_quarters> to a true value.

=cut

use constant NEXT_QUARTER_INCREMENT => 86400 * 85;	# 85 days.

*__next_quarter_coordinate = __PACKAGE__->can( 
    'ecliptic_longitude' );

# use Astro::Coord::ECI::Mixin qw{ next_quarter };

sub next_quarter {
    my ( $self, $quarter ) = @_;
    $self->{iterate_for_quarters}
	and goto &Astro::Coord::ECI::Mixin::next_quarter;
    my $time = $self->universal();
    my $year = ( gmtime( $time ) )[5] + 1900;
    my $season;
    if ( defined $quarter ) {
	# I can't think of an edge case that makes the first calculation
	# give a quarter that is too late. Wish that made me feel better
	# than it in fact does.
	$season = $self->season( $year, $quarter );
	$season < $time
	    and $season = $self->season( $year + 1, $quarter );
	$self->universal( $season );
    } else {
	my ( undef, $lon ) = $self->ecliptic();
	# The fudged-in 359 is because I am worried about the limited
	# accuracy of the longitude calculation causing me to pick the
	# wrong quarter. So I essentially back the Sun up by about a
	# day. That may indeed put me a quarter too early, but I have to
	# check for that anyway because of the accuracy (or lack
	# thereof) of the calculated longitude.
	$quarter = ceil( ( rad2deg( $lon ) + 359 ) / 90 ) % 4;
	$season = $self->season( $year, $quarter );
	# If we're a quarter too early, add one and repeat the
	# calculation. We shouldn't have to do this more than once,
	# since our maximum error even with the fudge factor is a day.
	if ( $season < $time ) {
	    $quarter++;
	    if ( $quarter > 3 ) {
		$quarter -= 4;
		$year++;
	    }
	    $season = $self->season( $year, $quarter );
	}
    }
    $season = ceil( $season );	# Make sure we're AFTER.
    $self->universal( $season );
    return wantarray ? ( $season, $quarter, $self->__quarter_name(
	    $quarter ) ) : $season;
}

=item $hash_reference = $sun->next_quarter_hash($want);

This convenience method wraps $sun->next_quarter(), but returns the
data in a hash reference, sort of like Astro::Coord::ECI::TLE->pass()
does. The hash contains the following keys:

  {body} => the original object ($sun);
  {almanac} => {
    {event} => 'quarter',
    {detail} => the quarter number (0 through 3);
    {description} => the quarter description;
  }
  {time} => the time the quarter occurred.

The {time}, {detail}, and {description} keys correspond to elements 0
through 2 of the list returned by next_quarter().

=cut

use Astro::Coord::ECI::Mixin qw{ next_quarter_hash };

=item $period = $sun->period ()

Although this method is attached to an object that represents the
Sun, what it actually returns is the sidereal period of the Earth,
per Appendix I (pg 408) of Jean Meeus' "Astronomical Algorithms,"
2nd edition.

=cut

sub period {return 31558149.7632}	# 365.256363 * 86400

{

    my @quarters = ('Spring equinox', 'Summer solstice',
	'Fall equinox', 'Winter solstice');

    sub __quarter_name {
	my ( $self, $quarter, $name ) = @_;
	$name ||= \@quarters;
	my $station;
	$station = $self->get( 'station' )
	    and ( $station->geodetic() )[0] < 0
	    and $quarter = ( $quarter + @{ $name } / 2 ) % @{ $name };
	return $name->[$quarter];
    }
}

=begin comment

=item $time = $self->season( $year, $season );

This method calculates the time of the given season of the given
Gregorian year. The $season is an integer from 0 to 3, with 0 being the
astronomical Spring equinox (first point of Aries), and so on.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 27 ("Equinoxes and Solstices), pages 278ff.

THIS METHOD IS UNSUPPORTED. I understand the temptation to call it if
all you want are the seasons, but if possible I would like to be able to
remove it if its use in next_quarter() turns out to e a bad idea. I am
not unwilling to support it; if you want me to, please contact me.

Because it is unsupported, its name may change without warning if
L<Test::Pod::Coverage|Test::Pod::Coverage> becomes smart enough to
realize that the =begin/end comment markers mean that this method is not
documented after all.

=end comment

=cut

sub season {
    my ( $self, $year, $season ) = @_;
    my ( $Y, $d ) = $year < 1000 ? (
	$year / 1000,
	[	# Meeus table 27 A
	    [ -0.00071,  0.00111,  0.06134, 365242.13740, 1721139.29189 ],
	    [  0.00025,  0.00907, -0.05323, 365241.72562, 1721233.25401 ],
	    [  0.00074, -0.00297, -0.11677, 365242.49558, 1721325.70455 ],
	    [ -0.00006, -0.00933, -0.00769, 365242.88257, 1721414.39987 ],
	]->[ $season ],
    ) : (
	( $year - 2000 ) / 1000,
	[	# Meeus table 27 B
	    [ -0.00057, -0.00411,  0.05169, 365242.37404, 2451623.80984 ],
	    [ -0.00030,  0.00888,  0.00325, 365241.62603, 2451716.56767 ],
	    [  0.00078,  0.00337, -0.11575, 365242.01767, 2451810.21715 ],
	    [  0.00032, -0.00823, -0.06223, 365242.74049, 2451900.05952 ],
	]->[ $season ],
    );
    my $JDE0 = ( ( ( $d->[0] * $Y + $d->[1] ) * $Y + $d->[2] ) * $Y +
	$d->[3] ) * $Y + $d->[4];
    my $T = ( $JDE0 - 2451545.0 ) / 36525;
    $self->{debug}
	and print "Debug - T = $T\n";
    my $W = mod2pi( deg2rad( 35999.373 * $T - 2.47 ) );
    my $delta_lambda = 1 + 0.0334 * cos( $W ) + 0.0007 * cos( 2 * $W );
    $self->{debug}
	and print "Debug - delta lambda = $delta_lambda\n";
    my $S = 0;
    foreach my $term (	# Meeus table 27 C
	[ 485, 324.96,   1934.136 ],
	[ 203, 337.23,  32964.467 ],
	[ 199, 342.08,     20.186 ],
	[ 182,  27.85, 445267.112 ],
	[ 156,  73.14,  45036.886 ],
	[ 136, 171.52,  22518.443 ],
	[  77, 222.54,  65928.934 ],
	[  74, 296.72,   3034.906 ],
	[  70, 243.58,   9037.513 ],
	[  58, 119.81,  33718.147 ],
	[  52, 297.17,    150.678 ],
	[  50,  21.02,   2281.226 ],
	[  45, 247.54,  29929.562 ],
	[  44, 325.15,  31555.956 ],
	[  29,  60.93,   4443.417 ],
	[  18, 155.12,  67555.328 ],
	[  17, 288.79,   4562.452 ],
	[  16, 198.04,  62894.029 ],
	[  14, 199.76,  31436.921 ],
	[  12,  95.39,  14577.848 ],
	[  12, 287.11,  31931.756 ],
	[  12, 320.81,  34777.259 ],
	[   9, 227.73,   1222.114 ],
	[   8,  15.45,  16859.074 ],
    ) {
	$S += $term->[0] * cos( mod2pi( deg2rad( $term->[1] + $term->[2]
		    * $T ) ) );
    }
    $self->{debug}
	and print "Debug - S = $S\n";
    my $JDE = 0.00001 * $S / $delta_lambda + $JDE0;
    $self->{debug}
	and print "Debug - JDE = $JDE\n";
    my $time = ( $JDE - JD_OF_EPOCH ) * SECSPERDAY;
    # Note that gmtime() in the following needs the parens because it
    # might have come from Time::y2038, which appears to take more than
    # one argument -- even though, as I read it, its prototype is (;$).
    $self->{debug}
	and print "Debug - dynamical date is ", scalar gmtime( $time ), "\n";
    return $time - dynamical_delta( $time );	# Not quite right.
}

sub set {
    my ( $self, @args ) = @_;
    while ( @args ) {
	my ( $name, $val ) = splice @args, 0, 2;
	if ( $attrib{$name} ) {
	    if ( ref $self ) {
		$self->{$name} = $val;
	    } else {
		$static{$name} = $val;
	    }
	} else {
	    $self->SUPER::set( $name, $val );
	}
    }
    return $self;
}


=item $sun->time_set ()

This method sets coordinates of the object to the coordinates of the
Sun at the object's currently-set universal time.  The velocity
components are arbitrarily set to 0. The 'equinox_dynamical' attribute
is set to the object's currently-set dynamical time.

Although there's no reason this method can't be called directly, it
exists to take advantage of the hook in the B<Astro::Coord::ECI>
object, to allow the position of the Sun to be computed when the
object's time is set.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 25, pages 163ff.

=cut

#	The following constants are used in the time_set() method,
#	because Meeus' equations are in degrees, I was too lazy
#	to hand-convert them to radians, but I didn't want to
#	penalize the user for the conversion every time.


use constant SUN_C1_0 => deg2rad (1.914602);
use constant SUN_C1_1 => deg2rad (-0.004817);
use constant SUN_C1_2 => deg2rad (-0.000014);
use constant SUN_C2_0 => deg2rad (0.019993);
use constant SUN_C2_1 => deg2rad (0.000101);
use constant SUN_C3_0 => deg2rad (0.000289);
use constant SUN_LON_2000 => deg2rad (- 0.01397);

sub time_set {
    my $self = shift;
    my $time = $self->dynamical;

#	The following algorithm is from Meeus, chapter 25, page, 163 ff.

    my $T = jcent2000 ($time);				# Meeus (25.1)
    my $L0 = mod2pi(deg2rad((.0003032 * $T + 36000.76983) * $T	# Meeus (25.2)
	    + 280.46646));
    my $M = mod2pi(deg2rad(((-.0001537) * $T + 35999.05029)	# Meeus (25.3)
	    * $T + 357.52911));
    my $e = (-0.0000001267 * $T - 0.000042037) * $T + 0.016708634;# Meeus (25.4)
    my $C  = ((SUN_C1_2 * $T + SUN_C1_1) * $T + SUN_C1_0) * sin ($M)
	    + (SUN_C2_1 * $T + SUN_C2_0) * sin (2 * $M)
	    + SUN_C3_0 * sin (3 * $M);
    my $O = $self->{_sun_geometric_longitude} = $L0 + $C;
    my $omega = mod2pi (deg2rad (125.04 - 1934.136 * $T));
    my $lambda = mod2pi ($O - deg2rad (0.00569 + 0.00478 * sin ($omega)));
    my $nu = $M + $C;
    my $R = (1.000_001_018 * (1 - $e * $e)) / (1 + $e * cos ($nu))
	    * AU;
    $self->{debug} and print <<eod;
Debug sun - @{[strftime '%d-%b-%Y %H:%M:%S', gmtime( $time )]}
    T  = $T
    L0 = @{[_rad2deg ($L0)]} degrees
    M  = @{[_rad2deg ($M)]} degrees
    e  = $e
    C  = @{[_rad2deg ($C)]} degrees
    O  = @{[_rad2deg ($O)]} degrees
    R  = @{[$R / AU]} AU
    omega = @{[_rad2deg ($omega)]} degrees
    lambda = @{[_rad2deg ($lambda)]} degrees
eod

    $self->ecliptic (0, $lambda, $R);
    ## $self->set (equinox_dynamical => $time);
    $self->equinox_dynamical ($time);
    return $self;
}

# The Sun is normally positioned in inertial coordinates.

sub __initial_inertial { return 1 }

1;

=back

=head2 Attributes

This class has the following public attributes. The description gives
the data type.

=over

=item iterate_for_quarters (Boolean)

If this attribute is true, the C<next_quarter()> method uses the old
(pre-0.088_01) algorithm.

If this attribute is false, the new algorithm is used.

The default is C<undef>, i.e. false, because I believe the new algorithm
to be more accurate for reasonably-current times.

This attribute is new with version 0.088_01.

=back

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge Jean Meeus, whose book "Astronomical
Algorithms" (second edition) formed the basis for this module.

=head1 SEE ALSO

The L<Astro::Coord::ECI::OVERVIEW|Astro::Coord::ECI::OVERVIEW>
documentation for a discussion of how the pieces/parts of this
distribution go together and how to use them.

L<Astro::MoonPhase|Astro::MoonPhase> by Brett Hamilton, which contains a
function-based module to compute the current phase, distance and angular
diameter of the Moon, as well as the angular diameter and distance of
the Sun.

L<Astro::Sunrise|Astro::Sunrise> by Ron Hill and Jean Forget, which
contains a function-based module to compute sunrise and sunset for the
given day and location.

L<Astro::SunTime|Astro::SunTime> by Rob Fugina, which provides
functionality similar to B<Astro-Sunrise>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
