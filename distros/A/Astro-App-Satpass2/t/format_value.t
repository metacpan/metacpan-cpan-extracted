package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;

use lib qw{ inc };
use My::Module::Test::App qw{ load_or_skip };

use Astro::Coord::ECI 0.059;
use Astro::Coord::ECI::Moon 0.059;
use Astro::Coord::ECI::TLE 0.059;
use Astro::Coord::ECI::Utils 0.059 qw{ deg2rad PI };

use Astro::App::Satpass2::FormatTime;
use Astro::App::Satpass2::FormatValue;


# Note that the following are _not_ real Keplerian elements for the
# International Space Station, or in fact any other orbiting body. The
# only data known to be real are the id, the name, and the internatinal
# launch designator. Instead of doing an actual position calculation, we
# simply set the model to 'null', and then set the ECI position we want.

my $time = 1223594621;	# 09-Oct-2008 23:23:41
my $epoch = 1223549582;	# 09-Oct-2008 10:53:02

my $body = Astro::Coord::ECI::TLE->new(
    model => 'null',
    id => 25544,
    name => 'ISS',
    classification => 'U',
    effective => $epoch - 1800,
    epoch => $epoch,
    meanmotion => &deg2rad(3.930270155),
    eccentricity => 0.0004029,
    inclination => &deg2rad(51.6426),
    international => '98067A',
    firstderivative => &deg2rad(1.23456789e-8),
    secondderivative => &deg2rad(1.23456789e-20),
    bstardrag => 8.2345e-5,
    ephemeristype => 0,
    ascendingnode => &deg2rad(159.8765),
    argumentofperigee => &deg2rad(198.7654),
    meananomaly => &deg2rad(279.8765),
    elementnumber => 456,
    revolutionsatepoch => 56789,
    intrinsic_magnitude	=> -0.5,
)->geodetic(&deg2rad(34.0765), &deg2rad(-74.2084), 353.9
)->universal($time);

my $moon = Astro::Coord::ECI::Moon->new();

my $station = Astro::Coord::ECI->new(
    name => '1600 Pennsylvania Ave NW, Washington DC 20502'
)->geodetic(
    deg2rad( 38.898748 ),
    deg2rad( -77.037684 ),
    16.68 / 1000,
);

sub clone (@);
sub create (@);
sub method (@);
sub method_good (@);

my %default;
my $time_formatter = Astro::App::Satpass2::FormatTime->new()->gmt( 1 );

create data => {
	almanac	=> {
	    event	=> 'horizon',
	    detail	=> 1,
	    description	=> 'Sun rise',
	},
    },
    default => \%default,
    'Create formatter for almanac description data';
method almanac => [],
    'Sun rise                                ',
    'Almanac event description';
method almanac => [ field => 'description', width => '' ],
    'Sun rise',
    'Almanac event description (explicit, no width)';
method almanac => [ field => 'description', width => '10' ],
    'Sun rise  ',
    'Almanac event description (explicit width)';
$default{almanac}{width} = 10;
method almanac => [ field => 'description' ],
    'Sun rise  ',
    'Almanac event description (defaulted width)';
%default = ();
method almanac => [ units => 'event', width => '' ],
    'horizon',
    'Almanac event name (no width)';
method almanac => [ units => 'detail', width => '' ],
    '1',
    'Almanac event detail (no width)';

create data => {
	body	=> Astro::Coord::ECI->new()->geodetic(
	    deg2rad( 40 ), deg2rad( -90 ), 1 ),
    },
    default => \%default, 'Create formatter for altitude data';
method altitude => [], '    1.0', 'Altitude with everything defaulted';
method altitude => [ width => 4 ], ' 1.0',
    'Altitude with specified width';
$default{altitude}{width} = 5;
method altitude => [], '  1.0', 'Altitude with defaulted width';
$default{altitude}{places} = 0;
method altitude => [], '    1', 'Altitude with defauled width and places';
method altitude => [ places => 2 ], ' 1.00',
    'Altitude with defaulted width and specified places';
%default = ();
method altitude => [ units => 'kilometers' ], '    1.0',
    'Altitude specifically in kilometers';
method altitude => [ units => 'km' ], '    1.0',
    'Altitude specifically in km';
method altitude => [ units => 'meters' ], ' 1000.0',
    'Altitude specifically in meters';
method altitude => [ units => 'm' ], ' 1000.0',
    'Altitude specifically in m';
method altitude => [ units => 'miles' ], '    0.6',
    'Altitude specifically in miles';
method altitude => [ units => 'mi' ], '    0.6',
    'Altitude specifically in mi';
method altitude => [ units => 'feet' ], ' 3280.8',
    'Altitude specifically in feet';
method altitude => [ units => 'ft' ], ' 3280.8',
    'Altitude specifically in ft';

create data => {
	angle	=> PI / 2,
	appulse	=> {
	    angle	=> PI / 3,
	},
    },
    default => \%default, 'Create formatter for angle data';
method angle => [], ' 90.0', 'Angle with everything defaulted';
method angle => [ width => 3, places => 0 ], ' 90',
    'Angle with width and places specified';
$default{angle} = { width => 3, places => 0 };
method angle => [ width => 3, places => 0 ], ' 90',
    'Angle with width and places defaulted';
%default = ();
method appulse => [], angle => [], ' 60.0',
    'Appulse angle with everything defaulted';
method angle => [ units => 'degrees' ], ' 90.0',
    'Angle specifically in degrees';
method angle => [ units => 'decimal' ], ' 90.0',
    'Angle specifically in decimal';
method angle => [ places => 2, units => 'radians' ], ' 1.57',
    'Angle specifically in radians';
method angle => [ width => 2, units => 'bearing' ], 'E ',
    'Angle specifically in bearing';
method angle => [ width => '', bearing => 2, units => 'bearing' ], 'E',
    'Angle in bearing with no width';
$default{bearing}{table} = [
    [ qw{ n e s w } ], [ qw{ n ne e se s sw w nw } ] ];
method angle => [ width => 2, units => 'bearing' ], 'e ',
    'Angle specifically in bearing with custom bearing text';
delete $default{bearing};
method angle => [ width => '', units => 'phase' ], 'first quarter',
    'Angle specifically in phase';
$default{phase}{table} = [
    [6.1 => 'nueva'], [83.9 => 'waxing crescent'],
    [96.1 => 'creciente'], [173.9 => 'gibosa creciente'],
    [186.1 => 'llena'], [263.9 => 'gibosa menguante'],
    [276.1 => 'menguante'], [353.9 => 'waning crescent'],
];
method angle => [ width => '', units => 'phase' ], 'creciente',
    'Angle specifically in phase (in Spanish, sort of)';
%default = ();
method angle => [ width => '', units => 'right_ascension' ],
    '06:00:00.0',
    'Angle specifically in right ascension';
method angle => [ width => 10, places => 0, units => 'right_ascension' ],
    '  06:00:00',
    'Angle specifically in right ascension, justified';

my $event = {
    body	=> $body,
    event	=> 7,	# Appulse
    illumination => 2,	# Lit
    station	=> $station,
    time	=> $time,
    appulse => {
	angle => 0.0506145483078356,
	body => $moon->universal( $time ),
    },
};
create data => $event,
    default => \%default,
    time_formatter => $time_formatter,
    'Create formatter for TLE-specific data';

method apoapsis => [], '   356', 'Apoapsis with everything defaulted';
method apoapsis => [ as_altitude => 0 ], '  6734',
    'Apoapsis as distance from center of Earth, not as altitude';
method center => [], apoapsis => [], '      ',
    'Apoapsis of flare center (unavailable)';
method appulse => [], apoapsis => [], '      ',
    'Apoapsis of appulsing body (unavailable)';
method station => [], apoapsis => [], '      ',
    'Apoapsis of observing station (unavailable)';

method apogee => [], '   356', 'Apogee with everything defaulted';
method apogee => [ as_altitude => 0 ], '  6734',
    'Apogee as distance from center of Earth, not as altitude';
method center => [], apogee => [], '      ',
    'Apogee of flare center (unavailable)';
method appulse => [], apogee => [], '      ',
    'Apogee of appulsing body (unavailable)';
method station => [], apogee => [], '      ',
    'Apogee of observing station (unavailable)';

method argument_of_perigee => [], ' 198.7654', 'Argument of perigee';
method center => [], argument_of_perigee => [], '         ',
    'Argument of perigee of flare center (unavailable)';
method appulse => [], argument_of_perigee => [], '         ',
    'Argument of perigee of appulsing body (unavailable)';
method station => [], argument_of_perigee => [], '         ',
    'Argument of perigee of observing station (unavailable)';

method ascending_node => [], '10:39:30.36', 'Ascending node';
method ascending_node =>
    [ width => 9, places => 4, units => 'degrees' ],
    ' 159.8765',
    'Ascending node in degrees';
method center => [], ascending_node => [], '           ',
    'Ascending node of flare center (unavailable)';
method appulse => [], ascending_node => [], '           ',
    'Ascending node of appulsing body (unavailable)';
method station => [], ascending_node => [], '           ',
    'Ascending node of observing station (unavailable)';

method azimuth => [], '153.8', 'Azimuth, defaulting everything';
method azimuth => [ bearing => 2 ], '153.8 SE',
    'Azimuth with 2-character bearing';
method azimuth => [ bearing => 3 ], '153.8 SSE',
    'Azimuth with 3-character bearing';
method appulse => [], azimuth => [], '151.2',
    'Appulse azimuth';
method appulse => [], azimuth => [ bearing => 2 ], '151.2 SE',
    'Appulse azimuth with bearing';

method b_star_drag => [], ' 8.2345e-05', 'B* drag';
method appulse => [], b_star_drag => [], '           ',
    'Appulse B* drag (unavailable)';

method classification => [], 'U', 'Classification';

method date => [], '2008-10-09', 'Date';
method appulse => [], date => [], '2008-10-09', 'Appulse date';
my $old = delete $default{date};
$default{date} = { width => '', places => 5 };
method date => [ units => 'julian' ],
    '2454749.47478',
    'Julian date';
method date => [ units => 'days_since_epoch' ],
    sprintf( '%.5f', ($time - $epoch)/86400 ),
    'Days since epoch';
method appulse => [], date => [ units => 'days_since_epoch' ], '',
    'Appulse days since epoch are undefined';
$default{date} = $old;

method declination => [], '-19.2', 'Declination';
method earth => [], declination => [], ' 33.9',
    'Declination from center of earth';
method appulse => [], declination => [], '-16.8',
    'Declination of appulsing body';
method appulse => [], earth => [], declination => [], '-16.1',
    'Declination of appulsing body, from center of earth';
method earth => [], appulse => [], declination => [], '-16.1',
    'Declination of appulsing body, from center of earth, commuted';
method center => [], declination => [], '     ',
    'Declination of flare center (unavailable)';
method station => [], declination => [], ' 19.2',
    'Declination of station from satellite';

method eccentricity => [], ' 0.00040', 'Eccentricity';

method effective_date => [], '2008-10-09 10:23:02', 'Effective date';
$old = delete $default{effective_date};
$default{effective_date} = { width => '', places => 5 };
method effective_date => [ units => 'julian' ], '2454748.93266',
    'Effective date as Julian day';
method effective_date => [ units => 'days_since_epoch', places => 6 ],
    '-0.020833',
    'Effective date as days since epoch';
$default{effective_date} = $old;
method station => [], effective_date => [], '                   ',
    'Effective date of station (unavailable)';

method element_number => [], ' 456', 'Element number';

method elevation => [], ' 27.5', 'Elevation';
method center => [], elevation => [], '     ',
    'Elevation of center (unavailable)';
method appulse => [], elevation => [], ' 29.2',
    'Elevation of appulsed body';
method station => [], elevation => [], '-32.8',
    'Elevation of station, from satellite';

method ephemeris_type => [], '0', 'Ephemeris type';
method center => [], ephemeris_type => [], ' ',
    'Ephemeris type of center (unavailable)';
method appulse => [], ephemeris_type => [], ' ',
    'Ephemeris type of appulse (unavailable)';
method station => [], ephemeris_type => [], ' ',
    'Ephemeris type of station (unavailable)';

method epoch => [], '2008-10-09 10:53:02', 'Epoch';
$default{epoch} = { width => '', places => 5 };
method epoch => [ units => 'julian' ], '2454748.95350',
    'Epoch in Julian days';
method epoch => [ units => 'days_since_epoch' ], '0.00000',
    'Epoch in days since epoch (always 0)';
delete $default{epoch};
method center => [], epoch => [], '                   ',
    'Epoch of center (unavailable)';
method appulse => [], epoch => [], '                   ',
    'Epoch of appulse (unavailable)';
method station => [], epoch => [], '                   ',
    'Epoch of station (unavailable)';

# Note that the following directly manipulates data inside the formatter
# object, using the references used to set that data. The author will
# not be responsible for what happens if anyone other than the author
# writes code that does this.

method event => [], 'apls ', 'Event';
$event->{event} = 0;
method event => [], '     ', 'Event (0)';
$event->{event} = 1;
method event => [], 'shdw ', 'Event (1)';
$event->{event} = 2;
method event => [], 'lit  ', 'Event (2)';
$event->{event} = 3;
method event => [], 'day  ', 'Event (3)';
$event->{event} = 4;
method event => [], 'rise ', 'Event (4)';
$event->{event} = 5;
method event => [], 'max  ', 'Event (5)';
$event->{event} = 6;
method event => [], 'set  ', 'Event (6)';
$event->{event} = 7;
method event => [], 'apls ', 'Event (7)';
$default{event}{table} = [ undef, undef, undef, undef, undef, undef,
    undef, 'Conj' ];
method event => [], 'Conj ', 'Event with overridden description';
method event => [ units => 'string' ], 'apls ',
    'Event with string formatting gives the unlocalized string';
method event => [ units => 'integer' ], '    7',
    'Event with integer formatting gives the event number';
delete $default{event};

method first_derivative => [], ' 1.2345678900e-08',
    'First derivative (degrees/minute**2)';
method center => [], first_derivative => [], '                 ',
    'First derivative of center (unavailable)';
method appulse => [], first_derivative => [], '                 ',
    'First derivative of appulse (unavailable)';
method station => [], first_derivative => [], '                 ',
    'First derivative of station (unavailable)';

method fraction_lit => [], '    ',
    'Fraction of object lit (unavailable)';
method center => [], fraction_lit => [], '    ',
    'Fraction of flare center lit (unavailable)';
method appulse => [], fraction_lit => [], '0.74',
    'Fraction of appulsed body lit';
method appulse => [], fraction_lit => [ places => 0, units => 'percent' ],
    '  74',
    'Fraction of appulsed body lit, as percent';
method station => [], fraction_lit => [], '    ',
    'Fraction of observing station lit (unavailable)';

method oid => [], ' 25544', 'OID of satellite';
method center => [], oid => [], '      ',
    'OID of flare center (unavailable)';
method appulse => [], oid => [], 'Moon  ',
    'OID of appulsing body';
method station => [], oid => [], '      ',
    'OID of observing station (unavailable)';

method illumination => [], 'lit  ', 'Illumination';
method center => [], illumination => [], '     ',
    'Illumination of flare center (unavailable)';
method appulse => [], illumination => [], '     ',
    'Illumination of appulsed body (unavailable)';
method station => [], illumination => [], 'lit  ',
    'Illumination of observing station (available, but incorrect)';

method inclination => [], ' 51.6426', 'Inclination';
method center => [], inclination => [], '        ',
    'Inclination of flare center (unavailable)';
method appulse => [], inclination => [], '        ',
    'Inclination of appulsed body (unavailable)';
method station => [], inclination => [], '        ',
    'Inclination of observing station (unavailable)';

method inertial => [], '0', 'Inertial indicator';
method center => [], inertial => [], ' ',
    'Inertial indicator of flare center (unavailable)';
method appulse => [], inertial => [], '1',
    'Inertial indicator of appulsed body';
method station => [], inertial => [], '0',
    'Inertial indicator of observing station';

method international => [], '98067A  ',
    'International launch designator';
method center => [], international => [], '        ',
    'International launch designator of flare center (unavailable)';
method appulse => [], international => [], '        ',
    'International launch designator of appulsed body (unavailable)';
method station => [], international => [], '        ',
    'International launch designator of observing station (unavailable)';

method latitude => [], ' 34.0765', 'Latitude of satellite';
method center => [], latitude => [], '        ',
    'Latitude of flare center (unavailable)';
method appulse => [], latitude => [], '-16.0592',
    'Latitude of appulsed body';
method station => [], latitude => [], ' 38.8987',
    'Latitude of observing station';

method longitude => [], ' -74.2084', 'Longitude of satellite';
method center => [], longitude => [], '         ',
    'Longitude of flare center (unavailable)';
method appulse => [], longitude => [], ' -51.2625',
    'Longitude of appulsed body';
method station => [], longitude => [], ' -77.0377',
    'Longitude of observing station';

method magnitude => [], '-1.7', 'Magnitude';
method center => [], magnitude => [], '    ',
    'Magnitude of flare center (unavailable)';
method appulse => [], magnitude => [], '    ',
    'Magnitude of appulsed body (unavailable)';
method station => [], magnitude => [], '    ',
    'Magnitude of observing station (unavailable)';

# Reference implementation for Maidenhead grid:
# http://www.amsat.org/cgi-bin/gridconv

method maidenhead =>  [], 'FM24vb', 'Maidenhead grid of satellite';
method center => [], maidenhead => [], '      ',
    'Maidenhead grid of center (unavailable)';
method appulse => [], maidenhead => [ width => 4 ], 'GH43',
    'Maidenhead grid of appulsed body ( width => 4 )';
method station => [], maidenhead => [], 'FM18lv',
    'Maidenhead grid of observing station';
method station => [], maidenhead => [ places => 2 ], 'FM18  ',
    'Maidenhead grid of observing station ( places => 2 )';
method station => [], maidenhead => [ width => '' ], 'FM18lv',
    'Maidenhead grid of observing station (no width specified)';

method mean_anomaly => [], ' 279.8765', 'Mean anomaly';
method center => [], mean_anomaly => [], '         ',
    'Mean anomaly of flare center (unavailable)';
method appulse => [], mean_anomaly => [], '         ',
    'Mean anomaly of appulsed body (unavailable)';
method station => [], mean_anomaly => [], '         ',
    'Mean anomaly of observing station (unavailable)';

method mean_motion => [], '3.9302701550',
    'Mean motion (degrees/minute)';
method center => [], mean_motion => [], '            ',
    'Mean motion of flare center (unavailable)';
method appulse => [], mean_motion => [], '            ',
    'Mean motion of appulsed body (unavailable)';
method station => [], mean_motion => [], '            ',
    'Mean motion of observing station (unavailable)';

method mma => [], '   ', 'MMA of flare (unavailable)';
method center => [], mma => [], '   ',
    'MMA of flare center (unavailable)';
method appulse => [], mma => [], '   ',
    'MMA of appulsed body (unavailable)';
method station => [], mma => [], '   ',
    'MMA of observing station (unavailable)';

method name => [], 'ISS                     ', 'Name';
method center => [], name => [], '                        ',
    'Name of flare center (unavailable)';
method appulse => [], name => [], 'Moon                    ',
    'Name of appulsed body';
method station => [], name => [], '1600 Pennsylvania Ave NW',
    'Name of observing station';

method operational => [], ' ',
    'Operational status of satellite (unavailable)';
method center => [], operational => [], ' ',
    'Operational status of flare center (unavailable)';
method appulse => [], operational => [], ' ',
    'Operational status of appulsing body (unavailable)';
method station => [], operational => [], ' ',
    'Operational status of observing station (unavailable)';

method periapsis => [], '   351', 'Periapsis with everything defaulted';
method periapsis => [ as_altitude => 0 ], '  6729',
    'Periapsis as distance from center of Earth, not as altitude';
method center => [], periapsis => [], '      ',
    'Periapsis of flare center (unavailable)';
method appulse => [], periapsis => [], '      ',
    'Periapsis of appulsing body (unavailable)';
method station => [], periapsis => [], '      ',
    'Periapsis of observing station (unavailable)';

method perigee => [], '   351', 'Perigee with everything defaulted';
method perigee => [ as_altitude => 0 ], '  6729',
    'Perigee as distance from center of Earth, not as altitude';
method center => [], perigee => [], '      ',
    'Perigee of flare center (unavailable)';
method appulse => [], perigee => [], '      ',
    'Perigee of appulsing body (unavailable)';
method station => [], perigee => [], '      ',
    'Perigee of observing station (unavailable)';

method period => [], '    01:31:36', 'period of satellite';
method period => [ units => 'seconds' ], '        5496',
    'Period of satellite in seconds';
method period => [ units => 'minutes', places => 2 ], '       91.61',
    'Period of satellite in minutes';
method period => [ units => 'hours', places => 3 ], '       1.527',
    'Period of satellite in hours';
method period => [ units => 'days', places => 5 ], '     0.06362',
    'Period of satellite in days';
method center => [], period => [], '            ',
    'Period of flare center (unavailable)';
method appulse => [], period => [], ' 27 07:43:12',
    'Period of appulsed body';
method station => [], period => [], '            ',
    'Period of observing station (unavailable)';

method phase => [], '    ',
    'Phase of satellite (unavailable)';
method phase => [ units => 'phase', width => '' ], '',
    'Phase of satellite as string (unavailable)';
method center => [], phase => [], '    ',
    'Phase of flare center (unavailable)';
method appulse => [], phase => [], ' 119',
    'Phase of appulsed body';
method appulse => [], phase => [ units => 'phase', width => '' ],
    'waxing gibbous',
    'Phase of appulsed body as string';
method station => [], phase => [], '    ',
    'Phase of observing station (unavailable)';

method range => [], '     703.5', 'Range of satellite';
method range => [ units => 'm', places => 0 ], '    703549',
    'Range of satellite in meters';
method center => [], range => [], '          ',
    'Range of flare center (unavailable)';
method appulse => [], range => [], '  389093.9',
    'Range of appulsed body';
method station => [], range => [], '     703.5',
    'Range of observing station (from satellite)';

method revolutions_at_epoch => ' 56789', 'Revolutions at epoch';
method center => [], revolutions_at_epoch => '      ',
    'Revolutions at epoch of flare center (unavailable)';
method appulse => [], revolutions_at_epoch => '      ',
    'Revolutions at epoch of appulsed body (unavailable)';
method station => [], revolutions_at_epoch => '      ',
    'Revolutions at epoch of observing station (unavailable)';

method right_ascension => [], '21:09:19', 'Right ascension';
method earth => [], right_ascension => [], '19:42:37',
    'Right ascension from center of earth';
method appulse => [], right_ascension => [], '21:15:44',
    'Right ascension of appulsing body';
method appulse => [], earth => [], right_ascension => [], '21:14:24',
    'Right ascension of appulsing body, from center of earth';
method center => [], right_ascension => [], '        ',
    'Right ascension of flare center (unavailable)';
method station => [], right_ascension => [], '09:09:19',
    'Right ascension of station from satellite';

method second_derivative => [], ' 1.2345678900e-20',
    'Second derivative (degrees/minute**3)';
method center => [], second_derivative => [], '                 ',
    'Second derivative of center (unavailable)';
method appulse => [], second_derivative => [], '                 ',
    'Second derivative of appulse (unavailable)';
method station => [], second_derivative => [], '                 ',
    'Second derivative of station (unavailable)';

method semimajor => [], '  6732', 'Semimajor axis of satellite';
method center => [], semimajor => [], '      ',
    'Semimajor axis of flare center (unavailable)';
method appulse => [], semimajor => [], '      ',
    'Semimajor axis of appulsed body (unavailable)';
method station => [], semimajor => [], '      ',
    'Semimajor axis of observing station (unavailable)';

method semiminor => [], '  6732', 'Semiminor axis of satellite';
method center => [], semiminor => [], '      ',
    'Semiminor axis of flare center (unavailable)';
method appulse => [], semiminor => [], '      ',
    'Semiminor axis of appulsed body (unavailable)';
method station => [], semiminor => [], '      ',
    'Semiminor axis of observing station (unavailable)';

method status => [],
    '                                                            ',
    'Status of satellite (unavailable)';
method center => [], status => [],
    '                                                            ',
    'Status of flare center (unavailable)';
method appulse => [], status => [],
    '                                                            ',
    'Status of appulsed body (unavailable)';
method station => [], status => [],
    '                                                            ',
    'Status of observing station (unavailable)';

method time => [], '23:23:41', 'Time of day';
method time => [ format => '%I:%M' ], '11:23', 'Time of day with format';
method time => [ units => 'julian', width => 13, places => 5 ],
    '2454749.47478',
    'Time as Julian (same as date)';
method center => [], time => '23:23:41',
    'Time for flare center is the same as for satellite';
method appulse => [], time => '23:23:41',
    'Time for appulsed body is the same as for satellite';
method station => [], time => '23:23:41',
    'Time for observing station is the same as for satellite';
$time_formatter->gmt( 0 );	# Turn off GMT
SKIP: {
    my $tests = 1;

    load_or_skip 'DateTime', $tests;
    # Under circumstances I do not understand, some Perl 5.8.8s seem to
    # throw an exception for the above, but not for the below.  Both
    # should fail, since ::Strftime uses DateTime.
    load_or_skip 'Astro::App::Satpass2::FormatTime::DateTime::Strftime',
	$tests;

    $time_formatter->tz( 'MST7MDT' );	# Zone to US Mountain
    method time => '17:23:41', 'Time of day, Mountain';
    $time_formatter->tz( undef );	# Zone back to default
}
$time_formatter->gmt( 1 );	# Turn on GMT
method time => [], '23:23:41', 'Time of day (round trip on zone)';

method tle => [], <<'EOD', 'TLE';
ISS --effective 2008/283/10:23:02
1 25544U 98067A   08283.45349537  .00007111 10240-12  82345-4 0  4565
2 25544  51.6426 159.8765 0004029 198.7654 279.8765 15.72108062567893
EOD

$default{status} = { missing => '<none>' };
method status => [ width => '' ], '<none>',
    'Status of satellite with defaulted missing text';
delete $default{status};

clone local_coordinates => sub {
	my ( $self ) = @_;
	return join ' ', $self->right_ascension(), $self->declination();
    },
    'Set local coordinates to equatorial by code reference';
method local_coord => [], '21:09:19 -19.2',
    'Expand local_coord equatorial';

clone local_coordinates => 'azel',
    'Set local coordinates to azel by name';
method local_coord => [], ' 27.5 153.8 SE',
    'Expand local_coord azel';

clone local_coordinates => 'azel_rng',
    'Set local coordinates to azel_rng by name';
method local_coord => [], ' 27.5 153.8 SE      703.5',
    'Expand local_coord azel_rng';
method local_coord => [ bearing => 0 ], ' 27.5 153.8      703.5',
    'Expand local_coord azel_rng without bearing';

clone local_coordinates => 'az_rng',
    'Set local coordinates to az_rng by name';
method local_coord => [], '153.8 SE      703.5',
    'Expand local_coord az_rng';

clone local_coordinates => 'equatorial',
    'Set local coordinates to equatorial by name';
method local_coord => [], '21:09:19 -19.2',
    'Expand local_coord equatorial';

clone local_coordinates => 'equatorial_rng',
    'Set local coordinates to equatorial_rng by name';
method local_coord => [], '21:09:19 -19.2      703.5',
    'Expand local_coord equatorial_rng';

clone local_coordinates => sub {
	my ( $self ) = @_;
	return join ' ', $self->elevation(), $self->azimuth( bearing =>
	    2 );
    },
    'Set local coordinates to azel';
method local_coord => [], ' 27.5 153.8 SE',
    'Expand local_coord azel';
method appulse => [], local_coord => [], ' 29.2 151.2 SE',
    'Expand local_coord azel for appulsed body';

method list => [],
    ' 25544 ISS                       34.0765  -74.2084   353.9',
    'List fixed body';
method_good body => [], eci => [ 1000, 1000, 1000 ],
    'Set coordinates inertial';
method list => [],
    ' 25544 ISS                      2008-10-09 10:53:02     01:31:36',
    'List inertial body';


create title => 1, 'Create empty formatter for titles';
method altitude => [], 'Altitud', 'Altitude title';
method angle => [], 'Angle', 'Angle title';
method local_coord => [], 'Eleva  Azimuth      Range',
    'Titles for local_coord azel';
method list => [],
    'OID    Name                     Epoch               Period',
    'Title for list';

done_testing;

my $obj;

sub clone (@) {
    my $title = pop @_;
    my @arg = @_;

    if ( ! $obj ) {
	@_ = ( "$title failed: no object" );
	goto &fail;
    }

    eval {
	$obj = $obj->clone( @arg );
	1;
    } or do {
	$_ = ( "$title failed: $@" );
	goto &fail;
    };
    @_ = ( $title );
    goto &pass;
}

sub create (@) {
    my $title = pop @_;
    my %arg = @_;
    @_ = ( $title );
    $obj = undef;
    eval {
	defined $arg{time_formatter}
	    or $arg{time_formatter} =
		Astro::App::Satpass2::FormatTime->new()->gmt( 1 );
	$obj = Astro::App::Satpass2::FormatValue->new( %arg );
	1;
    } or do {
	@_ = "$title failed: $@";
	goto &fail;
    };
    @_ = ( $title );
    goto &pass;
}

sub method (@) {
    my @args = @_;
    my $title = pop @args;
    my $want = pop @args;

    $obj or do {
	@_ = ( 'No object instantiated' );
	goto &fail;
    };
    my $got = $obj;
    while ( @args ) {
	my ( $method, $parms ) = splice @args, 0, 2;
	$parms ||= [];
	eval {
	    $got = $got->$method( @{ $parms } );
	    1;
	} or do {
	    @_ = "$title failed: $@";
	    goto &fail;
	};
    }
    @_ = ( $got, $want, $title );
    goto &is;
}

sub method_good (@) {
    my @args = @_;
    my $title = pop @args;

    $obj or do {
	@_ = ( 'No object instantiated' );
	goto &fail;
    };
    my $got = $obj;
    while ( @args ) {
	my ( $method, $parms ) = splice @args, 0, 2;
	$parms ||= [];
	eval {
	    $got = $got->$method( @{ $parms } );
	    1;
	} or do {
	    @_ = "$title failed: $@";
	    goto &fail;
	};
    }
    @_ = ( $title );
    goto &pass;
}

1;

# ex: set textwidth=72 :
