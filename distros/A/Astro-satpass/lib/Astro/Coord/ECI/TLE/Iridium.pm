=head1 NAME

Astro::Coord::ECI::TLE::Iridium - Compute behavior of Iridium satellites

=head1 SYNOPSIS

The following is a semi-brief script to calculate Iridium flares. You
will need to substitute your own location where indicated.

 use Astro::SpaceTrack;
 use Astro::Coord::ECI;
 use Astro::Coord::ECI::TLE;
 use Astro::Coord::ECI::Utils qw{deg2rad rad2deg};

 # 1600 Pennsylvania Avenue, Washington DC, USA
 my $your_north_latitude_in_degrees = 38.898748;
 my $your_east_longitude_in_degrees = -77.037684;
 my $your_height_above_sea_level_in_meters = 16.68;
 
 # Create object representing the observers' location.
 # Note that the input to geodetic() is latitude north
 # and longitude west, in RADIANS, and height above sea
 # level in KILOMETERS.
 
 my $loc = Astro::Coord::ECI->geodetic (
    deg2rad ($your_north_latitude_in_degrees),
    deg2rad ($your_east_longitude_in_degrees),
    $your_height_above_sea_level_in_meters/1000);
 
 # Get all the Iridium data from CelesTrak; it is direct-
 # fetched, so no password is needed.
 
 my $st = Astro::SpaceTrack->new (direct => 1);
 my $data = $st->celestrak ('iridium');
 $data->is_success or die $data->status_line;
 
 # Parse the fetched data, yielding Iridium objects.
 
 my @sats = Astro::Coord::ECI::TLE->parse ($data->content);
 
 # We want flares for the next 2 days. In order to try to
 # duplicate http://www.heavens-above.com/ as closely as
 # possible, we throw away daytime flares dimmer than -6,
 # and nighttime flares dimmer than -1. We also calculate
 # flares for spares, and assume night is any time the Sun
 # is below the horizon.
 
 my $start = time ();
 my $finish = $start + 2 * 86400;
 my @flares;
 my %mag_limit = (am => -1, day => -6, pm => -1);
 foreach my $irid (@sats) {
    $irid->can_flare (1) or next;
    $irid->set (twilight => 0);
    foreach my $flare ($irid->flare ($loc, $start, $finish)) {
        $flare->{magnitude} <= $mag_limit{$flare->{type}}
	    and push @flares, $flare;
    }
 }
 print <<eod;
      Date/Time          Satellite        Elevation  Azimuth Magnitude
 eod
 foreach my $flare (sort {$a->{time} <=> $b->{time}} @flares) {
 
 # If we wanted to make use of the Iridium object that
 # produced the flare (e.g. to get apparant equatorial
 # coordinates) we would need to set the time first.
 ## $flare->{body}->universal ($flare->{time});
 
 #  The returned angles are in radians, so we need to
 #  convert back to degrees.
 
    printf "%s %-15s %9.1f %9.1f %5.1f\n",
        scalar localtime $flare->{time},
        $flare->{body}->get ('name'),
	rad2deg ($flare->{elevation}),
	rad2deg ($flare->{azimuth}),
	$flare->{magnitude};
 }

=head1 NOTICE -- IRIDIUM SUPPORT

As of early 2017 the flaring Iridium satellites are being taken out of
service, to be replaced by non-flaring Iridium Next satellites. Once the
flaring Iridium satellites are out of service, I plan to deprecate and
remove all functionality relating to the acquisition of Iridium status.

I have not yet decided on the disposition of
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium>. My
thought at the moment is that it will be moved to its own package rather
than deleted, because the flare functionality may be of historical
interest. By the same reasoning, the TLE parsing logic in
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> will remain able to
rebless satellites as Iridium, but the canned status will be 'tumbling'.

=head1 DESCRIPTION

This class is a subclass of
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE>, representing
original-design Iridium satellites. This class will probably B<not> work
for the Iridium Next satellites, which are being launched starting early
2017.

The C<< Astro::Coord::ECI::TLE->parse() >> method makes use of
built-in data to determine which satellites to rebless into this class,
based on the object's NORAD SATCAT ID. This internal data can be
modified using the Astro::Coord::ECI::TLE->status method to correct
errors or for historical research. It is also possible to get an Iridium
object by calling $tle->rebless (iridium => {status => $status})
directly.

What this subclass adds is the ability to generate information on
Iridium flares (or glints, as they are also called). Members of this
class are considered capable of generating flares based on their status,
as follows:

 0 => in service
 1 => spare (may or may not flare)
 2 => failed - no predictable flares.

CelesTrak-style statuses ('+', 'S', and '-' respectively) are accepted
on input. See L<Astro::SpaceTrack|Astro::SpaceTrack> method
iridium_status for a way to get current Iridium constellation status.

=head2 Methods

This class adds the following public methods:

=over

=cut

package Astro::Coord::ECI::TLE::Iridium;

use strict;
use warnings;

use base qw{Astro::Coord::ECI::TLE};

our $VERSION = '0.088';

use Astro::Coord::ECI::Sun;
use Astro::Coord::ECI::Utils qw{:all};
use Carp;
use POSIX qw{floor strftime};	# For debugging

use constant ATTRIBUTE_KEY => '_sub_TLE_Iridium';
use constant DEFAULT_MAX_MIRROR_ANGLE => deg2rad (10);
use constant MMAAREA => 1.88 * .86;	# Area of MMA, in square meters.
use constant MMAPHI => deg2rad (-130);	# The MMAs are at an angle of
					# 40 degrees to the axis, so
					# we need to lay them back 130
					# degrees (90 + 40) to make
					# them "flat".
use constant TWOPIOVER3 => TWOPI / 3;	# 120 degrees, in radians.

use constant BODY_STATUS_IS_OPERATIONAL	=> 0;
use constant BODY_STATUS_IS_SPARE	=> 1;
use constant BODY_STATUS_IS_TUMBLING	=> 2;
use constant BODY_STATUS_IS_DECAYED	=> 3;

my %mutator = (
    algorithm => sub {
	my ( $self, $name, $value ) = @_;
	my $method = "_flare_$value";
	croak "Error - Unknown flare algorithm name $value"
	    unless $self->can ($method);
	$self->{&ATTRIBUTE_KEY}{$name} = $value;
	$self->{&ATTRIBUTE_KEY}{_algorithm_method} = $method;
    },
    status	=> \&_set_operational_status,
);
foreach my $key (qw{am day extinction max_mirror_angle pm status zone}) {
    $mutator{$key} = sub {$_[0]->{&ATTRIBUTE_KEY}{$_[1]} = $_[2]};
}

my %accessor = ();
foreach my $key (keys %mutator) {
    $accessor{$key} ||= sub {$_[0]->{&ATTRIBUTE_KEY}{$_[1]}}
}

my %static = (		# static values
    algorithm => 'fixed',
    am => 1,
    day => 1,
    extinction => 1,
    intrinsic_magnitude	=> 7.0,
    max_mirror_angle => DEFAULT_MAX_MIRROR_ANGLE,
    pm => 1,
    status => '',
    zone	=> undef,	# Offset from GMT, in seconds
);

my %statatr = (		# for convenience of get() and put().
    &ATTRIBUTE_KEY => \%static,
);

__PACKAGE__->alias (iridium => __PACKAGE__);


#	Pre-compute the transform vectors for each of the three Main
#	Mission Antennae, so that we do not have to repeatedly compute
#	the sin and cos of the relevant angles. The transform we are
#	doing is a rotation of theta radians about the Z axis (theta
#	being Main Mission Antenna index * 2 * PI / 3) to face the
#	MMA in the X direction, followed by a rotation of phi radians
#	about the Y axis (phi being -130 degrees) to lay the MMA back
#	into the X-Y plane.

#	Although we are using vector math for the actual operation, the
#	transform vectors are derived using matrix math, with the
#	resultant matrix being decomposed into the row vectors we need.
#	The actual computation is to premultiply the theta transform
#	matrix by the phi transform matrix:

#	+-                       -+     +-                           -+
#	|  cos(phi)  0  sin(phi)  |     |  cos(theta) -sin(theta)  0  |
#	|    0       1    0       |  X  |  sin(theta)  cos(theta)  0  |
#	| -sin(phi)  0  cos(phi)  |     |    0           0         1  |
#	+-                       -+     +-                           -+

#	  +-                                                        -+
#	  |  cos(theta) * cos(phi)  -sin(theta) * cos(phi)  sin(phi) |
#	= |  sin(theta)              cos(theta)             0        |
#	  | -cos(theta) * sin(phi)   sin(theta) * sin(phi)  cos(phi) |
#	  +-                                                        -+


my @transform_vector;
{	# Begin local symbol block.
my $cosphi = cos (MMAPHI);
my $sinphi = sin (MMAPHI);

foreach my $mma (0 .. 2) {
    my $theta = $mma * TWOPIOVER3;
    my $costheta = $theta ? cos ($theta) : 1;
    my $sintheta = $theta ? sin ($theta) : 0;

    push @transform_vector,
	[   [$costheta * $cosphi, - $sintheta * $cosphi, $sinphi],
	    [$sintheta, $costheta, 0],
	    [- $costheta * $sinphi, $sintheta * $sinphi, $cosphi],
	];
    }
}	# End local symbol block.


#	We also pre-compute the inverse transforms, to facilitate the
#	recovery of the virtual image of the illuminating body.

my @inverse_transform_vector =
    map {scalar _invert_matrix_list (@$_)} @transform_vector;


#	Various things we will share.

my $sun;	# For an Astro::Coord::ECI::Sun object.


=item $tle->after_reblessing (\%attribs);

This method supports reblessing into a subclass, with the argument
representing attributes that the subclass may wish to set. It is called
by rebless() and should not be called by the user.

At this level of the inheritance hierarchy, it sets the status of the
object from the {status} key of the given hash. If this key is absent,
the object is assumed capable of generating flares.

=cut

{
    # This seems to me to be a bit of a crock, but I can think of no
    # other way to prevent the intrinsic_magnitude from being clobbered
    # as not relevant to the class.
    my %retain = map { $_ => 1 }
	qw{ intrinsic_magnitude }, keys %mutator;

    sub after_reblessing {
	my ($self, $attrs) = @_;
	if (defined $attrs) {
	    $attrs = {%$attrs};
	} else {
	    $attrs = {};
	}
	ref $attrs eq 'HASH' or croak <<eod;
Error - The argument of after_reblessing(), if any, must be a hash
	reference.
eod
	foreach my $key (keys %static) {
	    $attrs->{$key} = $static{$key} unless defined $attrs->{$key};
	}
	foreach my $key (keys %$attrs) {
	    delete $attrs->{$key} unless $retain{$key};
	}
	$self->set (%$attrs);
	return;
    }
}


#	see Astro::Coord::ECI->attribute ();


sub attribute {
    my ($self, $name) = @_;
    return exists $accessor{$name} ?
	__PACKAGE__ :
	$self->SUPER::attribute ($name);
}


=item $tle->before_reblessing ()

This method supports reblessing into a subclass. It is intended to do
any cleanup the old class needs before reblessing into the new class. It
is called by rebless(), and should not be called by the user.

At this level of the inheritance hierarchy, it removes the status
attribute.

=cut

sub before_reblessing {
    my ($self) = @_;
    delete $self->{&ATTRIBUTE_KEY};
    return;
}


=item $tle->can_flare ($spare);

This method returns true (in the Perl sense) if the object is capable
of producing flares, and false otherwise. If the optional $spare
argument is true, spares are considered capable of flaring, otherwise
not. If C<$spare> is C<'all'>, then all objects are considered capable
of flaring.

=cut

sub can_flare {
    my ( $self, $spare ) = @_;
    defined $spare
	and 'all' eq $spare
	and return 1;
    my $status = $self->get ('status');
    return !$status || $spare && $status == $self->BODY_STATUS_IS_SPARE;
}


=item @flares = $tle->flare ($sta, $start, $end);

This method returns the list of flares produced by the given Iridium
satellite at the given station between the given start time and the
given end time. This list may be empty. If called in scalar context you
get the number of flares.

All arguments are optional, with the defaults being

 $station = the 'station' attribute
 $start = time()
 $end = $start + 1 day

Each flare is represented by a reference to an anonymous hash, with
elements as follows:

 angle => Mirror angle, radians
 appulse => information about the position of the Sun
   angle => distance from Sun to flare, radians
   body => reference to the Sun object
 area => Projected MMA area, square radians
 azimuth => Azimuth of flare, radians
 body => Reference to object producing flare
 center => information about the center of the flare
   body => location of the center of the flare
   magnitude => estimated magnitude at the center
 elevation => Elevation of flare, radians
 magnitude => Estimated magnitude
 mma => Flaring mma (0, 1, or 2)
 range => Range to flare, kilometers
 specular => True if specular reflection
 station => reference to the observer's location
 status => ''
 type => Type of flare (see notes)
 time => Time of flare
 virtual_image => Location of virtual image

Note that:

* The time of the object passed in the {body} element is not
necessarily set to the time of the flare.

* The {center}{body} element contains an Astro::Coord::ECI object
set to the location of the center of the flare at the given time.
The center is defined as the intersection of the plane of the
observer's horizon with the line from the virtual image of the
illuminating body through the flaring satellite.

* The {mma} element indicates which Main Mission Antenna generated
the flare. The antennae are numbered clockwise (looking down on the
vehicle) from the front, so 0, 1, and 2 correspond to Heavens Above's
'Front', 'Right', and 'Left' respectively.

* The {specular} element is actually the limb darkening factor if
applicable. Otherwise, it is 1 if the reflection is specular, and 0 if
not.

* The {status} key is reserved for an explanation of why there is no
flare. When the hash is generated by the flare() method, this key will
always be false (in the Perl sense).

* The {type} element contains 'day' if the flare occurs between the
beginning of twilight in the morning and the end of twilight in the
evening, 'am' if the flare is after midnight but not during the day,
and 'pm' if the flare is before midnight but not during the day.

* The {virtual_image} element is an Astro::Coord::ECI object
representing the location of the virtual image of the illuminator
at the time of the flare.

Why does this software produce different results than
L<http://www.heavens-above.com/>?

The short answer is "I don't know, because I don't know how Heavens
Above gets their answers."

In a little more detail, there appear to be several things going on:

First, there appears to be no standard reference for how to calculate
the magnitude of a flare. This module calculates specular reflections
as though the sky were opaque, and the flaring Main Mission Antenna
were a window through to the virtual image of the Sun. Limb darkening
is taken into account, as is atmospheric extinction. Non-specular
flares are calculated by a fairly arbitrary equation whose coefficients
were fitted to visual flare magnitude estimates collected by Ron Lee
and made available on the Web by Randy John as part of his skysat
web site at L<http://home.comcast.net/~skysat/>. Atmospheric extinction
is also taken into account for the non-specular flares.

Atmospheric extinction is calculated according to the article by Daniel
W.  Green in the July 1992 issue of "International Comet Quarterly", and
available at L<http://www.cfa.harvard.edu/icq/ICQExtinct.html>. Because
Heavens Above does not display flares dimmer than a certain magnitude
(-6 for day flares, and apparently 0 for night flares), it may not
display a flare that this code predicts. I have no information how
Heavens Above calculates magnitudes, but I find that this class gives
estimates about a magnitude brighter than Heavens Above at the dim end
of the scale.

Second, I suspect that the positions and velocities calculated by
Astro::Coord::ECI::TLE differ slightly from those used by Heavens Above.
I do not know this, because I do not know what positions Heavens Above
uses, but there are slight differences among the results of all the
orbital propagation models I have looked at. All I can say about the
accuracy of Astro::Coord::ECI::TLE is that it duplicates the test data
given in "Spacetrack Report Number Three". But small differences are
important -- 0.1 degree at the satellite can make the difference between
seeing and not seeing a flare, and smaller differences can affect the
magnitude predictions, especially if they make the difference between
predicting a specular or non-specular flare. Occasionally I find that I
get very different results than Heavens Above, even when using orbital
data published on that web site.

Third, Heavens Above issues predictions on satellites that my source
says are spares. I have skipped the spares by default because I do not
know that their attitudes are maintained to the requisite precision,
though perhaps they would be, to demonstrate that the spares are
functional. This software currently uses the Iridium status from
CelesTrak (L<http://celestrak.com/SpaceTrack/query/iridium.txt>), since
it represents one-stop shopping, and Dr. Kelso has expressed the intent
to check with Iridium Satellite LLC monthly for status. Mike McCants'
"Status of Iridium Payloads" at
L<http://users2.ev1.net/~mmccants/tles/iridium.html> notes that flares
may be unreliable for spares, so can_flare () returns false for them. If
this is not what you want, call can_flare with a true value (e.g.
can_flare(1)).

Fourth, the Heavens Above definition of 'daytime' differs from mine.
Heavens Above does not document what their definition is, at least
not that I have found. My definition of daytime includes twilight,
which by default means the center of the Sun is less than 6 degrees
below the horizon. I know that, using that definition, this software
classifies some flares as daytime flares which Heavens Above classifies
as nighttime flares. It appears to me that Heavens Above considers it
night whenever the Sun is below the horizon.

Fifth, the orbital elements used to make the prediction can differ.
I have occasionally seen Heavens Above using elements a day old,
versus the ones available from Space Track, and seen this difference
make a difference of six or eight seconds in the time of the flare.

Sixth, this method takes no account of the decrease in magnitude that
would result from the Sun being extremely close to the horizon as seen
from the flaring satellite. I do not know whether Heavens Above does
this or not, but I have seen an instance where this code predicted a
flare but Heavens Above did not, where the observed flare was much
dimmer than this code predicted, and reddened. Subsequent calculations
put the Sun 0.1 degrees above the horizon as seen from the satellite.

B<NOTE> that the algorithm used to calculate flares does not work at
latitudes beyond 85 degrees north or south, nor does it work for any
location that is not fixed to the Earth's surface. This may be fixed in
a future release. The chances of it being fixed in a future release will
be enhanced if someone claims to actually need it. This someone will be
invited to help test the new code.

B<NOTE also> that as of version 0.002_01 of this class, the 'backdate'
attribute determines whether a set of orbital elements can be used for
computations of flares before the epoch of the elements. If 'backdate'
is false and the start time passed to flare() is earlier than the epoch,
the start time is silently moved forward to the epoch. The initial
version of this functionality raised an exception if this adjustment
placed the start time after the end time, but as of version 0.003_01 of
this class, you simply get no flares if this happens.

=cut

use constant DTFMT => '%d-%b-%Y %H:%M:%S (GMT)';
use constant DAY_TOLERANCE => deg2rad (2);	# Distance Sun moves in 8 minutes.
use constant AM_START_LIMIT => 86400 - 480;	# 8 minutes before midnight.
use constant AM_END_LIMIT => 43200 + 480;	# 8 minutes after noon.
use constant PM_START_LIMIT => 43200 - 480;	# 8 minutes before noon.
use constant PM_END_LIMIT => 480;		# 8 minutes after midnight.

sub flare {
    my ( $self, @args ) = __default_station( @_ );
    my $method = $self->{&ATTRIBUTE_KEY}{_algorithm_method};
    return $self->$method (@args);
}

# Called as $self->$method()
sub _flare_fixed {	## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my $station = shift;
    {
	local $@;
	__instance( $station, 'Astro::Coord::ECI' ) or croak <<eod;
Error - The station must be a subclass of Astro::Coord::ECI.
eod
    }
    my $start = shift || time ();
    my $end = shift || $start + SECSPERDAY;
    $end >= $start or croak <<eod;
Error - End time must be after start time.
eod

    $start = $self->max_effective_date($start);
    $start > $end and return;

    my @flares;
    my $illum = $self->get ('illum');
    my $horizon = $self->get ('horizon');
    my $twilight = $self->get ('twilight');
    $sun ||= Astro::Coord::ECI::Sun->new ();

    my %want = (
	am => $self->get ('am'),
	day => $self->get ('day'),
	pm => $self->get ('pm'),
    );
    my $check_time = !($want{am} && $want{day} && $want{pm});
    my $day_limit = $twilight - DAY_TOLERANCE;
    my $night_limit = $twilight + DAY_TOLERANCE;
    my $illum_tolerance = deg2rad (15);


#	We assume our observing location is fixed on the surface of the
#	Earth, and take advantage of the fact that an Iridium orbit is
#	very nearly polar. We use these to calculate the intervals
#	between successive passes through the observer's latitude, since
#	the satellite is visible then if ever.

###	CAVEAT: The typical orbital inclination of an Iridium satellite
###	is about 85 degrees. So this algorithm only works between
###	latitudes 85 north and 85 south.

    my $satlat = ($self->universal ($start)->geodetic ())[0];
    my $zdot = ($self->eci)[5];
    my $stalat = ($station->geodetic ())[0];
    my $period = $self->period;
    my $angular_velocity = TWOPI / $period;
    my ($time, $asc) = ($zdot > 0 ?
	$satlat < $stalat ? (($stalat - $satlat) / $angular_velocity, 1) :
	    ((PI - $stalat - $satlat) / $angular_velocity, 0) :
	$satlat < $stalat ?
	    ((PI + $stalat + $satlat) / $angular_velocity, 1) :
	    (($satlat - $stalat) / $angular_velocity, 0));
    $time += $start;
    my @deltas = (
	(PIOVER2 + $stalat) * 2 / $angular_velocity,
	(PIOVER2 - $stalat) * 2 / $angular_velocity,
    );

#	At this point the time represents (approximately, because our
#	calculated period is a little scant) a moment when the
#	satellite crosses the observer's latitude.

#	Pick up a copy of our max mirror angle so we don't have to call
#	get () repeatedly.

    my $max_mirror_angle = $self->get ('max_mirror_angle');

#	While this time is less than our end time ...

    while ($time < $end) {

#	Calculate location of satellite.

	$self->universal ($time);
	my ($satlat, $satlon, $satalt) = $self->geodetic;


#	Correct time to put satellite at same latitude as station.

	$time += ($asc ? $stalat - $satlat : $satlat - $stalat)
	    / $angular_velocity;
	($satlat, $satlon, $satalt) = $self->universal ($time)->geodetic;


#	Calculate whether satellite is above horizon.

	my ( undef, $elev, $rng ) = $station->azel_offset( $self, 0 );
	$elev > $horizon or next;


#	Check whether we are interested in this potential flare, based
#	on whether it might be during the day, or am, or pm.

	$check_time and (eval {
	    my $sun_elev = ($station->azel ($sun->universal ($time)))[1];
	    ($want{day} && $sun_elev > $day_limit) and return 1;
	    (($want{am} || $want{pm}) && $sun_elev < $night_limit) or return 0;
	    my @local_time = $self->_time_in_zone( $time );
	    my $time_of_day = ($local_time[2] * 60 + $local_time[1]) * 60
		    + $local_time[0];
	    ($want{am} && ($time_of_day > AM_START_LIMIT ||
		    $time_of_day < AM_END_LIMIT)) and return 1;
	    ($want{pm} && ($time_of_day > PM_START_LIMIT ||
		    $time_of_day < PM_END_LIMIT)) and return 1;
	    0;
	    } || next);


#	Calculate whether the satellite is illuminated.

##	my $lit = ($self->azel ($illum->universal ($time)))[1] >=
	($self->azel ($illum->universal ($time)))[1] >=
	    $self->dip () - $illum_tolerance or next;


#	For our screening to work we need to know the maximum angular
#	distance we can travel in 30 seconds. This is the arc tangent
#	of the velocity over the range

	my (undef, undef, undef, $xdot, $ydot, $zdot) = $self->eci ();
	my $max_angle = atan2 (
	    sqrt ($xdot * $xdot + $ydot * $ydot + $zdot * $zdot), $rng)
	    * 30;
	$max_angle += $max_mirror_angle;	# Take into account near misses.


#	Iterate over a period of 16 minutes centered on our current
#	time, calculating the location of the reflection of the sun
#	versus the satellite, as seen by the observer.

	my @flare_potential = ([], [], []);	# Flare-potential data by MMA.
	foreach my $deltat (-8 .. 8) {
	    my $time = $deltat * 60 + $time;


#	See if the satellite is illuminated at this time.
#	TODO This code may need some slop; specifically we might want to
#	assume the Sun is higher than it actually is by $max_angle.

	    ($self->universal ($time)->azel ($illum->universal ($time)))[1] >=
		$self->dip () or next;


#	Transform the relevant coordinates into a coordinate system
#	in which the axis of the satellite is along the Z axis (with
#	the Earth in the negative Z direction) and the direction of
#	motion (and hence one of the Main Mission Antennae) is along
#	the X axis. The method returns Math::VectorReal objects
#	corresponding to all inputs, including '$self'.

	    my ( $illum_vector, $station_vector ) =
		$self->_flare_transform_coords_list (
		$illum, $station->universal( $time ) );


#	Now we do a second iteration over the Main Mission Antennae,
#	checking for the position of the Sun's reflection.

	    foreach my $mma (0 .. 2) {


#	We clone the sun and the station, and then calculate the angle
#	between the satellite and the reflection of the Sun, as seen by
#	the observer. We skip to the next antenna if no reflection is
#	generated.

		my $illum_vector = [@$illum_vector];
		my $station_vector = [@$station_vector];
		next unless defined (
		    my $angle = _flare_calculate_angle_list(
		    $mma, $illum_vector, $station_vector ) );


#	Save the angle, time, and cloned station for subsequent
#	analysis.

		push @{$flare_potential[$mma]},
		    [$angle, $time, $illum_vector, $station_vector];


#	End of iterating over Main Mission Antennae.

	    }


#	End of iterating over 16 minute period centered on current
#	time.

	}


#	Now iterate over each MMA to calculate its flare, if any.

MMA_LOOP:
	foreach my $mma (0 .. 2) {


#	Find the best possibility for a flare. If none, or the angle is
#	more than the max possible, ignore this antenna.

	    next if @{$flare_potential[$mma]} < 2;
	    my @flare_approx;
	    do {	# Begin local symbol block
		my $inx = 0;
		my $angle = $flare_potential[$mma][$inx][0];
		foreach (1 .. @{$flare_potential[$mma]} - 1) {
		    next unless $flare_potential[$mma][$_][0] < $angle;
		    $inx = $_;
		    $angle = $flare_potential[$mma][$_][0];
		}
		next if $angle > $max_angle;

#	If the best potential is at the beginning or end of the list,
#	calculate the entrance (or exit) of the flare so we have a
#	starting point for out approximations. Note that we used to
#	just abandon the calculation in these cases.

		if ($inx == 0) {
		    unshift @{$flare_potential[$mma]},
			$self->_flare_entrance ($illum, $station, $mma,
			    $flare_potential[$mma][$inx][1] - 60,
			    $flare_potential[$mma][$inx][1]);
		    $inx++;
		} elsif ($inx == @{$flare_potential[$mma]} - 1) {
		    push @{$flare_potential[$mma]},
			$self->_flare_entrance ($illum, $station, $mma,
			    $flare_potential[$mma][$inx][1] + 60,
			    $flare_potential[$mma][$inx][1]);
		}
		@flare_approx = ($flare_potential[$mma][$inx - 1],
		    $flare_potential[$mma][$inx + 1]);
	    };	# End local symbol block;


#	Use successive approximation to find the time of minimum
#	angle. We can not use a linear split-the-difference search,
#	because the behavior is too far from linear. So we fudge by
#	taking the second- and third-closest angles found, and working
#	inward from them. We also use a weighted average of the two
#	previously-used times to prevent converging so fast we jump
#	over the point we are trying to find.

	    while (abs ($flare_approx[1][1] - $flare_approx[0][1]) > .1) {


#	Calculate the next time to try as a weighted average of the
#	previous two approximations, with the worse approximation
#	having three times the weight of the better one. This prevents
#	us from converging so fast we miss the true minimum. Yes, this
#	is ad-hocery. I tried weighting the 'wrong' flare twice as
#	much, but still missed the maximum sometimes. This was more
#	obvious on daytime flares, where if you miss the peak the
#	flare is probably not specular.

##		my $time = ($flare_approx[1][1] * 2 + $flare_approx[0][1]) / 3;
		my $time = ($flare_approx[1][1] * 3 + $flare_approx[0][1]) / 4;
####		my $time = ($flare_approx[1][1] * 6 + $flare_approx[0][1]) / 7;


#	Transform the relevant coordinates into a coordinate system
#	in which the axis of the satellite is along the Z axis (with
#	the Earth in the negative Z direction) and the direction of
#	motion (and hence one of the Main Mission Antennae) is along
#	the X axis.

		my ( $illum_vector, $station_vector ) =
		    $self->universal( $time )->
			_flare_transform_coords_list(
			$illum->universal( $time ),
			$station->universal( $time ) );


#	Calculate the angle between the satellite and the reflection
#	of the Sun, as seen by the observer.

		my $angle = _flare_calculate_angle_list(
		    $mma, $illum_vector, $station_vector );
		defined $angle or next MMA_LOOP;


#	Store the data in our approximation list, in order by angle.

		pop @flare_approx;
		splice @flare_approx, $angle >= $flare_approx[0][0], 0,
		    [$angle, $time, $illum_vector, $station_vector];


#	End of successive approximation of time of minimum angle.

	    }


#	Pull the (potential) flare data off the approximation list.

	    my ($angle, $time, $illum_vector, $station_vector) =
		    @{$flare_approx[0]};


#	Skip it if the mirror angle is greater than the max.

	    next if $angle > $max_mirror_angle;


#	All our approximations may have left us with a satellite which
#	is not quite lit. This happened with Iridium 32 (OID 24945) on
#	Feb 03 2007 at 07:45:19 PM. So we check for illumination one
#	last time.
#	TODO: this calculation should be performed not on the position
#	of the Sun, but on the actual point on the Sun which is
#	reflected to the observer. It looks now like it needs to be done
#	in _flare_calculate_angle_list().

	    ($self->universal ($time)->azel ($illum->universal ($time)))[1] >=
		$self->dip () or next;


#	Calculate all the flare data.

	    my $flare = $self->_flare_char_list ($station, $mma, $angle,
		$time, $illum_vector, $station_vector);

#	Stash the data.

	    push @flares, $flare
		if !$flare->{status} && $want{$flare->{type}};


#	End of iteration over each MMA to calculate its flare.

	}


#	Compute the next approxiate crossing of the observer's
#	latitude.

    } continue {
	$time += $deltas[$asc];
	$asc = 1 - $asc;
    }

    return @flares;

}


#	[$angle, $time, $illum_vector, $station_vector] =
#	    $self->_flare_entrance ($illum, $station, $mma, $start,
#	    $end);

#	Given that a flare is in progress at the end time and not at
#	the start time, computes the start of the flare. Can be used
#	for exit by reversing the times.

sub _flare_entrance {
    my ($self, $illum, $station, $mma, $start, $end) = @_;
    my $output;
#   my $time = find_first_true (
    find_first_true (
	$start, $end,
	sub {
	    $self->universal ($_[0]);
	    my ( $illum_vector, $station_vector ) =
		$self->_flare_transform_coords_list(
		$illum->universal( $_[0] ),
		$station->universal( $_[0] ) );
	    if ( defined ( my $angle = _flare_calculate_angle_list(
		$mma, $illum_vector, $station_vector ) ) ) {
		$output = [$angle, $_[0], $illum_vector, $station_vector];
		1;
	    } else {
		0;
	    }
	});
    $output ||= do {	# Can happen if end is entrance.
	    $self->universal ($end);
	    my ( $illum_vector, $station_vector ) =
		$self->_flare_transform_coords_list(
		$illum->universal( $end ),
		$station->universal( $end) );
	    my $angle = _flare_calculate_angle_list(
		$mma, $illum_vector, $station_vector );
	    defined $angle ?
		[$angle, $end, $illum_vector, $station_vector] :
		undef;
	    } || confess <<eod;
Programming error - No entrance found by _flare_entrance.
    @{[join ' - ', grep {$_} map {$self->get ($_)} qw{name id}]}
    \$mma = $mma
    \$start = $start = @{[scalar localtime $start]}
    \$end = $end = @{[scalar localtime $end]}
eod
    return $output;
}

#	@vectors = $tle->_flare_transform_coords_list( $eci ....)
#
#	This private method transforms the coordinates of the $tle
#	object and all $eci objects passed in, so that the $tle
#	object is at the origin of a coordinate system whose
#	X axis is along the velocity vector of the $tle object, the
#	Y axis is perpendicular to the plane of the orbit, and the
#	Z axis is perpendicular to both of these, and therefore
#	nominally "up and down", with the center of the Earth in the
#	- Z direction. The objects are not modified, instead
#	list references (containing the position vectors)
#	corresponding to all arguments (except the invocant) are
#	returned.

sub _flare_transform_coords_list {
    my ( $self, @args ) = @_;
    my @ref = $self->eci();
    my $X = vector_unitize( [@ref[3 .. 5]] );
    my $Y = vector_cross_product( vector_unitize( [ @ref[0 .. 2]] ), $X );
    my $Z = vector_cross_product( $X, $Y );
    my @coord = ($X, $Y, $Z);
    my @rslt;
    foreach my $loc (@args) {
	my @eci = $loc->eci();
	my @pos = map { $eci[$_] - $ref[$_] } 0 .. 2;
	push @rslt, [
	    map { vector_dot_product( \@pos, $coord[$_] ) } 0 .. 2
	];
    }
    return @rslt;
}

#	@original = $tle->_flare_transform_coords_inverse_list( @vectors )
#
#	This private method is the inverse (almost) of
#	_flare_transform_coords_list(). The weasel word is because it
#	returns array references representing the ECI position vectors,
#	rather than Astro::Coord::ECI objects.

sub _flare_transform_coords_inverse_list {
    my ( $self, @args ) = @_;
    my @ref = $self->eci();
    my $X = vector_unitize( [@ref[3 .. 5]] );
    my $Y = vector_cross_product( vector_unitize( [ @ref[0 .. 2]] ), $X );
    my $Z = vector_cross_product( $X, $Y );
    my @coord = _invert_matrix_list($X, $Y, $Z);
    my @rslt;
    foreach my $loc (@args) {
	push @rslt, [
	    map { vector_dot_product( $loc, $coord[$_] ) + $ref[$_] } 0 .. 2
	];
    }
    return @rslt;
}


#	$angle = _flare_calculate_angle_list($mma, $illum, $station)

#	This private subroutine calculates the angle between the
#	satellite and the reflection of the Sun in the given Main
#	Mission Antenna as seen from the observing station. $illum and
#	$station are list reverences generated by
#	_flare_transform_coords_list(). The satellite position is not
#	needed because in this coordinate system it is [0, 0, 0]

#	A reflection can only occur if both the Sun and the observer
#	are in front of the antenna (i.e. have positive Z coordinates
#	after transforming everything so that the plane of the MMA is
#	the X-Y axis). If there is no reflection, undef is returned.

sub _flare_calculate_angle_list {
    my ( $mma, $illum, $station ) = @_;

#	Rotate the objects so that the Main Mission Antenna of interest
#	lies in the X-Y plane, facing in the +Z direction.

    my @eci;
    foreach my $inx (0 .. 2) {
	$eci[$inx] = vector_dot_product ($illum, $transform_vector[$mma][$inx])
    }
    return unless $eci[2] > 0;
    $eci[2] = - $eci[2];
    $illum = [$eci[0], $eci[1], $eci[2]];
    foreach my $inx (0 .. 2) {
	$eci[$inx] = vector_dot_product ($station, $transform_vector[$mma][$inx])
    }
    return unless $eci[2] > 0;
    $station = [$eci[0], $eci[1], $eci[2]];

#	Now calculate the angle between the illumination source and the
#	observer as seen by the observer.

    return _list_angle( $station, $illum, [ 0, 0, 0 ] );
}


#	$hash_ref = $iridium->_flare_char_list (...)
#
#	Calculate the characteristics of the flare of the given body.
#	The arguments are as follows:
#
#	$station => the object representing the observer.
#	$mma => the flaring Main Mission Antenna (0 .. 2).
#	$angle => the previously-calculated mirror angle.
#	$time => the time of the flare.
#	$illum_vector => the previously-calculated vector to the
#		illuminating body (satellite = [0, 0, 0]).
#	$station_vector => the previously-calculated vector to the
#		observer (satellite = [0, 0, 0])

sub _flare_char_list {

my ($self, $station, $mma, $angle, $time, $illum_vector, $station_vector) = @_;

#	Skip it if the flare is not above the horizon.

my ($azim, $elev) = $station->azel ($self->universal ($time));
my $horizon = $self->get ('horizon');
if ($elev < $horizon) {
    return _make_status (sprintf (
	'Satellite %.2f degrees below horizon', rad2deg ($horizon - $elev)));
    }


#	Retrieve the illuminating body information.

my $illum = $self->get ('illum');
my $illum_radius = $illum->get ('diameter') / 2;


#	Retrieve missing station information.

my $height = ($station->geodetic)[2];

#	And any odds and ends we might need.

$sun ||= Astro::Coord::ECI::Sun->new ();
my $twilight = $self->get ('twilight');
my $atm_extinct = $self->get ('extinction');


#	Calculate the range to the satellite, and to the reflection of
#	the Sun, from the observer.

my $sat_range = vector_magnitude ($station_vector);
my $illum_range = vector_magnitude ([
	$illum_vector->[0] - $station_vector->[0],
	$illum_vector->[1] - $station_vector->[1],
	$illum_vector->[2] - $station_vector->[2],
	]);

#	Calculate the projected area of the MMA of interest, in square
#	radians.

my $sat_area = abs ($station_vector->[2]) / $sat_range * MMAAREA
	/ 1e6 / ($sat_range * $sat_range);

#	As a side effect, we calculate omega, the angle from the center
#	of the Sun to the edge, as seen by the observer.

my $illum_omega = $illum_radius / $illum_range;
my $illum_area = PI * $illum_omega * $illum_omega;

#	Calculate the magnitude of the illuminating body at the point
#	reflected by the Main Mission Antenna.

my ($point_magnitude, $limb_darkening, $central_magnitude) =
	$illum->magnitude ($angle, $illum_omega);

#	Calculate the reduction in magnitude due to the fact that the
#	projected area of the main mission antenna is smaller than the
#	projected area of the Sun.

my $area_correction =
	intensity_to_magnitude ($sat_area / $illum_area);

#	Calculate the dead-center flare magnitude as the central
#	magnitude of the Sun plus the delta caused by the fact that the
#	projected area of the main mission antenna is smaller than the
#	area of the sun.

my $central_mag = $central_magnitude + $area_correction;

#	And for the test case, I got -8.0. Amazing.


#	Calculate the atmospheric extinction of the flare.

my $extinction = $atm_extinct ?
	atmospheric_extinction ($elev, $height) : 0;


#	The following off-axis magnitude calculation is the result of
#	normalizing Ron Lee's magnitude data (made available by Randy
#	John in various forms at http://home.comcast.net/~skysat/ ) for
#	a projected Main Mission Antenna area of 1e-12 square radians
#	and zero atmospheric extinction. A logarithmic correlation was
#	suggested by Rob Matson (author of IRIDFLAR) at
#	http://www.satobs.org/seesat/Apr-1998/0175.html . I tried a
#	couple other possibilities, but ended up most satisfied (or
#	least unsatisfied) with a linear regression on
#	ln (8 - magnitude), with the 8 picked because it was the
#	maximum possible magnitude.
#	Maybe I could have done better with a larger arbitrary
#	constant, since the data sags a bit in the middle versus the
#	regression line, but there is a fair amount of scatter anyway.

#	All this means that the calculation is
#	mag = 8 - exp (-5.1306 * angle_in_radians + 2.4128) +
#		intensity_to_magnitude (area / 1e-12) +
#		atmospheric_refraction (elevation, height)
#	The R-squared for this is .563.

#	There are several possible sources of error:

#	* My mirror angle is defined slightly different than Randy
#	  John's. Mine is the angle between the satellite and the
#	  virtual image of the Sun as seen by the observer. His is the
#	  angle between the actual reflection and a central specular
#	  reflection, which I take to be 180 degrees minus the angle
#	  between the Sun and the observer as seen from the satellite.
#	  This makes my angle slightly smaller than his, the difference
#	  being the angle between the observer and the satellite as
#	  seen from the Sun, something on the order of 0.01 degrees or
#	  less. This is probably not directly a source of error (since
#	  I used my own calculation of mirror angle), but needs to be
#	  taken into account when evaluating the other sources of
#	  error.

#	* My calculated mirror angles are different than Randy John's
#	  by an amount which is typically about a tenth of a degree,
#	  but which can be on the order of a couple degrees. Since I
#	  do not currently have any Wintel hardware, I can not tell
#	  how much of this is difference in calculation and how much
#	  is difference in orbital elements.

#	* The error between the visually estimated magnitudes and the
#	  actual magnitudes is unknown. In theory, visual estimates are
#	  fairly good given a number of nearby comparison stars of
#	  magnitudes near the body to be estimated. How the ephemeral
#	  nature of the flares affects the accuracy of this process is
#	  not known to me. What happens with magnitudes brighter than
#	  about -1, where there are no comparison objects available is
#	  also unknown, as is the actual methodology of making the
#	  estimates.

#	Note to me: the current estimate was done with
#	perl process.pl -quiet -specular -radians -constant 8
#	The previous was done with
#	perl process.pl -specular -radians, but the correlation was
#	done in a spreadsheet (normalized2.ods)

use constant OFF_AXIS_FACTOR => -5.1306;	# Was -3.9246
use constant OFF_AXIS_CONST => 2.4128;		# Was 2.60
use constant OFF_AXIS_STD_AREA => 1e-12;
use constant OFF_BASE_MAG => 8;			# Was 10

my $off_axis_mag = OFF_BASE_MAG -
	exp ($angle * OFF_AXIS_FACTOR + OFF_AXIS_CONST) +
	intensity_to_magnitude ($sat_area / OFF_AXIS_STD_AREA) +
	$extinction;
my $flare_mag = $limb_darkening > 0 ? do {
    my $specular_mag = $point_magnitude + $area_correction +
	$extinction;
    min ($specular_mag, $off_axis_mag) } : $off_axis_mag;


#	Compute the flare type (am, day, or pm)

my $sun_elev = ($station->azel ($sun->universal ($time)))[1];
my $flare_type = $sun_elev >= $twilight ? 'day' :
	( $self->_time_in_zone( $time ) )[2] > 12 ? 'pm' : 'am';


#	Compute the angle from the Sun to the flare.

my $sun_angle = $station->angle ($sun, $self);

#	Wikipedia gives the following analytical expression for the
#	inversion of a 3 x 3 matrix at
#	http://en.wikipedia.org/wiki/Matrix_inversion
#	Given
#
#	    +-	   -+
#	    | a b c |
#	A = | d e f |
#	    | g h i |
#	    +      -+
#
#	the inverse is
#
#	        +-                 -+
#	     1  | ei-fh ch-bi bf-ce |
#	A'= --- | fg-di ai-cg cd-af |
#	    |A| | dh-eg bg-ah ae-bd |
#	        +-                 -+
#
#	where the determinant |A| = a(ei - fh) - b(di - fg) + c(dh - eg)
#	and the matrix is singuar if |A| == 0
#
#	I can then undo the rotations by premultiplying the inverse
#	matrices in the reverse order, and add back the location of
#	the Iridium satellite to get the location of the virtual image
#	in ECI coordinates.

#	Compute the location of the virtual image of the illuminator,
#	in ECI coordinates:

my ($virtual_image, $image_vector) = do {

    # Recover the position of the virtual image of the illuminator. We
    # calculated this before, but never saved it.

    my $image_vector = [
	map { vector_dot_product( $illum_vector,
	    $transform_vector[$mma][$_] ) } 0 .. 2
    ];
    $image_vector->[2] = - $image_vector->[2];


    # Undo the rotations that placed the MMA of interest in the X-Y
    # plane.

    $image_vector = [
	map { vector_dot_product( $image_vector,
	    $inverse_transform_vector[$mma][$_] ) } 0 .. 2
    ];


    # Transform from satellite-local coordinates to ECI coordinates.

    ( $image_vector ) = $self->_flare_transform_coords_inverse_list(
	$image_vector );

    # Manufacture an object representing the virtual image, and a vector
    # represnting same for use in calculating the flare sub-point.

    ( Astro::Coord::ECI->universal( $time )->eci( @{ $image_vector } ),
	$image_vector );
    };


#	Compute the distance to the flare center.

#	For the calculation, consider the Earth flat, and consider the
#	center of the flare at the given time to be the point where the
#	line from the virtual image of the Sun through the satellite
#	intersects the plane.

#	Per http://mathforum.org/library/drmath/view/55094.html
#	you can consider the plane defined as a point A (the observer)
#	and a normal vector N (toward the zenith), and the line
#	to be defined by point P (Iridium) and vector V (= Q - P, with
#	Q being the virtual image of the Sun). Then the intersection X
#	is given by
#
#	        (A - P) dot N
#	X = P + ------------- (Q - P)
#	        (Q - P) dot N
#
#	I have A (observer), P (Iridium), and Q (virtual image of Sun),
#	so all I need is N. This I can get by rotating a unit vector by
#	the longitude, then by the geodetic latitude. The distance is
#	| X - A |, and the direction is the azimuth of X from A, which
#	the azel() method will give me.
#

my $sub_vector = do {
    my $a = [($station->eci ())[0 .. 2]];
    my $p = [($self->eci ())[0 .. 2]];
    my $q = $image_vector;
    my @n = $station->geodetic ();
    $n[2] += 1;
    my $n = [(Astro::Coord::ECI->geodetic (@n)
	->universal ($time)->eci ())[0 .. 2]];
    $n = [$n->[0] - $a->[0], $n->[1] - $a->[1], $n->[2] - $a->[2]];
    my $q_p = [$q->[0] - $p->[0], $q->[1] - $p->[1], $q->[2] - $p->[2]];
    my $k = vector_dot_product ([$a->[0] - $p->[0], $a->[1] - $p->[1], $a->[2] - $p->[2]], $n) /
	vector_dot_product ($q_p, $n);
    [$q_p->[0] * $k + $p->[0], $q_p->[1] * $k + $p->[1], $q_p->[2] * $k + $p->[2]];
    };
my $sub_point = Astro::Coord::ECI->new(
    station => $station )->universal( $time )->eci( @$sub_vector );


#	Stash the data.

my %rslt = (
	angle => $angle,		# Mirror angle, radians
	appulse => {			# Relationship of flare to Sun
	    angle => $sun_angle,	# Angle from flare to Sun
	    body => $sun,		# Reference to Sun
	},
	area => $sat_area,		# Projected MMA area, square radians
	azimuth => $azim,		# Azimuth of flare
	body => $self,			# Reference to flaring body
	center => {			# Information on flare center
	    body => $sub_point,		# Location of center
	    magnitude => $central_mag,	# Predicted magnitude  at center
	},
	elevation => $elev,		# Elevation of flare
	magnitude => $flare_mag,	# Estimated magnitude
	mma => $mma,			# Flaring mma (0, 1, or 2)
	range => $sat_range,		# Range to satellite, kilometers
	specular => $limb_darkening,	# True if specular
	station => $station,		# Observer's location
	status => '',			# True if below horizon or not illum
	time => $time,			# Time of flare
	type => $flare_type,		# Flare type ('am', 'day', 'pm')
	virtual_image => $virtual_image, # Virtual image of illum.
	);

return wantarray ? %rslt : \%rslt;
}


#	$ainv = _invert_matrix_list ($a)

#	This subroutine takes a reference to a list of three list
#	references, considers them as a matrix, and inverts that
#	matrix, returning a reference to the list of list references
#	that represents the inverted matrix. If called in list context,
#	it returns the list itself. You can also pass the three input
#	list references as a list.

sub _invert_matrix_list {
    my @args = @_;
    confess <<eod unless (grep {ref $_ eq 'ARRAY'} @args) == 3;
Programming error -- _invert_matrix_list takes as its arguments three
       list references.
eod
    my ($a, $b, $c) = @{$args[0]};
    my ($d, $e, $f) = @{$args[1]};
    my ($g, $h, $i) = @{$args[2]};
    my $ei_fh = $e * $i - $f * $h;
    my $fg_di = $f * $g - $d * $i;
    my $dh_eg = $d * $h - $e * $g;
    my $A = $a * $ei_fh + $b * $fg_di + $c * $dh_eg;
    confess <<eod if $A == 0;
Programming error -- You are trying to invert a singular matrix. This
        should not happen since our purpose is to undo a rotation.
eod
    my @inv = (
	[$ei_fh / $A, ($c * $h - $b * $i) / $A, ($b * $f - $c * $e) / $A],
	[$fg_di / $A, ($a * $i - $c * $g) / $A, ($c * $d - $a * $f) / $A],
	[$dh_eg / $A, ($b * $g - $a * $h) / $A, ($a * $e - $b * $d) / $A],
    );
    return wantarray ? @inv : \@inv;
}

#	$a = _list_angle ($A, $B, $C)
#
#	This subroutine takes as input three list references, which are
#	assumed to define the coordinates of the vertices of a
#	triangle. The angle of the first vertex is computed (in
#	radians) by the law of cosines, and returned.

sub _list_angle {
    my $A = shift;
    my $B = shift;
    my $C = shift;

    my $a = distsq ($B, $C);
    my $b = distsq ($A, $C);
    my $c = distsq ($A, $B);

    return acos (($b + $c - $a) / sqrt (4 * $b * $c));
}

=item $value = $tle->get ($name);

This method returns the value of the given attribute. Attributes other
than 'status' are delegated to the parent.

=cut

sub get {
    my $self = shift;
    my $name = shift;

    if (!$accessor{$name}) {
	return $self->SUPER::get ($name);
    } elsif (ref $self) {
	return $accessor{$name}->($self, $name);
    } else {
	return $accessor{$name}->(\%statatr, $name);
    }
}

#	$status = _make_status ($message);

#	This subroutine returns a reference to a hash with key 'status'
#	containing the given message. In list context it returns the
#	hash itself.

sub _make_status {
    my %stat = (status => @_);
    return wantarray ? %stat : \%stat;
}

=item $mag = $tle->magnitude( $station );

This override of the superclass' method method returns the magnitude of
the body as seen from the given station at the body's currently-set
time. If no C<$station> is specified, the object's C<'station'>
attribute is used.  If that is not set, and exception is thrown.

This method calls the superclass' C<magnitude()>, and returns C<undef>
if the superclass does. Otherwise it adds to the magnitude of the body
itself the magnitude of any flare in progress, and returns the result.

=cut

sub magnitude {
    my ( $self, $sta ) = __default_station( @_ );
    defined( my $mag = $self->SUPER::magnitude( $sta ) )
	or return undef;	## no critic (ProhibitExplicitReturnUndef)
    my $time = $self->universal();
    my @flare = grep { defined }
	map { $_->{magnitude} }
	$self->reflection( $sta, $time );
    @flare
	and $mag = add_magnitudes( $mag, @flare );
    return $mag;
}


=item @data = $tle->reflection ($station, $time)

This method returns a list of references to hashes containing the same
data as returned for a flare, calculated for the given observer and time
for all Main Mission Antennae. If C<$time> is C<undef>, the current time
setting of the invocant is used. If C<$station> is C<undef> the current
C<station> attribute is used. Note the following differences from the
flare() hash:

If the hash contains a 'status' key which is true (in the Perl sense),
no reflection occurred, and the content of the key is a message saying
why not. If the 'mma' key exists in addition to the 'status' key, the
failure applies only to that MMA, and other MMAs may possibly generate a
reflection. If the 'mma' key does not exist, then the satellite is
either not illuminated or below the horizon for the given observer, and
the @data list will contain only a single entry.

Other than (maybe) 'mma', no other keys should be assumed to exist if
the 'status' key is true.

If called in scalar context, a reference to the \@data list is returned.

B<NOTE> that prior to 0.061_01 the C<$time> argument defaulted to the
current time. This behavior was undocumented, and therefore I felt free
to change it.

=cut

sub reflection {
    my ( $self, $station, $time ) = __default_station( @_ );
    my $method = "_reflection_$self->{&ATTRIBUTE_KEY}{algorithm}";
    return $self->$method( $station, $time );
}


# Called as $self->$method, above
sub _reflection_fixed {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $station, $time ) = @_;
    defined $time
	or $time = $self->universal();
    my $debug = $self->get ('debug');
    my $illum = $self->get ('illum')->universal ($time);


#	Calculate whether satellite is above horizon.

    my (undef, $elev) = $station->universal ($time)->
	    azel_offset( $self->universal ($time), 0 );
    return scalar _make_status (
	sprintf ('Satellite %.2f degrees below horizon', rad2deg (-$elev)))
	unless $elev >= 0;


#	Calculate whether the satellite is illuminated.

    my $lit = ($self->azel ($illum->universal ($time)))[1] - $self->dip ();
    return scalar _make_status (
	sprintf ('Satellite fails to be illuminated by %.2f degrees',
	    rad2deg (-$lit)))
	unless $lit >= 0;


#	Transform the relevant coordinates into a coordinate system
#	in which the axis of the satellite is along the Z axis (with
#	the Earth in the negative Z direction) and the direction of
#	motion (and hence one of the Main Mission Antennae) is along
#	the X axis.

    my ( $illum_vector, $station_vector ) =
	$self->_flare_transform_coords_list( $illum, $station );

    my @rslt;

    foreach my $mma (0 .. 2) {

#	We calculate
#	the angle between the satellite and the reflection of the Sun,
#	as seen by the observer. We skip to the next antenna if no
#	reflection is generated.

	my $angle = _flare_calculate_angle_list(
		$mma, $illum_vector, $station_vector );
	warn <<eod if $debug;	## no critic (RequireCarping)
        MMA $mma Angle: @{[defined $angle ? rad2deg ($angle) . ' degrees' :
		'undefined']}
eod
	push @rslt, defined $angle ?
	    scalar $self->_flare_char_list ($station, $mma, $angle, $time,
		$illum_vector, $station_vector) :
	    scalar _make_status ('Geometry does not allow reflection',
		mma => $mma);
    }

    return wantarray ? @rslt : \@rslt;
}


=item $tle->set ($name => $value ...)

This method sets the value of the given attribute (or attributes).
Attributes other than 'status' are delegated to the parent.

=cut

sub set {
    my ($self, @args) = @_;
    while (@args) {
	my $name = shift @args;
	my $value  = shift @args;
	if (!$mutator{$name}) {
	    $self->SUPER::set ($name, $value);
	} elsif (ref $self) {
	    $mutator{$name}->($self, $name, $value);
	} else {
	    $mutator{$name}->(\%statatr, $name, $value);
	}
    }
    return $self;
}

# For use of -am and -pm
{
    my $date_time_available = eval {
	load_module( 'DateTime' );
	load_module( 'DateTime::TimeZone' );
	1;
    };

    sub _time_in_zone {
	my ( $self, $time ) = @_;

	defined( my $zone = $self->get( 'zone' ) )
	    or return localtime $time;

	looks_like_number( $zone )
	    and return gmtime( $zone * 3600 + $time );

	if ( $date_time_available ) {

	    my $dt = DateTime->from_epoch(
		epoch		=> $time,
		time_zone	=> $zone,
	    );

	    my @localtime = map { $dt->$_() } qw{ second minute hour day
	    month_0 year day_of_week_0 day_of_year_0 is_dst };
	    $localtime[5] -= 1900;
	    return @localtime;

	} else {

	    local $ENV{TZ} = $zone;
	    return localtime $time;

	}
    }
}

sub __parse_name {
    my ( $self, $name ) = @_;
    defined $name
	and $name =~ s/ \s* [[] ( \S ) []] \s* \z //smx
	and $self->_set_operational_status( status => $1 );
    return $self->SUPER::__parse_name( $name );
}

{
    my @encode_status;
    $encode_status[BODY_STATUS_IS_OPERATIONAL]	= '+';
    $encode_status[BODY_STATUS_IS_SPARE]	= 'S';
    $encode_status[BODY_STATUS_IS_TUMBLING]	= '-';
    $encode_status[BODY_STATUS_IS_DECAYED]	= 'D';

    sub __encode_operational_status {
##	my ( $self, $name, $status ) = @_;
	my ( $self, undef, $status ) = @_;	# Name unused
	defined $status
	    or $status = $self->get( 'status' );
	defined $encode_status[ $status ]
	    or return BODY_STATUS_IS_TUMBLING;
	return $encode_status[ $status ];
    }
}


{

    my %status_map = (
	BODY_STATUS_IS_OPERATIONAL()	=> BODY_STATUS_IS_OPERATIONAL,
	''			=> BODY_STATUS_IS_OPERATIONAL,
	'+'			=> BODY_STATUS_IS_OPERATIONAL,
	BODY_STATUS_IS_SPARE()		=> BODY_STATUS_IS_SPARE,
	'?'			=> BODY_STATUS_IS_SPARE,
	'S'			=> BODY_STATUS_IS_SPARE,
	's'			=> BODY_STATUS_IS_SPARE,
	'D'			=> BODY_STATUS_IS_DECAYED,
	'd'			=> BODY_STATUS_IS_DECAYED,
	BODY_STATUS_IS_TUMBLING()	=> BODY_STATUS_IS_TUMBLING,
	BODY_STATUS_IS_DECAYED()	=> BODY_STATUS_IS_DECAYED,
    );

    sub __decode_operational_status {
	my ( $value ) = @_;
	defined $value
	    or return BODY_STATUS_IS_OPERATIONAL;;
	defined $status_map{$value}
	    or return BODY_STATUS_IS_TUMBLING;
	return $status_map{$value};
    }
}

sub _set_operational_status {
    my ( $self, $name, $value ) = @_;
    $self->{&ATTRIBUTE_KEY}{$name} = __decode_operational_status( $value );
    return $self;
}

{
    my %json_map = (
	operational_status	=> \&__encode_operational_status,
    );

    sub TO_JSON {
	my ( $self ) = @_;
	return $self->__to_json(
	    \%json_map,
	    $self->SUPER::TO_JSON(),
	);
    }
}

1;

__END__

=back

=head2 Attributes

This class adds the following attributes:

=over

=item am (boolean)

If true, the flare() method returns flares that occur between midnight
and morning twilight. If false, such flares are ignored.

The default is 1 (i.e. true).

=item day (boolean)

If true, the flare() method returns flares that occur between morning
twilight and evening twilight. If false, such flares are ignored.

The default is 1 (i.e. true).

=item extinction (boolean)

If true, flare magnitude calculations will take atmospheric extinction
into account. If false, they will not. The observer who wishes to
compare forecast magnitudes to nearby stars may wish to set this to some
value Perl considers false (e.g. undef).

The default is 1 (i.e. true).

=item intrinsic_magnitude (numeric or undef)

This attribute is inherited from the parent class, but unlike the parent
(which defaults it to C<undef>), this class defaults it to C<7.0>, which
is the average intrinsic magnitude for an Iridium satellite.

=item max_mirror_angle (angle in radians)

This attribute is used in the flare calculation to screen passes for
flare potential. The position of the satellite is calculated at
intervals during a pass, and for each position the mirror angle (defined
as the angle subtended at the satellite between the observer and the
reflection of the Sun) is calculated. If no calculated mirror angle is
less than the value of this attribute, no flare is predicted. If one of
the mirror angles B<is> less than this, a flare is predicted and its
maximum magnitude calculated.

The default value is equivalent to 10 degrees. This is fine for fairly
bright flares, but if you are looking for really dim ones (relative to
the maximum brightness given the source of illumination) you want to
increase this. The cost of increasing it is, of course, increased
computation. The maximum useful value is the equivalent of 180 degrees,
but this is not enforced. If you have a particular angle in mind, you
will want to set this to about 10 degrees more, because of the way it is
used in the flare algorithm.

=item pm (boolean)

If true, the flare() method returns flares that occur between evening
twilight and midnight. If false, such flares are ignored.

The default is 1 (i.e. true).

=item status (integer)

This attribute determines whether the Iridium satellite is considered
able to produce predictable flares. The possible values are:

 0 => in service;
 1 => spare, or maneuvering;
 2 => out of service, tumbling, et cetera;
 3 => decayed.

By default, the can_flare() method returns true only if the status is 0.
But if given a true argument (e.g. can_flare(1)) it will also return true
if the status is 1.

When setting this attribute, both T. S. Kelso and Mike McCants style
strings are accepted. That is:

 '+' or '' will be considered 0;
 'S' or '?' will be considered 1;
 anything else will be considered 2.

Technically, the default is 0. But if the object is manufactured by
Astro::Coord::ECI::TLE->parse(), the status will be set based on the
internal status table in Astro::Coord::ECI::TLE.

B<Note> that Mike McCants' Iridium statuses are no longer maintained, so
his status codes (C<''> and C<'?'>) are being put through a deprecation
cycle. In 6 months they will warn on the first use; 6 months after that
they will warn on every use, and 6 months after that they will become
fatal.

=item zone (number or string)

This attribute is used to determine whether a flare took place in the
C<am> or C<pm>. It can be set to a number of possible values:

* C<undef> causes the computation to be done in the local zone, whatever
that is.

* A numeric value is interpreted as an offset in hours east of
Greenwich; hours west are negative.

* Anything else is interpreted as a zone name. If L<DateTime|DateTime>
is available, it is used to convert the time to the named zone, throwing
an exception if the zone name is not recognized.

Otherwise, $ENV{TZ} is set to the zone, and then C<localtime()> is
called. Whether this has the desired effect depends on your operating
system.

Yes, this is a bit of a crock, but I realized (B<after> putting out
0.036, with the Iridium flare tests that anyone can run) that I needed
to do B<something> to get a user's-zone-independent test.

The default is C<undef>.

=back

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge the following people, without
whose work this module would never have existed:

Ron Lee and the members of his team who collected Iridium magnitude
data.

Randy John, the author of SKYSAT (L<http://home.comcast.net/~skysat/>),
whose Turbo Pascal implementation of the geometry calculation (at
L<http://home.comcast.net/~skysat/algo.txt> provided the basic mechanism
for my own geometry calculation, and who made Ron Lee's data available
on the SKYSAT web site.

The contributors to the Visual Satellite Observer's Home Page
(L<http://www.satobs.org/satintro.html>), particularly the
Iridium Flares page (L<http://www.satobs.org/iridium.html>),
which provided the background for the entire Iridium flare
effort.

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org/>.

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
