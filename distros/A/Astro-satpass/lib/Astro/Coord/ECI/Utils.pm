=head1 NAME

Astro::Coord::ECI::Utils - Utility routines for astronomical calculations

=head1 SYNOPSIS

 use Astro::Coord::ECI::Utils qw{ :all };
 my $now = time ();
 print "The current Julian day is ", julianday ($now);

=head2 DEPRECATION NOTICE

As of version 0.131, subroutines C<date2epoch()> and C<epoch2datetime()>
are deprecated. These are not used internally. Under Perl 5.12 and
later, C<Time::Local::timegm_posix()> and core C<gmtime()> are
recommended over these subroutines. For earlier Perls, you can try
L<Time::y2038|Time::y2038>.

Six months after the release of version 0.131, these subroutines will
warn on first use. Six months after that, they will warn on every use.
After a further six months, use of them will be fatal.

=head1 DESCRIPTION

This module was written to provide a home for all the constants and
utility subroutines used by B<Astro::Coord::ECI> and its descendants.
What ended up here was anything that was essentially a subroutine, not
a method.

Because figuring out how to convert to and from Perl time bids fair to
become complicated, this module is also responsible for figuring out how
that is done, and exporting whatever is needful to export. See C<:time>
below for the gory details.

This module exports nothing by default. But all the constants,
variables, and subroutines documented below are exportable, and the
following export tags may be used:

=over

=item :all

This imports everything exportable into your name space.

=item :greg_time

This imports all time routines except the discouraged routines
C<time_gm()> and C<time_local()>.

=item :mainstream

This imports everything not deprecated into your name space.

=item :params

This imports the parameter validation routines C<__classisa> and
C<__instance>.

=item :ref

This imports all the C<*_REF> constants.

=item :time

This imports the time routines into your name space. If
L<Time::y2038|Time::y2038> is available, it will be loaded, and both
this tag and C<:all> will import C<gmtime>, C<localtime>, C<time_gm>,
C<time_local>, C<greg_time_gm>, and C<greg_time_local> into your name
space. Otherwise, C<Time::Local|Time::Local> will be loaded, and both
this tag and C<:all> will import C<time_gm>, C<time_local>,
C<greg_time_gm>, and C<greg_time_local> into your name space.

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

 ARRAY_REF  = 'ARRAY'
 CODE_REF   = 'CODE'
 HASH_REF   = 'HASH'
 SCALAR_REF = 'SCALAR'

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

our $VERSION = '0.131';
our @ISA = qw{Exporter};

use Carp;
## use Config;
## use Data::Dumper;
use POSIX qw{ floor modf strftime };
use Scalar::Util qw{ blessed };

my @greg_time_routines;

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
	    $date[5] = _year_adjust_y2038( $date[5] );
	    return Time::y2038::timegm( @date );
	};
	# greg_time_local
	*greg_time_gm = sub {
	    my @date = @_;
	    $date[5] -= 1900;
	    return Time::y2038::timegm( @date );
	};

	# sub time_local
	*time_local = sub {
	    my @date = @_;
	    $date[5] = _year_adjust_y2038( $date[5] );
	    return Time::y2038::timelocal( @date );
	};
	# sub greg_time_local
	*greg_time_local = sub {
	    my @date = @_;
	    $date[5] -= 1900;
	    return Time::y2038::timelocal( @date );
	};

	@greg_time_routines = qw{
	    gmtime localtime
	    greg_time_gm greg_time_local
	    __tle_year_to_Gregorian_year
	};

	1;
    } or do {
	require Time::Local;

	# sub time_gm
	*time_gm = Time::Local->can( 'timegm' );
	# sub greg_time_gm
	*greg_time_gm = Time::Local->can( 'timegm_modern' ) || sub {
	    my @date = @_;
	    $date[5] = _year_adjust_greg( $date[5] );
	    return Time::Local::timegm( @date );
	};

	# sub time_local
	*time_local = Time::Local->can( 'timelocal' );
	# sub greg_time_local
	*greg_time_local = Time::Local->can( 'timelocal_modern' ) || sub {
	    my @date = @_;
	    $date[5] = _year_adjust_greg( $date[5] );
	    return Time::Local::timelocal( @date );
	};

	@greg_time_routines = qw{
	    greg_time_gm greg_time_local
	    __tle_year_to_Gregorian_year
	};

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

    use constant NOT_GREG	=>
	'%d not interpreted as Gregorian year by Time::Local::timegm';

    # Adujst the year so that the Time::y2038 implementation of
    # time_gm() and time_local() mirrors the Time::Local timegm() and
    # timelocal() behavior. Kinda sorta.
    sub _year_adjust_y2038 {
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

# Adjust a Gregorian year so that Time::Local timegm() and timelocal()
# return epochs in that year.
sub _year_adjust_greg {
    my ( $year ) = @_;
    return $year >= 1000 ? $year : $year - 1900;
}

our @CARP_NOT = qw{
    Astro::Coord::ECI
    Astro::Coord::ECI::Mixin
    Astro::Coord::ECI::Moon
    Astro::Coord::ECI::Star
    Astro::Coord::ECI::Sun
    Astro::Coord::ECI::TLE
    Astro::Coord::ECI::TLE::Set
    Astro::Coord::ECI::Utils
};

our @EXPORT;
my @all_external = ( qw{
	AU $DATETIMEFORMAT $JD_GREGORIAN JD_OF_EPOCH LIGHTYEAR PARSEC
	PERL2000 PI PIOVER2 SECSPERDAY SECS_PER_SIDERIAL_DAY
	SPEED_OF_LIGHT TWOPI
	ARRAY_REF CODE_REF HASH_REF SCALAR_REF
	acos add_magnitudes asin
	atmospheric_extinction date2epoch date2jd
	decode_space_track_json_time deg2rad distsq dynamical_delta
	embodies epoch2datetime find_first_true
	fold_case __format_epoch_time_usec
	format_space_track_json_time gm_strftime intensity_to_magnitude
	jcent2000 jd2date jd2datetime jday2000 julianday
	keplers_equation load_module local_strftime
	looks_like_number max min mod2pi
	omega position_angle
	rad2deg rad2dms rad2hms tan theta0 thetag vector_cross_product
	vector_dot_product vector_magnitude vector_unitize __classisa
	__default_station __instance __subroutine_deprecation
	__sprintf
	},
	qw{ time_gm time_local }, @greg_time_routines );
our @EXPORT_OK = (
    qw{ @CARP_NOT },	# Package-private, undocumented
    @all_external,
);

my %deprecated_export = map { $_ => 1 } qw{
};

our %EXPORT_TAGS = (
    all => \@all_external,
    greg_time	=> \@greg_time_routines,
    mainstream => [ grep { ! $deprecated_export{$_} } @all_external ],
    params => [ qw{ __classisa __instance } ],
    ref	=> [ grep { m/ [[:upper:]]+ _REF \z /smx } @all_external ],
    time => [ qw{ gm_strftime local_strftime time_gm time_local },
	@greg_time_routines ],
    vector => [ grep { m/ \A vector_ /smx } @all_external ],
);

use constant AU => 149597870;		# 1 astronomical unit, per
					# Meeus, Appendix I pg 407.
use constant LIGHTYEAR => 9.4607e12;	# 1 light-year, per Meeus,
					# Appendix I pg 407.
use constant PARSEC => 30.8568e12;	# 1 parsec, per Meeus,
					# Appendix I pg 407.
use constant PERL2000 => greg_time_gm( 0, 0, 12, 1, 0, 2000 );
use constant PI => atan2 (0, -1);
use constant PIOVER2 => PI / 2;
use constant SECSPERDAY => 86400;
use constant SECS_PER_SIDERIAL_DAY => 86164.0905;	# Appendix I, page 408.
use constant SPEED_OF_LIGHT => 299792.458;	# KM/sec, per NIST.
### use constant SOLAR_RADIUS => 1392000 / 2;	# Meeus, Appendix I, page 407.
use constant TWOPI => PI * 2;

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant SCALAR_REF	=> ref \0;

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
L<http://www.icq.eps.harvard.edu/ICQExtinct.html>. The text of
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
The inputs are a Perl date and time; $mon is in the range 0 -
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

This subroutine is B<deprecated> as of version 0.131. It will be put
through my usual deprecation cycle (warn on first use after six months,
and so on) and removed.

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
    __subroutine_deprecation();
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
	( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+
	( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+ ( [0-9]+ ) (?: ( [.] [0-9]* ) )? \s* \z }smx
	or return;
    my @time = ( $1, $2, $3, $4, $5, $6 );
    my $frac = $7;
    $time[0] = __tle_year_to_Gregorian_year( $time[0] );
    $time[1] -= 1;
    my $rslt = greg_time_gm( reverse @time );
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
    my ( $x, $y ) = @_;
    ARRAY_REF eq ref $x
	and ARRAY_REF eq ref $y
	and @{ $x } == @{ $y }
	or confess <<'EOD';
Programming error - Both arguments to distsq must be references to
        arrays of the same length.
EOD

    my $sum = 0;
    my $size = @$x;
    for (my $inx = 0; $inx < $size; $inx++) {
	my $delta = $x->[$inx] - $y->[$inx];
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
Edition, Chapter 10, page 78. Meeus notes that this is actually an
observed quantity, and the algorithm is an approximation.

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

This subroutine is B<deprecated> as of version 0.131. It will be put
through my usual deprecation cycle (warn on first use after six months,
and so on) and removed.

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
    __subroutine_deprecation();
    my $day = floor ($time / SECSPERDAY);
    my $sec = $time - $day * SECSPERDAY;
    ($day, my $mon, my $yr, undef, my $leap) = jd2date (
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
    # FIXME this seems to be needed under Perl 5.39.8, but not under
    # earlier Perls.
    local $ENV{TZ} = 'UTC';
    return POSIX::strftime( $DATETIMEFORMAT, $sec, $min, $hr, $day,
	$mon, $yr, $wday, $yd );
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

B<Note> that Space Track does not represent fractional seconds, even in
the epoch. This subroutine deals with this by truncating the epoch to
seconds, and leaving the fractional seconds to the caller to deal with.

=cut

sub format_space_track_json_time {
    my ( $time ) = @_;
    defined $time
	and $time =~ m/ \S /smx
	or return;
    my ( undef, $sec ) = modf( $time );
    my @parts = ( gmtime $sec )[ reverse 0 .. 5 ];
    $parts[0] += 1900;
    $parts[1] += 1;
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d', @parts;
}

=item $fmtd = __format_epoch_time_usec( time(), '%F %T' )

This function takes as input a Perl time with a possible fractional
part, and returns that time as GMT in the given C<strftime> format, but
with seconds expressed to the nearest microsecond.

=cut

sub __format_epoch_time_usec {
    my ( $epoch, $date_format ) = @_;
    return gm_strftime( $date_format, $epoch, 6 );
}

=item print gm_strftime( $format, $epoch, $places )

This subroutine takes as input a strftime-compatible format and an
epoch, and returns the GMT, formatted per the format.

Optional argument C<$places> is the default number of decimal places for
seconds. If defined, it must be either C<''> or an unsigned integer.

You can also specify an optional C<'.d'> (where the 'd' is one or more
decimal digits) before any format specification that generates seconds.
Examples include C<'%.3S'> or C<'%.6T'>. Such a specification overrides
the C<$places> argument, if any.

=cut

sub gm_strftime {
    my ( $format, $epoch ) = _pre_strftime( @_ );
    my @gmt = gmtime $epoch;
    pop @gmt;
    # FIXME this seems to be needed under Perl 5.39.8, but not under
    # earlier Perls.
    local $ENV{TZ} = 'UTC';
    return POSIX::strftime( $format, @gmt );
}

=item $epoch = greg_time_gm( $sec, $min, $hr, $day, $mon, $yr );

This exportable subroutine is a wrapper for either
C<Time::y2038::timegm()> (if that module is installed),
C<Time::Local::timegm_modern()> (if that is available), or
C<Time::Local::timegm()> (if not.)

This subroutine interprets years as Gregorian years.

The difference between this and C<time_gm()> is that C<time_gm()>
interprets the year the way C<Time::Local::timegm()> does.  For that
reason, this subroutine is preferred over c<time_gm()>.

This wrapper is needed because the routines have subtly different
signatures. L<Time::y2038|Time::y2038> C<timegm()> interprets years
strictly as Perl years. L<Time::Local|Time::Local> C<timegm_modern()>
interprets them strictly as Gregorian years. L<Time::Local|Time::Local>
C<timegm()> interprets them differently depending on the value of the
year. Years greater than or equal to 1000 are Gregorian years, but all
others are Perl years, except for the range 0 to 99 inclusive, which are
within 50 years of the current year.

If you are doing historical calculations, see
L<Historical Calculations|Astro::Coord::ECI::Sun/Historical Calculations>
in the L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> documentation
for a discussion of input and output time conversion.

=item $epoch = greg_time_local( $sec, $min, $hr, $day, $mon, $yr );

This exportable subroutine is a wrapper for either
C<Time::y2038::timelocal()> (if that module is installed),
C<Time::Local::timelocal_modern()> (if that is available), or
C<Time::Local::timelocal()> (if not.)

This subroutine interprets years as Gregorian years.

The difference between this and c<time_local()> is that C<time_local()>
interprets the year the way C<Time::Local::timelocal()> does.  For that
reason, this subroutine is preferred over c<time_local()>.

This wrapper is needed for the same reason C<greg_time_gm()> is
needed.

If you are doing historical calculations, see
L<Historical Calculations|Astro::Coord::ECI::Sun/Historical Calculations>
in the L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> documentation
for a discussion of input and output time conversion.

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
	$rslt{$module} = eval "require $module"
	    or croak( $error{$module} = $@ );
	return $rslt{$module};
    }
}	# End local symbol block.

=item print local_strftime( $format, $epoch, $places )

This subroutine takes as input a strftime-compatible format and an
epoch, and returns the local time, formatted per the format.

Optional argument C<$places> is the default number of decimal places for
seconds. If defined, it must be either C<''> or an unsigned integer.

You can also specify an optional C<'.d'> (where the 'd' is one or more
decimal digits) before any format specification that generates seconds.
Examples include C<'%.3S'> or C<'%.6T'>. Such a specification overrides
the C<$places> argument, if any.

=cut

sub local_strftime {
    my ( $format, $epoch ) = _pre_strftime( @_ );
    return POSIX::strftime( $format, localtime $epoch );
}

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
	return 1 if (/^[+-]?[0-9]+$/); # is a +/- integer
	return 1 if (/^([+-]?)(?=[0-9]|\.[0-9])[0-9]*(\.[0-9]*)?([Ee]([+-]?[0-9]+))?$/); # a C float
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

=item $pa = position_angle( $alpha1, $delta1, $alpha2, $delta2 );

This low-level subroutine calculates the position angle in right
ascension of the second body with respect to the first, given the first
body's right ascension and declination and the second body's right
ascension and declination in that order, B<in radians>.

The return is the position angle B<in radians>, in the range
C<< -PI <= $pa < PI >>.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, page 116, but his algorithm is for the position angle of the
first body with respect to the second (i.e. the roles of the two bodies
are reversed). The order of arguments for this subroutine is consistent
with The IDL Astronomy User's Library at
L<https://github.com/wlandsman/IDLAstro>, function C<posang()>. The NASA
page for this, L<https://asd.gsfc.nasa.gov/archive/idlastro/>, is
obsolete and no longer updated, but also more descriptive.

This is exposed because in principal you could calculate the position
angle in any spherical coordinate system, you would just need to get the
order of arguments right (e.g. azimuth, elevation or longitude,
latitude).

=cut

sub position_angle {
    my ( $alpha1, $delta1, $alpha2, $delta2 ) = @_;
    my $delta_alpha = $alpha2 - $alpha1;
    return atan2( sin( $delta_alpha ),
	cos( $delta1 ) * tan( $delta2 ) -
	sin( $delta1 ) * cos( $delta_alpha ) );
}

=item $degrees = rad2deg ($radians)

This subroutine converts the given angle in radians to its equivalent
in degrees. If the argument is C<undef>, C<undef> will be returned.

=cut

sub rad2deg { return defined $_[0] ? $_[0] / PI * 180 : undef }

=item $deg_min_sec = rad2dms( $radians, $decimals, $degree_sign )

This subroutine converts the given angle in radians to its equivalent in
degrees, minutes and seconds, represented as a string. Degrees will be
suppressed if zero, and minutes will be suppressed if both degrees and
minutes are zero. If degrees are present the default delimiter is a
degree sign. The delimiters for minutes and seconds are C<'> and C<">
respectively, with the C<"> appearing before the decimal point.

The optional C<$decimals> argument specifies the number of decimal
places in the seconds value, and defaults to C<3>.

The optional C<$degree_sign> argument specifies the degree sign. The
default is a Unicode degree sign, C<"\N{DEGREE SIGN}">, a.k.a.
C<"\N{U+00B0}">.

=cut

sub rad2dms {
    my ( $rad, $dp, $ds ) = @_;
    defined $rad
	or return $rad;
    defined $dp
	or $dp = 3;
    defined $ds
	or $ds = "\N{U+00B0}";
    my $wid = $dp + 3;

    ( $rad, my $sgn ) = $rad < 0 ? ( -$rad, '-' ) : ( $rad, '' );
    my $sec = rad2deg( $rad );
    ( $sec, my $deg ) = modf( $sec );
    ( $sec, my $min ) = modf( $sec * 60 );
    $sec *= 60;
    my $rslt;
    if ( $deg ) {
	$rslt = sprintf qq<%d$ds%02d'%$wid.${dp}f>, $deg, $min, $sec;
    } elsif ( $min ) {
	$rslt = sprintf qq<%d'%$wid.${dp}f>, $min, $sec;
    } else {
	$rslt = sprintf qq<%.${dp}f>, $sec;
    }
    $rslt =~ s/ [.] /"./smx
	or $rslt .= q<">;
    return "$sgn$rslt";
}

=item $hr_min_sec = rad2hms( $radians, $decimals )

This subroutine converts the given angle in radians to its equivalent in
hours, minutes and seconds (presumably of right ascension), represented
as a string. Hours will be suppressed if zero, and minutes will be
suppressed if both hours and minutes are zero. The delimiters for hours,
minutes, and seconds are C<'h'>, C<'m'>, and C<'s'> respectively, with
the C<'s'> appearing before the decimal point.

The optional C<$decimals> argument specifies the number of decimal
places in the seconds value, and defaults to C<3>.

=cut

sub rad2hms {
    my ( $rad, $dp ) = @_;
    defined $rad
	or return $rad;
    defined $dp
	or $dp = 3;

    my $wid = $dp + 3;
    ( $rad, my $sgn ) = $rad < 0 ? ( -$rad, '-' ) : ( $rad, '' );
    my $sec = $rad * 12 / PI;
    ( $sec, my $hr ) = modf( $sec );
    ( $sec, my $min ) = modf( $sec * 60 );
    $sec *= 60;
    my $rslt;
    if ( $hr ) {
	$rslt = sprintf "%dh%02dm%$wid.${dp}f", $hr, $min, $sec;
    } elsif ( $min ) {
	$rslt = sprintf "%dm%$wid.${dp}f", $min, $sec;
    } else {
	$rslt = sprintf "%.${dp}f", $sec;
    }
    $rslt =~ s/ [.] /s./smx
	or $rslt .= 's';
    return "$sgn$rslt";
}

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
    return thetag( greg_time_gm( 0, 0, 0, @t[3 .. 5] ) );
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

=item $epoch = time_gm( $sec, $min, $hr, $day, $mon, $yr );

This exportable subroutine is a wrapper for either
C<Time::y2038::timegm()> (if that module is installed), or
C<Time::Local::timegm()> (if not.)

This subroutine interprets years the same way C<Time::Local::timegm()>
does.

This wrapper is needed because the routines have subtly different
signatures. L<Time::y2038|Time::y2038> C<timegm()> interprets years
strictly as Perl years. L<Time::Local|Time::Local> C<timegm()>
interprets years differently depending on the value of the year; greater
than 999 as Gregorian years, but other years are Perl years, except for
the years 0 to 99 inclusive, which are interpreted as within 50 years of
the current year.

This subroutine is discouraged in favor of C<greg_time_gm()>, which
always interprets years as Gregorian years.

=item $epoch = time_local( $sec, $min, $hr, $day, $mon, $yr );

This exportable subroutine is a wrapper for either
C<Time::y2038::timelocal()> (if that module is installed), or
C<Time::Local::timelocal()> (if not.)

This subroutine interprets years the same way
C<Time::Local::timelocal()> does.

This wrapper is needed for the same reason C<time_gm()> is
needed.

This subroutine is discouraged in favor of C<greg_time_local()>, which
always interprets years as Gregorian years.

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

=item $m = vector_magnitude( $x );

This subroutine computes and returns the magnitude of vector $x. The
vector is represented by an array reference.

=cut

sub vector_magnitude {
    my ( $x ) = @_;
    ARRAY_REF eq ref $x
	or confess 'Programming error - vector_magnitude argument ',
    'must be a reference to an array';
    my $mag = 0;
    my $size = @{ $x } - 1;
    foreach my $inx ( 0 .. $size ) {
	$mag += $x->[$inx] * $x->[$inx];
    }
    return sqrt $mag;
}

=item $u = vector_unitize( $x );

This subroutine computes and returns a unit vector pointing in the same
direction as $x. The vectors are represented by array references.

=cut

sub vector_unitize {
    my ( $x ) = @_;
    ARRAY_REF eq ref $x
	or confess 'Programming error - vector_unitize argument ',
    'must be a reference to an array';
    my $mag = vector_magnitude( $x );
    return [ map { $_ / $mag } @{ $x } ];
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
		( [+-] ) ( [0-9]{2} ) :? ( [0-9]{2} )? ) \z //smx
	    and @zone = ( $1, $2, $3, $4 );
	my @date;

	# ISO 8601 date
	if ( $string =~ m{ \A
		( [0-9]{4} [^0-9]? | [0-9]{2} [^0-9] )		# year: $1
		(?: ( [0-9]{1,2} ) [^0-9]?			# month: $2
		    (?: ( [0-9]{1,2} ) (?: \s* | [^0-9]? )	# day: $3
			(?: ( [0-9]{1,2} ) [^0-9]?		# hour: $4
			    (?: ( [0-9]{1,2} ) [^0-9]?		# minute: $5
				(?: ( [0-9]{1,2} ) [^0-9]?	# second: $6
				    ( [0-9]* )			# fract: $7
				)?
			    )?
			)?
		    )?
		)?
		\z
	    }smx ) {
	    @date = ( $1, $2, $3, $4, $5, $6, $7, undef );

	# special-case 'yesterday', 'today', and 'tomorrow'.
	} elsif ( $string =~ m< \A
		( yesterday | today | tomorrow )	# day: $1
		(?: [^0-9]* ( [0-9]{1,2} ) [^0-9]?	# hour: $2
		    (?: ( [0-9]{1,2} ) [^0-9]?		# minute: $3
			(?: ( [0-9]{1,2} ) [^0-9]?	# second: $4
			    ( [0-9]* )			# fract: $5
			)?
		    )?
		)?
		\z >smx ) {
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
	    defined $_ and s/ [^0-9]+ //smxg;
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
	    $time = greg_time_gm( reverse @date );
	} else {
	    $time = greg_time_local( reverse @date );
	}

	if ( defined $frc  && $frc ne '') {
	    my $denom = 1 . ( 0 x length $frc );
	    $time += $frc / $denom;
	}

	return $time + $offset;
    }

}

sub _pre_strftime {
    my ( $format, $epoch, $places ) = @_;
    my $seconds = POSIX::floor( $epoch );
    my $frac = $epoch - $seconds;
    $format =~ s( ( %+ ) ( [.] [0-9]* )? ( [DFrRSTV] ) )
    ( _pre_strftime_mung_fmt( $1, $2, $3, $frac, $places ) )smxge;
    return ( $format, $seconds );
};

{
    # The test of __format_epoch_time_usec() (which uses format '%F %T')
    # failed under Windows, at least undef Strawberry, returning the
    # empty string. Expanding %F fixed this, so I decided to expand all
    # the 'equivalent to' format strings I could find.

    my %mung = (
	'D'	=> 'm/%%d/%%y',
	'F'	=> 'Y-%%m-%%d',
	'r'	=> 'I:%%M:%%S%s %%p',
	'R'	=> 'H:%%M',
	'S'	=> 'S%s',
	'T'	=> 'H:%%M:%%S%s',
	'V'	=> 'e-%%b-%%Y',
    );

    sub _pre_strftime_mung_fmt {
	my ( $percent, $places, $fmt, $frac, $dflt_places ) = @_;
	length( $percent ) % 2
	    and $mung{$fmt}
	    or return "$percent$places$fmt";
	my $f = '';
	defined $places
	    or $places = $dflt_places;
	if ( defined $places ) {
	    index( $places, '.' ) == 0
		or substr $places, 0, 0, '.';
	    $places eq '.'
		and $places = '';
	    $f = sprintf "%${places}f", $frac;
	    $f =~ s/ \A 0+ //smx;
	}
	return $percent . __sprintf( $mung{$fmt}, $f );
    }
}

sub __sprintf {
    my ( $tplt, @args ) = @_;
    defined $tplt
	or return undef;	## no critic (ProhibitExplicitReturnUndef)
    no if $] gt '5.021002', qw{ warnings redundant };
    return sprintf $tplt, @args;
}

{
    my %deprecate = (
	epoch2datetime	=> {
	    level	=> 0,
	    method	=> 'core subroutine gmtime',
	},
	date2epoch	=> {
	    level	=> 0,
	    method	=> 'subroutine Time::Local::timegm_posix',
	},
    );

    sub __subroutine_deprecation {
	( my $sub = ( caller 1 )[3] ) =~ s/ .* :: //smx;
	my $info = $deprecate{$sub} or return;
	$info->{level}
	    or return;
	my $msg = "Subroutine $sub() deprecated in favor of @{[
	    $info->{method} || $sub ]}()";
	$info->{level} >= 3
	    and croak $msg;
	carp $msg;
	$info->{level} == 1
	    and $info->{level} = 0;
	return;
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
Algorithms" (second edition) published by Willmann-Bell Inc provided
several of the algorithms implemented herein. Willmann-Bell ceased to be
a separate entity in 2021, but their publications, including Dr. Meeus'
book, are still available through Sky and Telescope's Willmann-Bell
imprint at L<https://shopatsky.com/collections/willmann-bell>.

=head1 BUGS

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-satpass>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2024 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
