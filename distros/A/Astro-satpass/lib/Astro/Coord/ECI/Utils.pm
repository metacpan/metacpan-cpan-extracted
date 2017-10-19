=head1 NAME

Astro::Coord::ECI::Utils - Utility routines for astronomical calculations

=head1 SYNOPSIS

 use Astro::Coord::ECI::Utils qw{:all};
 my $now = time ();
 print "The current Julian day is ", julianday ($now);

=head1 DESCRIPTION

This module was written to provide a home for all the constants and
utility subroutines used by B<Astro::Coord::ECI> and its descendants.
What ended up here was anything that was essentially a subroutine, not
a method.

Because figuring out how to convert to and from Perl time bids fair to
become complicated, this module is also responsible for figuring out how
that is done, and exporting whatever is needful to export. See C<:time>
below for the gory details.

This package exports nothing by default. But all the constants,
variables, and subroutines documented below are exportable, and the
following export tags may be used:

=over

=item :all

This imports everything exportable into your name space.

=item :params

This imports the parameter validation routines C<__classisa> and
C<__instance>.

=item :time

This imports the time routines into your name space. If
L<Time::y2038|Time::y2038> is available, it will be loaded, and both
this tag and C<:all> will import C<gmtime>, C<localtime>, C<time_gm>,
and C<time_local> into your name space. Otherwise,
C<Time::Local|Time::Local> will be loaded, and both this tag and C<:all>
will import C<time_gm> and C<time_local> into your name space.

=item :vector

This imports the vector arithmetic routines. It includes anything whose
name begins with C<'vector_'>.

=back

Under Perl 5.6 you may find that, if you use any of the above tags, you
need to specify them first in your import list.

=head2 The following constants are exportable:

 AU = number of kilometers in an astronomical unit
 JD_OF_EPOCH = the Julian Day of Perl epoch 0
 LIGHTYEAR = number of kilometers in a light year
 PARSEC = number of kilometers in a parsec
 PERL2000 = January 1 2000, 12 noon universal, in Perl time
 PI = the circle ratio, computed as atan2 (0, -1)
 PIOVER2 = half the circle ratio
 SECSPERDAY = the number of seconds in a day
 SECS_PER_SIDERIAL_DAY = seconds in a siderial day
 SPEED_OF_LIGHT = speed of light in kilometers per second
 TWOPI = twice the circle ratio

=head2 The following global variables are exportable:

=head3 $DATETIMEFORMAT

This variable represents the POSIX::strftime format used to convert
times to strings. The default value is '%a %b %d %Y %H:%M:%S' to be
consistent with the behavior of gmtime (or, to be precise, the
behavior of ctime as documented on my system).

=head3 $JD_GREGORIAN

This variable represents the Julian Day of the switch from Julian to
Gregorian calendars. This is used by date2jd(), jd2date(), and the
routines which depend on them, for deciding whether the date is to be
interpreted as in the Julian or Gregorian calendar. Its initial setting
is 2299160.5, which represents midnight October 15 1582 in the Gregorian
calendar, which is the date that calendar was first adopted. This is
slightly different than the value of 2299161 (noon of the same day) used
by Jean Meeus.

If you are interested in historical calculations, you may wish to reset
this appropriately. If you use date2jd to calculate the new value, be
aware of the effect the current setting of $JD_GREGORIAN has on the
interpretation of the date you give.

=head2 In addition, the following subroutines are exportable:

=over 4

=cut

package Astro::Coord::ECI::Utils;

use strict;
use warnings;

our $VERSION = '0.084';
our @ISA = qw{Exporter};

use Carp;
## use Config;
## use Data::Dumper;
use POSIX qw{floor strftime};
use Scalar::Util qw{ blessed };

my @time_routines;

BEGIN {

    # NOTE WELL
    #
    # The logic here should be consistent with the optional-module text
    # emitted by inc/Astro/Coord/ECI/Recommend.pm.
    #

    eval {
	require Time::y2038;
	Time::y2038->import( qw{ gmtime localtime } );

	# sub time_gm
	*time_gm = sub {
	    my @date = @_;
	    $date[5] = _year_adjust( $date[5] );
	    return Time::y2038::timegm( @date );
	};

	# sub time_local
	*time_local = sub {
	    my @date = @_;
	    $date[5] = _year_adjust( $date[5] );
	    return Time::y2038::timelocal( @date );
	};

	@time_routines = ( qw{ gmtime localtime time_gm time_local
	    __tle_year_to_Gregorian_year } );

	1;
    } or do {
	require Time::Local;

	# sub time_gm
	*time_gm = Time::Local->can( 'timegm' );

	# sub time_local
	*time_local = Time::Local->can( 'timelocal' );

	@time_routines = ( qw{ time_gm time_local __tle_year_to_Gregorian_year } );

    };
}

# This subroutine is used to convert year numbers to Perl years in
# accordance with the documentation in the 5.24.0 version of
# Time::Local. It is intended to be called by the Time::y2038 code,
# which expects Perl years.

{
    # The following code is lifted verbatim from Time::Local 1.25.
    # Because that code bases the window used for expanding two-digit
    # years on the local year as of the time the module was loaded, I do
    # too.

    my $ThisYear    = ( localtime() )[5];
    my $Breakpoint  = ( $ThisYear + 50 ) % 100;
    my $NextCentury = $ThisYear - $ThisYear % 100;
    $NextCentury += 100 if $Breakpoint < 50;
    my $Century = $NextCentury - 100;

    # The above code is lifted verbatim from Time::Local 1.25.

    sub _year_adjust {
	my ( $year ) = @_;

	$year < 0
	    and return $year;

	$year >= 1000
	    and return $year - 1900;

	# The following line of code is lifted verbatim from Time::Local
	# 1.25.
	$year += ( $year > $Breakpoint ) ? $Century : $NextCentury;

	return $year;
    }
}

our @EXPORT;
our @EXPORT_OK = ( qw{
	AU $DATETIMEFORMAT $JD_GREGORIAN JD_OF_EPOCH LIGHTYEAR PARSEC
	PERL2000 PI PIOVER2 SECSPERDAY SECS_PER_SIDERIAL_DAY
	SPEED_OF_LIGHT TWOPI acos add_magnitudes asin
	atmospheric_extinction date2epoch date2jd
	decode_space_track_json_time deg2rad distsq dynamical_delta
	embodies epoch2datetime equation_of_time find_first_true
	fold_case format_space_track_json_time intensity_to_magnitude
	jcent2000 jd2date jd2datetime jday2000 julianday
	keplers_equation load_module looks_like_number max min mod2pi
	nutation_in_longitude nutation_in_obliquity obliquity omega
	rad2deg tan theta0 thetag vector_cross_product
	vector_dot_product vector_magnitude vector_unitize __classisa
	__default_station __instance },
	@time_routines );

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    params => [ qw{ __classisa __instance } ],
    time => \@time_routines,
    vector => [ grep { m/ \A vector_ /smx } @EXPORT_OK ],
);

use constant AU => 149597870;		# 1 astronomical unit, per
					# Meeus, Appendix I pg 407.
use constant LIGHTYEAR => 9.4607e12;	# 1 light-year, per Meeus,
					# Appendix I pg 407.
use constant PARSEC => 30.8568e12;	# 1 parsec, per Meeus,
					# Appendix I pg 407.
use constant PERL2000 => time_gm( 0, 0, 12, 1, 0, 2000 );
use constant PI => atan2 (0, -1);
use constant PIOVER2 => PI / 2;
use constant SECSPERDAY => 86400;
use constant SECS_PER_SIDERIAL_DAY => 86164.0905;	# Appendix I, page 408.
use constant SPEED_OF_LIGHT => 299792.458;	# KM/sec, per NIST.
### use constant SOLAR_RADIUS => 1392000 / 2;	# Meeus, Appendix I, page 407.
use constant TWOPI => PI * 2;


=item $angle = acos ($value)

This subroutine calculates the arc in radians whose cosine is the given
value.

=cut

sub acos {
    abs ($_[0]) > 1 and confess <<eod;
Programming error - Trying to take the arc cosine of a number greater
        than 1.
eod
    return atan2 (sqrt (1 - $_[0] * $_[0]), $_[0])
}

=item $mag = add_magnitudes( $mag1, $mag2, ... );

This subroutine computes the total magnitude of a list of individual
magnitudes.  The algorithm comes from Jean Meeus' "Astronomical
Algorithms", Second Edition, Chapter 56, Page 393.

=cut

sub add_magnitudes {
    my @arg = @_;
    my $sum = 0;
    foreach my $mag ( @arg ) {
	$sum += 10 ** ( -0.4 * $mag );
    }
    return -2.5 * log( $sum ) / log( 10 );
}


=item $angle = asin ($value)

This subroutine calculates the arc in radians whose sine is the given
value.

=cut

sub asin {return atan2 ($_[0], sqrt (1 - $_[0] * $_[0]))}


=item $magnitude = atmospheric_extinction ($elevation, $height);

This subroutine calculates the typical atmospheric extinction in
magnitudes at the given elevation above the horizon in radians and the
given height above sea level in kilometers.

The algorithm comes from Daniel W. E. Green's article "Magnitude
Corrections for Atmospheric Extinction", which was published in
the July 1992 issue of "International Comet Quarterly", and is
available online at
L<http://www.cfa.harvard.edu/icq/ICQExtinct.html>. The text of
this article makes it clear that the actual value of the
atmospheric extinction can vary greatly from the typical
values given even in the absence of cloud cover.

=cut

#	Note that the "constant" 0.120 in Aaer (aerosol scattering) is
#	based on a compromise value A0 = 0.050 in Green's equation 3
#	(not exhibited here), which can vary from 0.035 in the winter to
#	0.065 in the summer. This makes a difference of a couple tenths
#	at 20 degrees elevation, but a couple magnitudes at the
#	horizon. Green also remarks that the 1.5 denominator in the
#	same equation (a.k.a. the scale height) can be up to twice
#	that.


sub atmospheric_extinction {
    my ($elevation, $height) = @_;
    my $cosZ = cos (PIOVER2 - $elevation);
    my $X = 1/($cosZ + 0.025 * exp (-11 * $cosZ));	# Green 1
    my $Aray = 0.1451 * exp (-$height / 7.996);	# Green 2
    my $Aaer = 0.120 * exp (-$height / 1.5);	# Green 4
    return ($Aray + $Aaer + 0.016) * $X;	# Green 5, 6
}


=item $jd = date2jd ($sec, $min, $hr, $day, $mon, $yr)

This subroutine converts the given date to the corresponding Julian day.
The inputs are as for B<Time::Local::timegm>; $mon is in the range 0 -
11, and $yr is from 1900, with earlier years being negative. The year 1
BC is represented as -1900.

If less than 6 arguments are provided, zeroes will be prepended to the
argument list as needed.

The date is presumed to be in the Gregorian calendar. If the resultant
Julian Day is before $JD_GREGORIAN, the date is reinterpreted as being
from the Julian calendar.

The only validation is that the month be between 0 and 11 inclusive, and
that the year be not less than -6612 (4713 BC). Fractional days are
accepted.

The algorithm is from Jean Meeus' "Astronomical Algorithms", second
edition, chapter 7 ("Julian Day"), pages 60ff, but the month is
zero-based, not 1-based, and years are 1900-based.

=cut

our $DATETIMEFORMAT;
our $JD_GREGORIAN;
BEGIN {
    $DATETIMEFORMAT = '%a %b %d %Y %H:%M:%S';
    $JD_GREGORIAN = 2299160.5;
}

sub date2jd {
    my @args = @_;
    unshift @args, 0 while @args < 6;
    my ($sec, $min, $hr, $day, $mon, $yr) = @args;
    $mon++;		# Algorithm expects month 1-12.
    $yr += 1900;	# Algorithm expects zero-based year.
    ($yr < -4712) and croak "Error - Invalid year $yr";
    ($mon < 1 || $mon > 12) and croak "Error - Invalid month $mon";
    if ($mon < 3) {
	--$yr;
	$mon += 12;
    }
    my $A = floor ($yr / 100);
    my $B = 2 - $A + floor ($A / 4);
    my $jd = floor (365.25 * ($yr + 4716)) +
	floor (30.6001 * ($mon + 1)) + $day + $B - 1524.5 +
	((($sec || 0) / 60 + ($min || 0)) / 60 + ($hr || 0)) / 24;
    $jd < $JD_GREGORIAN and
	$jd = floor (365.25 * ($yr + 4716)) +
	floor (30.6001 * ($mon + 1)) + $day - 1524.5 +
	((($sec || 0) / 60 + ($min || 0)) / 60 + ($hr || 0)) / 24;
    return $jd;
}

use constant JD_OF_EPOCH => date2jd (gmtime (0));


=item $epoch = date2epoch ($sec, $min, $hr, $day, $mon, $yr)

This is a convenience routine that converts the given date to seconds
since the epoch, going through date2jd() to do so. The arguments are the
same as those of date2jd().

If less than 6 arguments are provided, zeroes will be prepended to the
argument list as needed.

The functionality is the same as B<Time::Local::timegm>, but this
function lacks timegm's limited date range under Perls before 5.12.0. If
you have Perl 5.12.0 or better, the core L<Time::Local|Time::Local>
C<timegm()> will probably do what you want.  If you have an earlier
Perl, L<Time::y2038|Time::y2038> C<timegm()> may do what you want.

=cut

sub date2epoch {
    my @args = @_;
    unshift @args, 0 while @args < 6;
    my ($sec, $min, $hr, $day, $mon, $yr) = @args;
    return (date2jd ($day, $mon, $yr) - JD_OF_EPOCH) * SECSPERDAY +
    (($hr || 0) * 60 + ($min || 0)) * 60 + ($sec || 0);
}

=item $time = decode_space_track_json_time( $string )

This subroutine decodes a time in the format Space Track uses in their
JSON code. This is ISO-8601-ish, but with a possible fractional part and
no zone.

=cut

sub decode_space_track_json_time {
    my ( $string ) = @_;
    $string =~ m{ \A \s*
	( \d+ ) \D+ ( \d+ ) \D+ ( \d+ ) \D+
	( \d+ ) \D+ ( \d+ ) \D+ ( \d+ ) (?: ( [.] \d* ) )? \s* \z }smx
	or return;
    my @time = ( $1, $2, $3, $4, $5, $6 );
    my $frac = $7;
    $time[0] = __tle_year_to_Gregorian_year( $time[0] );
    $time[1] -= 1;
    my $rslt = time_gm( reverse @time );
    defined $frac
	and $frac ne '.'
	and $rslt += $frac;
    return $rslt;
}


# my ( $self, $station, @args ) = __default_station( @_ )
#
# This exportable subroutine checks whether the second argument embodies
# an Astro::Coord::ECI object. If so, the arguments are returned
# verbatim. If not, the 'station' attribute of the invocant is inserted
# after the first argument and the result returned. If the 'station'
# attribute of the invocant has not been set, an exception is thrown.

sub __default_station {
    my ( $self, @args ) = @_;
    if ( ! embodies( $args[0], 'Astro::Coord::ECI' ) ) {
	my $sta = $self->get( 'station' )
	    or croak 'Station attribute not set';
	unshift @args, $sta;
    }
    return ( $self, @args );
}


=item $rad = deg2rad ($degr)

This subroutine converts degrees to radians. If the argument is
C<undef>, C<undef> will be returned.

=cut

sub deg2rad { return defined $_[0] ? $_[0] * PI / 180 : undef }


=item $value = distsq (\@coord1, \@coord2)

This subroutine calculates the square of the distance between the two
sets of Cartesian coordinates. We do not take the square root here
because of cases (e.g. the law of cosines) where we would just have
to square the result again.

B<Notice> that the subroutine does B<not> assume three-dimensional
coordinates. If @coord1 and @coord2 have six entries, you will get a
six-dimensional distance.

=cut

sub distsq {
    my ($a, $b) = @_;
    (ref $a eq 'ARRAY' && ref $b eq 'ARRAY' && @$a == @$b) or
	confess <<eod;
Programming error - Both arguments to distsq must be  references to
        arrays of the same length.
eod

    my $sum = 0;
    my $size = @$a;
    for (my $inx = 0; $inx < $size; $inx++) {
	my $delta = $a->[$inx] - $b->[$inx];
	$sum += $delta * $delta;
    }
    return $sum
}


=item $seconds = dynamical_delta ($time);

This method returns the difference between dynamical and universal time
at the given universal time. That is,

 $dynamical = $time + dynamical_delta ($time)

if $time is universal time.

The algorithm is from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 10, page 78.

=cut

sub dynamical_delta {
    my ($time) = @_;
    my $year = (gmtime $time)[5] + 1900;
    my $t = ($year - 2000) / 100;
    my $correction = .37 * ($year - 2100);	# Meeus' correction to (10.2)
    return (25.3 * $t + 102) * $t + 102		# Meeus (10.2)
	    + $correction;			# Meeus' correction.
}

=item $boolean = embodies ($thingy, $class)

This subroutine represents a safe way to call the 'represents' method on
$thingy. You get back true if and only if $thingy->can('represents')
does not throw an exception and returns true, and
$thingy->represents($class) returns true. Otherwise it returns false.
Any exception is trapped and dismissed.

This subroutine is called 'embodies' because it was too confusing to
call it 'represents', both for the author and for the Perl interpreter.

=cut

sub embodies {
    my ($thingy, $class) = @_;
    my $code = eval {$thingy->can('represents')};
    return $code ? $code->($thingy, $class) : undef;
}


=item ($sec, $min, $hr, $day, $mon, $yr, $wday, $yday, 0) = epoch2datetime ($epoch)

This convenience subroutine converts the given time in seconds from the
system epoch to the corresponding date and time. It is implemented in
terms of jd2date (), with the year and month returned from that
subroutine. The day is a whole number, with the fractional part
converted to hours, minutes, and seconds. The $wday is the day of the
week, with Sunday being 0. The $yday is the day of the year, with
January 1 being 0. The trailing 0 is the summer time (or daylight saving
time) indicator which is always 0 to be consistent with gmtime.

If called in scalar context, it returns the date formatted by
POSIX::strftime, using the format string in $DATETIMEFORMAT.

The functionality is the same as the core C<gmtime()>, but this function
lacks gmtime's limited date range under Perls before 5.12.0. If you have
Perl 5.12.0 or better, the core C<gmtime()> will probably do what you
want.  If you have an earlier Perl, L<Time::y2038|Time::y2038>
C<gmtime()> may do what you want.

The input must convert to a non-negative Julian date. The exact lower
limit depends on the system, but is computed by -(JD_OF_EPOCH * 86400).
For Unix systems with an epoch of January 1 1970, this is -210866760000.

Additional algorithms for day of week and day of year come from Jean
Meeus' "Astronomical Algorithms", 2nd Edition, Chapter 7 (Julian Day),
page 65.

=cut

sub epoch2datetime {
    my ($time) = @_;
    my $day = floor ($time / SECSPERDAY);
    my $sec = $time - $day * SECSPERDAY;
    ($day, my $mon, my $yr, my $greg, my $leap) = jd2date (
	my $jd = $day + JD_OF_EPOCH);
    $day = floor ($day + .5);
    my $min = floor ($sec / 60);
    $sec = $sec - $min * 60;
    my $hr = floor ($min / 60);
    $min = $min - $hr * 60;
    my $wday = ($jd + 1.5) % 7;
    my $yd = floor (275 * ($mon + 1) / 9) - (2 - $leap) * floor (($mon +
	10) / 12) + $day - 31;
    wantarray and return ($sec, $min, $hr, $day, $mon, $yr, $wday, $yd,
	0);
    return strftime ($DATETIMEFORMAT, $sec, $min, $hr, $day, $mon, $yr,
	$wday, $yd, 0);
}


=item $seconds = equation_of_time ($time);

This method returns the equation of time at the given B<dynamical>
time.

The algorithm is from W. S. Smart's "Text-Book on Spherical Astronomy",
as reported in Jean Meeus' "Astronomical Algorithms", 2nd Edition,
Chapter 28, page 185.

=cut

sub equation_of_time {

    my $time = shift;

    my $epsilon = obliquity ($time);
    my $y = tan($epsilon / 2);
    $y *= $y;


#	The following algorithm is from Meeus, chapter 25, page, 163 ff.

    my $T = jcent2000($time);				# Meeus (25.1)
    my $L0 = mod2pi(deg2rad((.0003032 * $T + 36000.76983) * $T	# Meeus (25.2)
	    + 280.46646));
    my $M = mod2pi(deg2rad(((-.0001537) * $T + 35999.05029)	# Meeus (25.3)
	    * $T + 357.52911));
    my $e = (-0.0000001267 * $T - 0.000042037) * $T + 0.016708634;# Meeus (25.4)

    my $E = $y * sin (2 * $L0) - 2 * $e * sin ($M) +
	4 * $e * $y * sin ($M) * cos (2 * $L0) -
	$y * $y * .5 * sin (4 * $L0) -
	1.25 * $e * $e * sin (2 * $M);				# Meeus (28.3)

    return $E * SECSPERDAY / TWOPI;	# The formula gives radians.
}


=item $time = find_first_true ($start, $end, \&test, $limit);

This function finds the first time between $start and $end for which
test ($time) is true. The resolution is $limit, which defaults to 1 if
not specified. If the times are reversed (i.e. the start time is after
the end time) the time returned is the last time test ($time) is true.

The C<test()> function is called with the Perl time as its only
argument. It is assumed to be false for the first part of the interval,
and true for the rest. If this assumption is violated, the result of
this subroutine should be considered meaningless.

The calculation is done by, essentially, a binary search; the interval
is repeatedly split, the function is evaluated at the midpoint, and a
new interval selected based on whether the result is true or false.

Actually, nothing in this function says the independent variable has to
be time.

=cut

sub find_first_true {
    my ($begin, $end, $test, $limit) = @_;
    $limit ||= 1;
    defined $begin
	or confess 'Programming error - $begin undefined';
    defined $end
	or confess 'Programming error - $end undefined';
    if ($limit >= 1) {
	if ($begin <= $end) {
	    $begin = floor ($begin);
	    $end = floor ($end) == $end ? $end : floor ($end) + 1;
	} else {
	    $end = floor ($end);
	    $begin = floor ($begin) == $begin ? $begin : floor ($begin) + 1;
	}
    }
    my $iterator = (
	$end > $begin ?
	sub {$end - $begin > $limit} :
	sub {$begin - $end > $limit}
    );
    while ($iterator->()) {
	my $mid = $limit >= 1 ?
	    floor (($begin + $end) / 2) : ($begin + $end) / 2;
	($begin, $end) = ($test->($mid)) ?
	    ($begin, $mid) : ($mid, $end);
    }
    return $end;
}

=item $folded = fold_case( $text );

This function folds the case of its input, kinda sorta. It maps to
C<CORE::fc> if that is available, otherwise it maps to C<CORE::lc>.

=cut

*fold_case = CORE->can( 'fc' ) || sub ($) { return lc $_[0] };

=item $fmtd = format_space_track_json_time( time() )

This function takes as input a Perl time, and returns that time
in a format consistent with the Space Track JSON data. This is
ISO-8601-ish, in Universal time, but without the zone indicated.

=cut

sub format_space_track_json_time {
    my ( $time ) = @_;
    defined $time
	and $time =~ m/ \S /smx
	or return;
    my @parts = gmtime floor( $time + .5 );
    $parts[4] += 1;
    $parts[5] += 1900;
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d', reverse
	@parts[ 0 .. 5 ];
}

=item $difference = intensity_to_magnitude ($ratio)

This function converts a ratio of light intensities to a difference in
stellar magnitudes. The algorithm comes from Jean Meeus' "Astronomical
Algorithms", Second Edition, Chapter 56, Page 395.

Note that, because of the way magnitudes work (a more negative number
represents a brighter star) you get back a positive result for an
intensity ratio less than 1, and a negative result for an intensity
ratio greater than 1.

=cut

{	# Begin local symbol block
    my $intensity_to_mag_factor;	# Calculate only if needed.
    sub intensity_to_magnitude {
	return - ($intensity_to_mag_factor ||= 2.5 / log (10)) * log ($_[0]);
    }
}


=item ($day, $mon, $yr, $greg, $leap) = jd2date ($jd)

This subroutine converts the given Julian day to the corresponding date.
The returns are year - 1900, month (0 to 11), day (which may have a
fractional part), a Gregorian calendar indicator which is true if the
date is in the Gregorian calendar and false if it is in the Julian
calendar, and a leap (or bissextile) year indicator which is true if the
year is a leap year and false otherwise. The year 1 BC is returned as
-1900 (i.e. as year 0), and so on. The date will probably have a
fractional part (e.g. 2006 1 1.5 for noon January first 2006).

If the $jd is before $JD_GREGORIAN, the date will be in the Julian
calendar; otherwise it will be in the Gregorian calendar.

The input may not be less than 0.

The algorithm is from Jean Meeus' "Astronomical Algorithms", second
edition, chapter 7 ("Julian Day"), pages 63ff, but the month is
zero-based, not 1-based, and the year is 1900-based.

=cut

sub jd2date {
    my ($time) = @_;
    my $mod_jd = $time + 0.5;
    my $Z = floor ($mod_jd);
    my $F = $mod_jd - $Z;
    my $A = (my $julian = $Z < $JD_GREGORIAN) ? $Z : do {
	my $alpha = floor (($Z - 1867216.25)/36524.25);
	$Z + 1 + $alpha - floor ($alpha / 4);
    };
    my $B = $A + 1524;
    my $C = floor (($B - 122.1) / 365.25);
    my $D = floor (365.25 * $C);
    my $E = floor (($B - $D) / 30.6001);
    my $day = $B - $D - floor (30.6001 * $E) + $F;
    my $mon = $E < 14 ? $E - 1 : $E - 13;
    my $yr = $mon > 2 ? $C - 4716 : $C - 4715;
    return ($day, $mon - 1, $yr - 1900, !$julian, ($julian ? !($yr % 4) : (
		$yr % 400 ? $yr % 100 ? !($yr % 4) : 0 : 1)));
##	% 400 ? 1 : $yr % 100 ? 0 : !($yr % 4))));
}


=item ($sec, $min, $hr, $day, $mon, $yr, $wday, $yday, 0) = jd2datetime ($jd)

This convenience subroutine converts the given Julian day to the
corresponding date and time. All this really does is converts its
argument to seconds since the system epoch, and pass off to
epoch2datetime().

The input may not be less than 0.

=cut

sub jd2datetime {
    my ($time) = @_;
    return epoch2datetime(($time - JD_OF_EPOCH) * SECSPERDAY);
}


=item $century = jcent2000 ($time);

Several of the algorithms in Jean Meeus' "Astronomical Algorithms"
are expressed in terms of the number of Julian centuries from epoch
J2000.0 (e.g equations 12.1, 22.1). This subroutine encapsulates
that calculation.

=cut

sub jcent2000 {return jday2000 ($_[0]) / 36525}


=item $jd = jday2000 ($time);

This subroutine converts a Perl date to the number of Julian days
(and fractions thereof) since Julian 2000.0. This quantity is used
in a number of the algorithms in Jean Meeus' "Astronomical
Algorithms".

The computation makes use of information from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 7, page 62.

=cut

sub jday2000 {return ($_[0] - PERL2000) / SECSPERDAY}


=item $jd = julianday ($time);

This subroutine converts a Perl date to a Julian day number.

The computation makes use of information from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 7, page 62.

=cut

sub julianday {return jday2000($_[0]) + 2_451_545.0}

=item $ea = keplers_equation( $M, $e, $prec );

This subroutine solves Kepler's equation for the given mean anomaly
C<$M> in radians, eccentricity C<$e> and precision C<$prec> in radians.
It returns the eccentric anomaly in radians, to the given precision.

The C<$prec> argument is optional, and defaults to the radian equivalent
of 0.001 degrees.

The algorithm is Meeus' equation 30.7, with John M. Steele's amendment
for large values for the correction, given on page 205 of Meeus' book,

This subroutine is B<not> used in the computation of satellite orbits,
since the models have their own implementation.

=cut

sub keplers_equation {
    my ( $mean_anomaly, $eccentricity, $precision ) = @_;
    defined $precision
	or $precision = 1.74533e-5;	# Radians, = 0.001 degrees
    my $curr = $mean_anomaly;
    my $prev;
    # Meeus' equation 30.7, page 199.
    {
	$prev = $curr;
	my $delta = ( $mean_anomaly + $eccentricity * sin( $curr
	    ) - $curr ) / ( 1 - $eccentricity * cos $curr );
	# Steele's correction, page 205
	$curr = $curr + max( -.5, min( .5, $delta ) );
	$precision < abs( $curr - $prev )
	    and redo;
    }
    return $curr;
}

=item $rslt = load_module ($module_name)

This convenience method loads the named module (using 'require'),
throwing an exception if the load fails. If the load succeeds, it
returns the result of the 'require' built-in, which is required to be
true for a successful load.  Results are cached, and subsequent attempts
to load the same module simply give the cached results.

=cut

{	# Local symbol block. Oh, for 5.10 and state variables.
    my %error;
    my %rslt;
    sub load_module {
	my  ($module) = @_;
	exists $error{$module} and croak $error{$module};
	exists $rslt{$module} and return $rslt{$module};
	# I considered Module::Load here, but it appears not to support
	# .pmc files. No, it's not an issue at the moment, but it may be
	# if Perl 6 becomes a reality.
	$rslt{$module} = eval "require $module";
	$@ and croak ($error{$module} = $@);
	return $rslt{$module};
    }
}	# End local symbol block.


=item $boolean = looks_like_number ($string);

This subroutine returns true if the input looks like a number. It uses
Scalar::Util::looks_like_number if that is available, otherwise it uses
its own code, which is lifted verbatim from Scalar::Util 1.19, which in
turn leans heavily on perlfaq4.

=cut

unless (eval {require Scalar::Util; Scalar::Util->import
	('looks_like_number'); 1}) {
    no warnings qw{once};
    *looks_like_number = sub {
	local $_ = shift;

	# checks from perlfaq4
	return 0 if !defined($_) || ref($_);
	return 1 if (/^[+-]?\d+$/); # is a +/- integer
	return 1 if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/); # a C float
	return 1 if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i)
	    or ($] >= 5.006001 and /^Inf$/i);

	return 0;
    };
}


=item $maximum = max (...);

This subroutine returns the maximum of its arguments.  If List::Util can
be loaded and 'max' imported, that's what you get. Otherwise you get a
pure Perl implementation.

=cut

unless (eval {require List::Util; List::Util->import ('max'); 1}) {
    no warnings qw{once};
    *max = sub {
	my $rslt;
	foreach (@_) {
	    defined $_ or next;
	    if (!defined $rslt || $_ > $rslt) {
		$rslt = $_;
	    }
	}
	$rslt;
    };
}


=item $minimum = min (...);

This subroutine returns the minimum of its arguments.  If List::Util can
be loaded and 'min' imported, that's what you get. Otherwise you get a
pure Perl implementation.

=cut

unless (eval {require List::Util; List::Util->import ('min'); 1}) {
    no warnings qw{once};
    *min = sub {
	my $rslt;
	foreach (@_) {
	    defined $_ or next;
	    if (!defined $rslt || $_ < $rslt) {
		$rslt = $_;
	    }
	}
	$rslt;
    };
}


=item $theta = mod2pi ($theta)

This subroutine reduces the given angle in radians to the range 0 <=
$theta < TWOPI.

=cut

sub mod2pi {return $_[0] - floor ($_[0] / TWOPI) * TWOPI}


=item $delta_psi = nutation_in_longitude ($time)

This subroutine calculates the nutation in longitude (delta psi) for
the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. Meeus states that it is good to
0.5 seconds of arc.

=cut

sub nutation_in_longitude {

    my $time = shift;
    my $T = jcent2000 ($time);	# Meeus (22.1)

    my $omega = mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	    1934.136261) * $T + 125.04452));

    my $L = mod2pi (deg2rad (36000.7698 * $T + 280.4665));
    my $Lprime = mod2pi (deg2rad (481267.8813 * $T + 218.3165));
    my $delta_psi = deg2rad ((-17.20 * sin ($omega) - 1.32 * sin (2 * $L)
	    - 0.23 * sin (2 * $Lprime) + 0.21 * sin (2 * $omega))/3600);

    return $delta_psi;
}


=item $delta_epsilon = nutation_in_obliquity ($time)

This subroutine calculates the nutation in obliquity (delta epsilon)
for the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. Meeus states that it is good to
0.1 seconds of arc.

=cut

sub nutation_in_obliquity {

    my $time = shift;
    my $T = jcent2000 ($time);	# Meeus (22.1)

    my $omega = mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	    1934.136261) * $T + 125.04452));

    my $L = mod2pi (deg2rad (36000.7698 * $T + 280.4665));
    my $Lprime = mod2pi (deg2rad (481267.8813 * $T + 218.3165));
    my $delta_epsilon = deg2rad ((9.20 * cos ($omega) + 0.57 * cos (2 * $L) +
	    0.10 * cos (2 * $Lprime) - 0.09 * cos (2 * $omega))/3600);

    return $delta_epsilon;
}


=item $epsilon = obliquity ($time)

This subroutine calculates the obliquity of the ecliptic in radians at
the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. The conversion from universal to
dynamical time comes from chapter 10, equation 10.2  on page 78.

=cut

use constant E0BASE => (21.446 / 60 + 26) / 60 + 23;

sub obliquity {

    my $time = shift;

    my $T = jcent2000 ($time);	# Meeus (22.1)

    my $delta_epsilon = nutation_in_obliquity ($time);

    my $epsilon0 = deg2rad (((0.001813 * $T - 0.00059) * $T - 46.8150)
	    * $T / 3600 + E0BASE);
    return $epsilon0 + $delta_epsilon;
}


=item $radians = omega ($time);

This subroutine calculates the ecliptic longitude of the ascending node
of the Moon's mean orbit at the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff.

=cut

sub omega {
    my $T = jcent2000 (shift);	# Meeus (22.1)
    return mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	    1934.136261) * $T + 125.04452));
}


=item $degrees = rad2deg ($radians)

This subroutine converts the given angle in radians to its equivalent
in degrees. If the argument is C<undef>, C<undef> will be returned.

=cut

sub rad2deg { return defined $_[0] ? $_[0] / PI * 180 : undef }

=item $value = tan ($angle)

This subroutine computes the tangent of the given angle in radians.

=cut

sub tan {return sin ($_[0]) / cos ($_[0])}


=item $value = theta0 ($time);

This subroutine returns the Greenwich hour angle of the mean equinox at
0 hours universal on the day whose time is given (i.e. the argument is
a standard Perl time).

=cut

sub theta0 {
    my ($time) = @_;
    my @t = gmtime $time;
    $t[5] += 1900;
    return thetag( time_gm( 0, 0, 0, @t[3 .. 5] ) );
}


=item $value = thetag ($time);

This subroutine returns the Greenwich hour angle of the mean equinox at
the given time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, equation 12.4, page 88.

=cut


#	Meeus, pg 88, equation 12.4, converted to radians and Perl dates.

sub thetag {
    my ($time) = @_;
    my $T = jcent2000 ($time);
    return mod2pi (4.89496121273579 + 6.30038809898496 *
	    jday2000 ($time))
	    + (6.77070812713916e-06 - 4.5087296615715e-10 * $T) * $T * $T;
}

# time_gm and time_local are actually created at the top of the module.

=item $epoch = time_gm( $yr, $mon, $day, $hr, $min, $sec );

This exportable subroutine is a wrapper for either
C<Time::y2038::timegm()> (if that module is installed) or
C<Time::Local::timegm()> (if not.)

This wrapper is needed because the two modules have subtly different
signatures; L<Time::y2038|Time::y2038> interprets years strictly as Perl
years, whereas L<Time::Local|Time::Local> interprets them differently
depending on the value of the year, and in particular interprets years
greater than 999 as Gregorian years.

=item $epoch = time_local( $yr, $mon, $day, $hr, $min, $sec );

This exportable subroutine is a wrapper for either
C<Time::y2038::timelocal()> (if that module is installed) or
C<Time::Local::timelocal()> (if not.)

This wrapper is needed for the same reason L<time_gm()|/time_gm> is
needed.

=item $a = vector_cross_product( $b, $c );

This subroutine computes and returns the vector cross product of $b and
$c. Vectors are represented by array references.  The cross product is
only defined if both arrays have 3 elements.

=cut

sub vector_cross_product {
    my ( $b, $c ) = @_;
    @{ $b } == 3 and @{ $c } == 3
	or confess 'Programming error - vector_cross_product arguments',
	    ' must be references to arrays of length 3';
    return [
	$b->[1] * $c->[2] - $b->[2] * $c->[1],
	$b->[2] * $c->[0] - $b->[0] * $c->[2],
	$b->[0] * $c->[1] - $b->[1] * $c->[0],
    ];
}

=item $a = vector_dot_product( $b, $c );

This subroutine computes and returns the vector dot product of $b and
$c. Vectors are represented by array references. The dot product is only
defined if both arrays have the same number of elements.

=cut

sub vector_dot_product {
    my ( $b, $c ) = @_;
    @{ $b } == @{ $c }
	or confess 'Programming error - vector_dot_product arguments ',
	    'must be references to arrays of the same length';
    my $prod = 0;
    my $size = @{ $b } - 1;
    foreach my $inx ( 0 .. $size ) {
	$prod += $b->[$inx] * $c->[$inx];
    }
    return $prod;
}

=item $a = vector_magnitude( $b );

This subroutine computes and returns the magnitude of vector $b. The
vector is represented by an array reference.

=cut

sub vector_magnitude {
    my ( $b ) = @_;
    'ARRAY' eq ref $b
	or confess 'Programming error - vector_magnitude argument ',
    'must be a reference to an array';
    my $mag = 0;
    my $size = @{ $b } - 1;
    foreach my $inx ( 0 .. $size ) {
	$mag += $b->[$inx] * $b->[$inx];
    }
    return sqrt $mag;
}

=item $a = vector_unitize( $b );

This subroutine computes and returns a unit vector pointing in the same
direction as $b. The vectors are represented by array references.

=cut

sub vector_unitize {
    my ( $b ) = @_;
    'ARRAY' eq ref $b
	or confess 'Programming error - vector_unitize argument ',
    'must be a reference to an array';
    my $mag = vector_magnitude( $b );
    return [ map { $_ / $mag } @{ $b } ];
}

#	__classisa( 'Foo', 'Bar' );
#
#	Returns true if Foo->isa( 'Bar' ) is true, and false otherwise.
#	In particular, returns false if the first argument is a
#	reference.

sub __classisa {
    my ( $invocant, $class ) = @_;
    ref $invocant and return;
    defined $invocant or return;
    return $invocant->isa( $class );
}

#	__instance( $foo, 'Bar' );
#
#	Returns true if $foo is an instance of 'Bar', and false
#	otherwise. In particular, returns false if $foo is not a
#	reference, or if it is not blessed.

sub __instance {
    my ( $object, $class ) = @_;
    ref $object or return;
    blessed( $object ) or return;
    return $object->isa( $class );
}

#	$epoch_time = __parse_time_iso_8601
#
#	Parse ISO 8601 date/time. I do not intend to expose this, since
#	it will probably go away when the satpass script is dropped. It
#	would actually be in that script except for the fact that it can
#	be more easily tested here, and because of the possibility that
#	it will be used in App::Satpass2.
{

    my %special_day_offset = (
	yesterday => -SECSPERDAY(),
	today => 0,
	tomorrow => SECSPERDAY(),
    );

    sub __parse_time_iso_8601 {
	my ( $string ) = @_;

	my @zone;
	$string =~ s/ \s* (?: ( Z ) |
		( [+-] ) ( \d{2} ) :? ( \d{2} )? ) \z //smx
	    and @zone = ( $1, $2, $3, $4 );
	my @date;

	# ISO 8601 date
	if ( $string =~ m{ \A
		( \d{4} \D? | \d{2} \D )			# year: $1
		(?: ( \d{1,2} ) \D?				# month: $2
		    (?: ( \d{1,2} ) (?: \s* | \D? )		# day: $3
			(?: ( \d{1,2} ) \D?			# hour: $4
			    (?: ( \d{1,2} ) \D?			# minute: $5
				(?: ( \d{1,2} ) \D?		# second: $6
				    ( \d* )			# fract: $7
				)?
			    )?
			)?
		    )?
		)?
		\z
	    }smx ) {
	    @date = ( $1, $2, $3, $4, $5, $6, $7, undef );

	# special-case 'yesterday', 'today', and 'tomorrow'.
	} elsif ( $string =~ m{ \A
		( yesterday | today | tomorrow )	# day: $1
		(?: \D* ( \d{1,2} ) \D?			# hour: $2
		    (?: ( \d{1,2} ) \D?			# minute: $3
			(?: ( \d{1,2} ) \D?		# second: $4
			    ( \d* )			# fract: $5
			)?
		    )?
		)?
		\z }smx ) {
	    my @today = @zone ? gmtime : localtime;
	    @date = ( $today[5] + 1900, $today[4] + 1, $today[3], $2, $3,
		$4, $5, $special_day_offset{$1} );

	} else {

	    return;

	}


	my $offset = pop @date || 0;
	if ( @zone && !$zone[0] ) {
	    my ( undef, $sign, $hr, $min ) = @zone;
	    $offset -= $sign . ( ( $hr * 60 + ( $min || 0 ) ) * 60 )
	}

	foreach ( @date ) {
	    defined $_ and s/ \D+ //smxg;
	}

	$date[0] = __tle_year_to_Gregorian_year( $date[0] );

	defined $date[1] and --$date[1];
	defined $date[2] or $date[2] = 1;
	my $frc = pop @date;

	foreach ( @date ) {
	    defined $_ or $_ = 0;
	}

	my $time;
	if ( @zone ) {
	    $time = time_gm( reverse @date );
	} else {
	    $time = time_local( reverse @date );
	}

	if ( defined $frc  && $frc ne '') {
	    my $denom = 1 . ( 0 x length $frc );
	    $time += $frc / $denom;
	}

	return $time + $offset;
    }

}

=item $year = __tle_year_to_Gregorian_year( $year )

The TLE data contain the year in two-digit form. NORAD decided to deal
with Y2K by decreeing that year numbers lower than 57 (the launch of
Sputnik 1) are converted to Gregorian by adding 2000. Years numbers of
57 or greater are still converted to Gregorian by adding 1900. This
subroutine encapsulates this logic. Years of 100 or greater are returned
unmodified.

This subroutine is B<private> to this package, and can be changed or
revoked without notice.

=cut

sub __tle_year_to_Gregorian_year {
    my ( $year ) = @_;
    return $year < 57 ? $year + 2000 :
	$year < 100 ? $year + 1900 : $year;
}

1;

__END__

=back

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge Jean Meeus, whose book "Astronomical
Algorithms" (second edition) published by Willmann-Bell Inc
(L<http://www.willbell.com/>) provided several of the algorithms
implemented herein.

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org/>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2017 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
