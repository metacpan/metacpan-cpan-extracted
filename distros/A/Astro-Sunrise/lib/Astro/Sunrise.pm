# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl extension for computing the sunrise/sunset on a given day
#     Copyright (C) 1999-2003, 2013, 2015, 2017, 2019 Ron Hill and Jean Forget
#
#     See the license in the embedded documentation below.
#
package Astro::Sunrise;

use strict;
use warnings;
use POSIX qw(floor);
use Math::Trig;
use Carp;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $RADEG $DEGRAD );

require Exporter;

@ISA       = qw( Exporter );
@EXPORT    = qw( sunrise sun_rise sun_set );
@EXPORT_OK = qw( DEFAULT CIVIL NAUTICAL AMATEUR ASTRONOMICAL sind cosd tand asind acosd atand atan2d equal );
%EXPORT_TAGS = (
        constants => [ qw/DEFAULT CIVIL NAUTICAL AMATEUR ASTRONOMICAL/ ],
        trig      => [ qw/sind cosd tand asind acosd atand atan2d equal/ ],
        );

$VERSION =  '0.98';
$RADEG   = ( 180 / pi );
$DEGRAD  = ( pi / 180 );
my $INV360     = ( 1.0 / 360.0 );

sub sun_rise {
  my ($sun_rise, undef) = sun_rise_sun_set(@_);
  return $sun_rise;
}
sub sun_set {
  my (undef, $sun_set) = sun_rise_sun_set(@_);
  return $sun_set;
}

sub sun_rise_sun_set {
  my %arg;
  if (ref($_[0]) eq 'HASH') {
    %arg = %{$_[0]};
  }
  else {
    @arg{ qw/lon lat alt offset/ } = @_;
  }

  # This trick aims to fulfill two antagonistic purposes:
  # -- do not load DateTime if the only function called is "sunrise"
  # -- load DateTime implicitly if the user calls "sun_rise" or "sun_set". This is to be backward
  # compatible with 0.92 or earlier, when Astro::Sunrise would load DateTime and thus, allow
  # the user to remove this line from his script.
  unless ($INC{DateTime}) {
    eval "use DateTime";
    croak $@
      if $@;
  }

  my ($longitude, $latitude) = @arg{ qw/lon lat/ };
  my $alt       = defined($arg{alt}      ) ?     $arg{alt}       : -0.833;
  my $offset    = defined($arg{offset}   ) ? int($arg{offset})   : 0 ;
  my $tz        = defined($arg{time_zone}) ?     $arg{time_zone} : 'local';
  $arg{precise}    ||= 0;
  $arg{upper_limb} ||= 0;
  $arg{polar}      ||= 'warn';
  $arg{trace}      ||= 0;
  croak "Longitude parameter (keyword: 'lon') is mandatory"
    unless defined $longitude;
  croak "Latitude parameter (keyword: 'lat') is mandatory"
    unless defined $latitude;
  croak "Wrong value of the 'polar' argument: should be either 'warn' or 'retval'"
    if $arg{polar} ne 'warn' and $arg{polar} ne 'retval';

  my $today = DateTime->today(time_zone => $tz);
  $today->set( hour => 12 );
  $today->add( days => $offset );

  my( $sun_rise, $sun_set ) = sunrise( { year  => $today->year,
                                         month => $today->mon,
                                         day   => $today->mday,
                                         lon   => $longitude,
                                         lat   => $latitude,
                                         tz    => ( $today->offset / 3600 ),
                                         #
                                         # DST is always 0 because DateTime
                                         # currently (v 0.16) adds one to the
                                         # offset during DST hours
                                         isdst      => 0,
                                         alt        => $alt,
                                         precise    => $arg{precise},
                                         upper_limb => $arg{upper_limb},
                                         polar      => $arg{polar},
                                         trace      => $arg{trace},
                                      } );
  return ($sun_rise, $sun_set);
}

sub sunrise  {
  my %arg;
  if (ref($_[0]) eq 'HASH') {
    %arg = %{$_[0]};
  }
  else {
    @arg{ qw/year month day lon lat tz isdst alt precise/ } = @_;
  }
  my (        $year, $month, $day, $lon, $lat, $TZ, $isdst, $trace)
    = @arg{ qw/year   month   day   lon   lat   tz   isdst   trace/ };
  my $altit     = defined($arg{alt}    ) ? $arg{alt}     : -0.833;
  $arg{precise}    ||= 0;
  $arg{upper_limb} ||= 0;
  $arg{polar}      ||= 'warn';
  $trace           ||= 0;
  croak "Year parameter is mandatory"
    unless defined $year;
  croak "Month parameter is mandatory"
    unless defined $month;
  croak "Day parameter is mandatory"
    unless defined $day;
  croak "Longitude parameter (keyword: 'lon') is mandatory"
    unless defined $lon;
  croak "Latitude parameter (keyword: 'lat') is mandatory"
    unless defined $lat;
  croak "Wrong value of the 'polar' argument: should be either 'warn' or 'retval'"
      if $arg{polar} ne 'warn' and $arg{polar} ne 'retval';

  if ($arg{precise})   {
    # This is the initial start
    my $d = days_since_2000_Jan_0($year, $month, $day) - $lon / 360.0;

    if ($trace) {
      print $trace "Precise computation of sunrise for $year-$month-$day, lon $lon, lat $lat, altitude $altit, upper limb $arg{upper_limb}\n";
    }
    my $h1 = 12; # noon, then sunrise
    for my $counter (1..9) {
      # 9 is a failsafe precaution against a possibly runaway loop
      # but hopefully, we will leave the loop long before, with "last"
      my $h2;
      ($h2, undef) = sun_rise_set($d + $h1 / 24, $lon, $lat, $altit, 15.04107, $arg{upper_limb}, $arg{polar}, $trace);
      if ($h2 eq 'day' or $h2 eq 'night') {
        $h1 = $h2;
        last;
      }
      if (equal($h1, $h2, 5)) {
        # equal within 1e-5 hour, a little less than a second
        $h1 = $h2;
        last;
      }
      $h1 = $h2;
    }

    if ($trace) {
      print $trace "Precise computation of sunset for $year-$month-$day, lon $lon, lat $lat, altitude $altit, upper limb $arg{upper_limb}\n";
    }
    my $h3 = 12; # noon at first, then sunset
    for my $counter (1..9) {
      # 9 is a failsafe precaution against a possibly runaway loop
      # but hopefully, we will leave the loop long before, with "last"
      my $h4;
      (undef, $h4) = sun_rise_set($d + $h3 / 24, $lon, $lat, $altit, 15.04107, $arg{upper_limb}, $arg{polar}, $trace);
      if ($h4 eq 'day' or $h4 eq 'night') {
        $h3 = $h4;
        last;
      }
      if (equal($h3, $h4, 5)) {
        # equal within 1e-5 hour, a little less than a second
        $h3 = $h4;
        last;
      }
      $h3 = $h4;
    }

    return convert_hour($h1, $h3, $TZ, $isdst);

  }
  else {
    if ($trace) {
      print $trace "Basic computation of sunrise and sunset for $year-$month-$day, lon $lon, lat $lat, altitude $altit, upper limb $arg{upper_limb}\n";
    }
    my $d = days_since_2000_Jan_0( $year, $month, $day ) + 0.5 - $lon / 360.0;
    my ($h1, $h2) = sun_rise_set($d, $lon, $lat, $altit, 15.0, $arg{upper_limb}, $arg{polar}, $trace);
    if ($h1 eq 'day' or $h1 eq 'night' or $h2 eq 'day' or $h2 eq 'night') {
      return ($h1, $h2);
    }
    return convert_hour($h1, $h2, $TZ, $isdst);
  }
}
#######################################################################################
# end sunrise
###################################################################################

#
#
# FUNCTIONAL SEQUENCE for days_since_2000_Jan_0 
#
# _GIVEN
# year, month, day
#
# _THEN
#
# process the year month and day (counted in days)
# Day 0.0 is at Jan 1 2000 0.0 UT
# Note that ALL divisions here should be INTEGER divisions
#
# _RETURN
#
# day number
#
sub days_since_2000_Jan_0 {
    use integer;
    my ( $year, $month, $day ) = @_;

    my $d =   367 * $year
            - int( ( 7 * ( $year + ( ($month + 9) / 12 ) ) ) / 4 )
            + int( (275 * $month) / 9 )
            + $day - 730530;

    return $d;

}

#
#
# FUNCTIONAL SEQUENCE for convert_hour 
#
# _GIVEN
# Hour_rise, Hour_set, Time zone offset, DST setting
# hours are in UT
#
# _THEN
#
# convert to local time
# 
#
# _RETURN
#
# hour:min rise and set 
#

sub convert_hour {
  my ($hour_rise_ut, $hour_set_ut, $TZ, $isdst) = @_;
  return (convert_1_hour($hour_rise_ut, $TZ, $isdst),
          convert_1_hour($hour_set_ut,  $TZ, $isdst));
}
#
#
# FUNCTIONAL SEQUENCE for convert_1_hour
#
# _GIVEN
# Hour, Time zone offset, DST setting
# hours are in UT
#
# _THEN
#
# convert to local time
#
#
# _RETURN
#
# hour:min
#

sub convert_1_hour {
  my ($hour_ut, $TZ, $isdst) = @_;

  if ($hour_ut eq 'day' or $hour_ut eq 'night') {
    return $hour_ut;
  }

  my $hour_local = $hour_ut + $TZ;
  if ($isdst) {
    $hour_local ++;
  }

  # The hour should be between 0 and 24;
  if ($hour_local < 0) {
    $hour_local += 24;
  }
  elsif ($hour_local > 24) {
    $hour_local -= 24;
  }

  my $hour =  int ($hour_local);

  my $min  = floor(($hour_local - $hour) * 60 + 0.5);

  if ($min >= 60) {
    $min -= 60;
    $hour++;
    $hour -= 24 if $hour >= 24;
  }

  return sprintf("%02d:%02d", $hour, $min);
}


sub sun_rise_set {
    my ($d, $lon, $lat,$altit, $h, $upper_limb, $polar, $trace) = @_;

    # Compute local sidereal time of this moment
    my $sidtime = revolution( GMST0($d) + 180.0 + $lon );

    # Compute Sun's RA + Decl + distance at this moment
    my ( $sRA, $sdec, $sr ) = sun_RA_dec($d, $lon, $trace);

    # Compute time when Sun is at south - in hours UT
    my $tsouth  = 12.0 - rev180( $sidtime - $sRA ) / 15.0;
    if ($trace) {
      printf $trace "For day $d (%s), sidereal time $sidtime, right asc $sRA\n", _fmt_hr(24 * ($d - int($d)), $lon);
      printf $trace "For day $d (%s), solar noon at $tsouth (%s)\n", _fmt_hr(24 * ($d - int($d)), $lon), _fmt_hr($tsouth, $lon);
    }

    if ($upper_limb) {
        # Compute the Sun's apparent radius, degrees
        my $sradius = 0.2666 / $sr;
        $altit -= $sradius;
    }

    # Compute the diurnal arc that the Sun traverses to reach
    # the specified altitude altit:
    my $cost =   ( sind($altit) - sind($lat) * sind($sdec) )
               / ( cosd($lat) * cosd($sdec) );

    my $t;
    if ( $cost >= 1.0 ) {
      if ($polar eq 'retval') {
        return ('night', 'night');
      }
      carp "Sun never rises!!\n";
      $t = 0.0;    # Sun always below altit
    }
    elsif ( $cost <= -1.0 ) {
      if ($polar eq 'retval') {
        return ('day', 'day');
      }
      carp "Sun never sets!!\n";
      $t = 12.0;    # Sun always above altit
    }
    else {
      my $arc = acosd($cost);    # The diurnal arc
      $t = $arc / $h;            # Time to traverse the diurnal arc, hours
      if ($trace) {
        printf $trace "Diurnal arc $arc -> $t hours (%s)\n", _fmt_dur($t);
      }
    }

    # Store rise and set times - in hours UT

    my $hour_rise_ut = $tsouth - $t;
    my $hour_set_ut  = $tsouth + $t;
    if ($trace) {
      printf $trace "For day $d (%s), sunrise at $hour_rise_ut (%s)\n", _fmt_hr(24 * ($d - int($d)), $lon),
                   _fmt_hr($hour_rise_ut, $lon);
      printf $trace "For day $d (%s), sunset  at $hour_set_ut (%s)\n",  _fmt_hr(24 * ($d - int($d)), $lon),
                   _fmt_hr($hour_set_ut , $lon);
    }
    return($hour_rise_ut, $hour_set_ut);
}

#########################################################################################################
#
#
# FUNCTIONAL SEQUENCE for GMST0
#
# _GIVEN
# Day number
#
# _THEN
#
# computes GMST0, the Greenwich Mean Sidereal Time
# at 0h UT (i.e. the sidereal time at the Greenwich meridian at
# 0h UT).  GMST is then the sidereal time at Greenwich at any
# time of the day..
#
#
# _RETURN
#
# Sidtime
#
sub GMST0 {
    my ($d) = @_;

    my $sidtim0 = revolution(   ( 180.0 + 356.0470 + 282.9404 )
                              + ( 0.9856002585 + 4.70935E-5 ) * $d );
    return $sidtim0;

}

#
#
# FUNCTIONAL SEQUENCE for sun_RA_dec
#
# _GIVEN
# day number, $r and $lon (from sunpos)
#
# _THEN
#
# compute RA and dec
# 
#
# _RETURN
#
# Sun's Right Ascension (RA), Declination (dec) and distance (r)
# 
#
sub sun_RA_dec {
    my ($d, $lon_noon, $trace) = @_;

    # Compute Sun's ecliptical coordinates 
    my ( $r, $lon ) = sunpos($d);
    if ($trace) {
      printf $trace "For day $d (%s), solar noon at ecliptic longitude $lon\n", _fmt_hr(24 * ($d - int($d)), $lon_noon),;
    }

    # Compute ecliptic rectangular coordinates (z=0) 
    my $x = $r * cosd($lon);
    my $y = $r * sind($lon);

    # Compute obliquity of ecliptic (inclination of Earth's axis) 
    my $obl_ecl = 23.4393 - 3.563E-7 * $d;

    # Convert to equatorial rectangular coordinates - x is unchanged 
    my $z = $y * sind($obl_ecl);
    $y    = $y * cosd($obl_ecl);

    # Convert to spherical coordinates 
    my $RA  = atan2d( $y, $x );
    my $dec = atan2d( $z, sqrt( $x * $x + $y * $y ) );

    return ( $RA, $dec, $r );

}    # sun_RA_dec


#
#
# FUNCTIONAL SEQUENCE for sunpos
#
# _GIVEN
#  day number
#
# _THEN
#
# Computes the Sun's ecliptic longitude and distance
# at an instant given in d, number of days since
# 2000 Jan 0.0.
#
#
# _RETURN
#
# ecliptic longitude and distance
# ie. $True_solar_longitude, $Solar_distance
#
sub sunpos {
    my ($d) = @_;

    #                       Mean anomaly of the Sun
    #                       Mean longitude of perihelion
    #                         Note: Sun's mean longitude = M + w
    #                       Eccentricity of Earth's orbit
    #                       Eccentric anomaly
    #                       x, y coordinates in orbit
    #                       True anomaly

    # Compute mean elements
    my $Mean_anomaly_of_sun = revolution( 356.0470 + 0.9856002585 * $d );
    my $Mean_longitude_of_perihelion = 282.9404 + 4.70935E-5 * $d;
    my $Eccentricity_of_Earth_orbit  = 0.016709 - 1.151E-9 * $d;

    # Compute true longitude and radius vector
    my $Eccentric_anomaly =   $Mean_anomaly_of_sun
                            + $Eccentricity_of_Earth_orbit * $RADEG
                               * sind($Mean_anomaly_of_sun)
                               * ( 1.0 + $Eccentricity_of_Earth_orbit * cosd($Mean_anomaly_of_sun) );

    my $x = cosd($Eccentric_anomaly) - $Eccentricity_of_Earth_orbit;

    my $y = sqrt( 1.0 - $Eccentricity_of_Earth_orbit * $Eccentricity_of_Earth_orbit )
            * sind($Eccentric_anomaly);

    my $Solar_distance = sqrt( $x * $x + $y * $y );    # Solar distance
    my $True_anomaly = atan2d( $y, $x );               # True anomaly

    my $True_solar_longitude = $True_anomaly + $Mean_longitude_of_perihelion;    # True solar longitude

    if ( $True_solar_longitude >= 360.0 ) {
      $True_solar_longitude -= 360.0;    # Make it 0..360 degrees
    }

    return ( $Solar_distance, $True_solar_longitude );
}



sub sind {
    sin( ( $_[0] ) * $DEGRAD );
}

sub cosd {
    cos( ( $_[0] ) * $DEGRAD );
}

sub tand {
    tan( ( $_[0] ) * $DEGRAD );
}

sub atand {
    ( $RADEG * atan( $_[0] ) );
}

sub asind {
    ( $RADEG * asin( $_[0] ) );
}

sub acosd {
    ( $RADEG * acos( $_[0] ) );
}

sub atan2d {
    ( $RADEG * atan2( $_[0], $_[1] ) );
}

#
#
# FUNCTIONAL SEQUENCE for revolution
#
# _GIVEN
# any angle
#
# _THEN
#
# reduces any angle to within the first revolution 
# by subtracting or adding even multiples of 360.0
# 
#
# _RETURN
#
# the value of the input is >= 0.0 and < 360.0
#

sub revolution {
    my $x = $_[0];
    return ( $x - 360.0 * floor( $x * $INV360 ) );
}

#
#
# FUNCTIONAL SEQUENCE for rev180
#
# _GIVEN
# 
# any angle
#
# _THEN
#
# Reduce input to within -180..+180 degrees
# 
#
# _RETURN
#
# angle that was reduced
#
sub rev180 {
    my ($x) = @_;
    
    return ( $x - 360.0 * floor( $x * $INV360 + 0.5 ) );
}

sub equal {
    my ($A, $B, $dp) = @_;

    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}

sub _fmt_hr {
  my ($utc, $lon) = @_;
  my $lmt = $utc + $lon / 15;
  my $hr_utc = floor($utc);
  $utc      -= $hr_utc;
  $utc      *= 60;
  my $mn_utc = floor($utc);
  $utc      -= $mn_utc;
  $utc      *= 60;
  my $sc_utc = floor($utc);
  my $hr_lmt = floor($lmt);
  $lmt      -= $hr_lmt;
  $lmt      *= 60;
  my $mn_lmt = floor($lmt);
  $lmt      -= $mn_lmt;
  $lmt      *= 60;
  my $sc_lmt = floor($lmt);
  return sprintf("%02d:%02d:%02d UTC %02d:%02d:%02d LMT", $hr_utc, $mn_utc, $sc_utc, $hr_lmt, $mn_lmt, $sc_lmt);
}

sub _fmt_dur {
  my ($dur) = @_;
  my $hr = floor($dur);
  $dur  -= $hr;
  $dur  *= 60;
  my $mn = floor($dur);
  $dur  -= $mn;
  $dur  *= 60;
  my $sc = floor($dur);
  return sprintf("%02d h %02d mn %02d s", $hr, $mn, $sc);
}


sub DEFAULT      () { -0.833 }
sub CIVIL        () { - 6 }
sub NAUTICAL     () { -12 }
sub AMATEUR      () { -15 }
sub ASTRONOMICAL () { -18 }

# Ending a module with whatever, which risks to be zero, is wrong.
# Ending a module with 1 is boring. So, let us end it with:
1950;
# Hint: directed by BW, with GS, WH and EVS

__END__

=encoding utf8

=head1 NAME

Astro::Sunrise - Perl extension for computing the sunrise/sunset on a given day

=head1 VERSION

This documentation refers to C<Astro::Sunrise> version 0.98.

=head1 SYNOPSIS

  # When did the sun rise on YAPC::Europe 2015?
  use Astro::Sunrise;
  my ($sunrise, $sunset) = sunrise( { year => 2015, month => 9, day => 2, # YAPC::EU starts on 2nd September 2015
                                      lon  => -3.6, lat   => 37.17,       # Granada is 37°10'N, 3°36'W
                                      tz   => 1,    isdst => 1 } );       # This is still summer, therefore DST

  # When does the sun rise today in Salt Lake City (home to YAPC::NA 2015)?
  use Astro::Sunrise;
  use DateTime;
  $sunrise_today = sun_rise( { lon => -111.88, lat => 40.75 } ); # 40°45'N, 111°53'W

  # And when does it set tomorrow at Salt Lake City?
  use Astro::Sunrise;
  use DateTime;
  $sunset_tomorrow = sun_set( { lat => 40.75,    # 40°45'N,
                                lon => -111.88,  # 111°53'W
                                alt => -0.833,   # standard value for the sun altitude at sunset
                                offset => 1 } ); # day offset up to tomorrow

=head1 DESCRIPTION

This module will return the sunrise and sunset for a given day.

Months are numbered 1 to 12, in the usual way, not 0 to 11 as in
C and in Perl's localtime.

 Eastern longitude is entered as a positive number
 Western longitude is entered as a negative number
 Northern latitude is entered as a positive number
 Southern latitude is entered as a negative number

Please note that, when given as positional parameters, the longitude is specified before the
latitude.

The time zone is given as the numeric value of the offset from UTC.

The C<precise> parameter is set to either 0 or 1.
If set to 0 no Iteration will occur.
If set to 1 Iteration will occur, which will give a more precise result.
Default is 0.

There are a number of sun altitudes to chose from.  The default is
-0.833 because this is what most countries use. Feel free to
specify it if you need to. Here is the list of values to specify
altitude (ALT) with, including symbolic constants for each.

=over

=item B<0> degrees

Center of Sun's disk touches a mathematical horizon

=item B<-0.25> degrees

Sun's upper limb touches a mathematical horizon

=item B<-0.583> degrees

Center of Sun's disk touches the horizon; atmospheric refraction accounted for

=item B<-0.833> degrees, DEFAULT

Sun's upper limb touches the horizon; atmospheric refraction accounted for

=item B<-6> degrees, CIVIL

Civil twilight (one can no longer read outside without artificial illumination)

=item B<-12> degrees, NAUTICAL

Nautical twilight (navigation using a sea horizon no longer possible)

=item B<-15> degrees, AMATEUR

Amateur astronomical twilight (the sky is dark enough for most astronomical observations)

=item B<-18> degrees, ASTRONOMICAL

Astronomical twilight (the sky is completely dark)

=back

=head1 USAGE

=head2 B<sunrise>

  ($sunrise, $sunset) = sunrise( { year    => $year,      month      => $month,
                                   day     => $day,
                                   lon     => $longitude, lat        => $latitude,
                                   tz      => $tz_offset, isdst      => $is_dst,
                                   alt     => $altitude,  upper_limb => $upper_limb,
                                   precise => $precise,   polar      => $action,
                                   trace   => $fh } );

  ($sunrise, $sunset) = sunrise(YYYY,MM,DD,longitude,latitude,Time Zone,DST);

  ($sunrise, $sunset) = sunrise(YYYY,MM,DD,longitude,latitude,Time Zone,DST,ALT);

  ($sunrise, $sunset) = sunrise(YYYY,MM,DD,longitude,latitude,Time Zone,DST,ALT,precise);

Returns the sunrise and sunset times, in HH:MM format.

The first form uses a hash reference to pass arguments by name.
The other forms are kept for backward compatibility. The arguments are:

=over 4

=item year, month, day

The three elements of the date for which you want to compute the sunrise and sunset.
Months are numbered 1 to 12, in the usual way, not 0 to 11 as in C and in Perl's localtime.

Mandatory, can be positional (#1, #2 and #3).

=item lon, lat

The longitude and latitude of the place for which you want to compute the sunrise and sunset.
They are given in decimal degrees. For example:

    lon => -3.6,  #  3° 36' W
    lat => 37.17, # 37° 10' N

 Eastern longitude is entered as a positive number
 Western longitude is entered as a negative number
 Northern latitude is entered as a positive number
 Southern latitude is entered as a negative number

Mandatory, can be positional (#4 and #5).

=item tz

Time Zone is the offset from GMT

Mandatory, can be positional (#6).

=item isdst

1 if daylight saving time is in effect, 0 if not.

Mandatory, can be positional (#7).

=item alt

Altitude of the sun, in decimal degrees. Usually a negative number,
because the sun should be I<under> the mathematical horizon.
But if there is a high mountain range sunward (that is, southward if you
live in the Northern hemisphere), you may need to enter a positive altitude.

This parameter is optional. Its default value is -0.833. It can be positional (#8).

=item upper_limb

If this parameter set to a true value (usually 1), the algorithm computes
the sun apparent radius and takes it into account when computing the sun
altitude. This parameter is useful only when the C<alt> parameter is set
to C<0> or C<-0.583> degrees. When using C<-0.25> or C<-0.833> degrees,
the sun radius is already taken into account. When computing twilights
(C<-6> to C<-18>), the sun radius is irrelevant.

Since the default value for the C<alt> parameter is -0.833, the
default value for C<upper_limb> is 0.

This parameter is optional and it can be specified only by keyword.

=item polar

When dealing with a polar location, there may be dates where there is
a polar night (sun never rises) or a polar day. The default behaviour of
the module is to emit a warning in these cases ("Sun never rises!!"
or "Sun never sets!!"). But some programmers may find this inconvenient.
An alternate behaviour is to return special values reflecting the
situation.

So, if the C<polar> parameter is set to C<'warn'>, the module emits
a warning. If the C<polar> parameter is set to C<'retval'>, the
module emits no warning, but it returns either C<'day'> or C<'night'>.

Example:

  # Loosely based on Alex Gough's activities: scientist and Perl programmer, who spent a year
  # in Halley Base in 2006. Let us suppose he arrived there on 15th January 2006.
  my ($sunrise, $sunset) = sunrise( { year => 2006, month => 1, day => 15,
                                      lon => -26.65, lat => -75.58, # Halley Base: 75°35'S 26°39'W
                                      tz  => 3, polar => 'retval' } );
  if ($sunrise eq 'day') {
    say "Alex Gough saw the midnight sun the first day he arrived at Halley Base";
  }
  elsif ($sunrise eq 'night') {
    say "It would be days, maybe weeks, before the sun would rise.";
  }
  else {
    say "Alex saw his first antarctic sunset at $sunset";
  }

This parameter is optional and it can be specified only by keyword.

=item trace

This parameter should either be a false value or a filehandle opened for output.
In the latter case, a few messages are printed to the filehandle, which allows
the programmer to see step by step how the sunrise and the sunset are computed.

Used for analysis and debugging purposes. You need to read the text
F<doc/astronomical-notes.pod> to understand what the traced values
represent.

This parameter is optional and it can be specified only by keyword.

=item precise

Choice between a precise algorithm and a simpler algorithm.
The default value is 0, that is, the simpler algorithm.
Any true value switches to the precise algorithm.

The original method only gives an approximate value of the Sun's rise/set times.
The error rarely exceeds one or two minutes, but at high latitudes, when the Midnight Sun
soon will start or just has ended, the errors may be much larger. If you want higher accuracy,
you must then use the precise algorithm. This feature is new as of version 0.7. Here is
what I have tried to accomplish with this.

a) Compute sunrise or sunset as always, with one exception: to convert LHA from degrees to hours,
   divide by 15.04107 instead of 15.0 (this accounts for the difference between the solar day
   and the sidereal day).

b) Re-do the computation but compute the Sun's RA and Decl, and also GMST0, for the moment
   of sunrise or sunset last computed.

c) Iterate b) until the computed sunrise or sunset no longer changes significantly.
   Usually 2 iterations are enough, in rare cases 3 or 4 iterations may be needed.

This parameter is optional. It can be positional (#9).

=back

=head3 I<For Example>

 ($sunrise, $sunset) = sunrise( 2001, 3, 10, 17.384, 98.625, -5, 0 );
 ($sunrise, $sunset) = sunrise( 2002, 10, 14, -105.181, 41.324, -7, 1, -18);
 ($sunrise, $sunset) = sunrise( 2002, 10, 14, -105.181, 41.324, -7, 1, -18, 1);

=head2 B<sun_rise>, B<sun_set>

  $sun_rise = sun_rise( { lon => $longitude, lat => $latitude,
                          alt => $altitude, upper_limb => $bool,
                          offset  => $day_offset,
                          precise => $bool_precise, polar => $action } );
  $sun_set  = sun_set ( { lon => $longitude, lat => $latitude,
                          alt => $altitude, upper_limb => $bool,
                          offset  => $day_offset,
                          precise => $bool_precise, polar => $action } );
  $sun_rise = sun_rise( $longitude, $latitude );
  $sun_rise = sun_rise( $longitude, $latitude, $alt );
  $sun_rise = sun_rise( $longitude, $latitude, $alt, $day_offset );

Returns the sun rise time (resp. the sun set time) for the given location
and for today's date (as given by DateTime), plus or minus some offset in days.
The first form use all parameters and transmit them by name. The second form
uses today's date (from DateTime) and the default altitude.  The third
form adds specifying a custom altitude.  The fourth form allows for specifying
an integer day offset from today, either positive or negative.

The parameters are the same as the parameters for C<sunrise>. There is an additional
parameter, C<offset>, which allows using a date other than today: C<+1> for
to-morrow, C<-7> for one week ago, etc.

The arguments are:

=over 4

=item lon, lat

The longitude and latitude of the place for which you want to compute the sunrise and sunset.
They are given in decimal degrees. For example:

    lon => -3.6,  #  3° 36' W
    lat => 37.17, # 37° 10' N

 Eastern longitude is entered as a positive number
 Western longitude is entered as a negative number
 Northern latitude is entered as a positive number
 Southern latitude is entered as a negative number

Mandatory, can be positional (#1 and #2).

=item alt

Altitude of the sun, in decimal degrees. Usually a negative number,
because the sun should be I<under> the mathematical horizon.
But if there is a high mountain range sunward (that is, southward if you
live in the Northern hemisphere), you may need to enter a positive altitude.

This parameter is optional. Its default value is -0.833. It can be positional (#3).

=item offset

By default, C<sun_rise> and C<sun_set> use the current day. If you need another
day, you give an offset relative to the current day. For example, C<+7> means
next week, while C<-365> means last year.

This parameter has nothing to do with timezones.

Optional, 0 by default, can be positional (#4).

=item time_zone

Time Zone is the Olson name for a timezone. By default, the functions
C<sun_rise> and C<sun_set> will try to use the C<local> timezone.

This parameter is optional and it can be specified only by keyword.

=item upper_limb

If this parameter set to a true value (usually 1), the algorithm computes
the sun apparent radius and takes it into account when computing the sun
altitude. This parameter is useful only when the C<alt> parameter is set
to C<0> or C<-0.583> degrees. When using C<-0.25> or C<-0.833> degrees,
the sun radius is already taken into account. When computing twilights
(C<-6> to C<-18>), the sun radius is irrelevant.

Since the default value for the C<alt> parameter is -0.833, the
default value for C<upper_limb> is 0.

This parameter is optional and it can be specified only by keyword.

=item polar

When dealing with a polar location, there may be dates where there is
a polar night (sun never rises) or a polar day. The default behaviour of
the module is to emit a warning in these cases ("Sun never rises!!"
or "Sun never sets!!"). But some programmers may find this inconvenient.
An alternate behaviour is to return special values reflecting the
situation.

So, if the C<polar> parameter is set to C<'warn'>, the module emits
a warning. If the C<polar> parameter is set to C<'retval'>, the
module emits no warning, but it returns either C<'day'> or C<'night'>.

This parameter is optional and it can be specified only by keyword.

=item trace

This parameter should either be a false value or a filehandle opened for output.
In the latter case, a few messages are printed to the filehandle, which allows
the programmer to see step by step how the sunrise and the sunset are computed.

Used for analysis and debugging purposes.

This parameter is optional and it can be specified only by keyword.

=item precise

Choice between a precise algorithm and a simpler algorithm.
The default value is 0, that is, the simpler algorithm.
Any true value switches to the precise algorithm.

For more documentation, see the corresponding parameter
for the C<sunrise> function.

This parameter is optional and it can be specified only by keyword.

=back

=head3 For Example

 $sunrise = sun_rise( -105.181, 41.324 );
 $sunrise = sun_rise( -105.181, 41.324, -15 );
 $sunrise = sun_rise( -105.181, 41.324, -12, +3 );
 $sunrise = sun_rise( -105.181, 41.324, undef, -12);

=head2 Trigonometric functions using degrees

Since the module use trigonometry with degrees, the corresponding functions
are available to the module user, free of charge. Just mention the
tag C<:trig> in the C<use> statement. These functions are:

=over 4

=item sind, cosd, tand

The direct functions, that is, sine, cosine and tangent functions, respectively.
Each one receives one parameter, in degrees, and returns the trigonometric value.

=item asind, acosd, atand

The reverse functions, that is, arc-sine, arc-cosine, and arc-tangent.
Each one receives one parameter, the trigonometric value, and returns the corresponding
angle in degrees.

=item atan2d

Arc-tangent. This function receives two parameters: the numerator and the denominator
of a fraction equal to the tangent. Use this function instead of C<atand> when you
are not sure the denominator is not zero. E.g.:

  use Astro::Sunrise qw(:trig);
  say atan2d(1, 2) # prints 26,5
  say atan2d(1, 0) # prints 90, without triggering a "division by zero" error

=item equal

Not really a trigonometrical function, but still useful at some times. This function
receives two floating values and an integer value. It compares the floating numbers,
and returns "1" if their most significant digits are equal. The integer value
specifies how many digits are kept. E.g.

  say equal(22/7, 355/113, 3) # prints 1, because :  22/7   = 3.14285715286 rounded to 3.14
                              #                     355/113 = 3.14159292035 rounded to 3.14
  say equal(22/7, 355/113, 4) # prints 0, because :  22/7   = 3.14285715286 rounded to 3.143
                              #                     355/113 = 3.14159292035 rounded to 3.142

=back

=head1 EXPORTS

By default, the functions C<sunrise>, C<sun_rise> and C<sun_set> are exported.

The constants C<DEFAULT>, C<CIVIL>, C<NAUTICAL>, C<AMATEUR> and C<ASTRONOMICAL> are
exported on request with the tag C<:constants>.

The functions C<sind>, C<cosd>, C<tand>, C<asind>, C<acosd>, C<atand>, C<atan2d> and C<equal>
exported on request with the tag C<:trig>.

=head1 DEPENDENCIES

This module requires only core modules: L<POSIX>, L<Math::Trig> and L<Carp>.

If you use the C<sun_rise> and C<sun_set> functions, you will need also L<DateTime>.

=head1 AUTHOR

Ron Hill
rkhill@firstlight.net

Co-maintainer: Jean Forget (JFORGET at cpan dot org)

=head1 SPECIAL THANKS

Robert Creager [Astro-Sunrise@LogicalChaos.org]
for providing help with converting Paul's C code to Perl,
for providing code for sun_rise, sun_set subs.
Also adding options for different altitudes.

Joshua Hoblitt [jhoblitt@ifa.hawaii.edu]
for providing the patch to convert to DateTime.

Chris Phillips for providing patch for conversion to
local time.

Brian D Foy for providing patch for constants :)

Gabor Szabo for pointing POD mistakes.

People at L<https://geocoder.opencagedata.com/> for noticing an endless
loop condition and for fixing it.

=head1 CREDITS

=over 4

=item  Paul Schlyter, Stockholm, Sweden

for his excellent web page on the subject.

=item Rich Bowen (rbowen@rbowen.com)

for suggestions.

=item Adrian Blockley [adrian.blockley@environ.wa.gov.au]

for finding a bug in the conversion to local time.

=item Slaven Rezić

for finding and fixing a bug with DST.

=back

Lightly verified against L<http://aa.usno.navy.mil/data/docs/RS_OneYear.html>

In addition, checked to be compatible with a C implementation of Paul Schlyter's algorithm.

=head1 COPYRIGHT and LICENSE

=head2 Perl Module

This program is distributed under the same terms as Perl 5.16.3:
GNU Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., L<https://www.fsf.org/>.

=head2 Original C program

Here is the copyright information provided by Paul Schlyter:

Written as DAYLEN.C, 1989-08-16

Modified to SUNRISET.C, 1992-12-01

(c) Paul Schlyter, 1989, 1992

Released to the public domain by Paul Schlyter, December 1992

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 BUGS

Before reporting a bug, please read the text
F<doc/astronomical-notes.pod> because the strange behavior you observed
may be a correct one, or it may be a corner case already known and
already mentioned in the text.

Nevertheless, patches and (justified) bug reports are welcome.

See L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-Sunrise>.

=head2 Astro::Sunrise Bug

Ticket #109992 has not been solved properly. For some combinations
of longitude and date, the precise algorithm does not converge.
As a stopgap measure, the loop is exited after 10 iterations, so
your program will not run amok. But the bug will be considered as fixed
only when we find a way to converge toward a single value.

=head2 Kwalitee

The CPANTS tools do not recognize the LICENSE POD paragraph. But any
human reader will admit that this LICENSE paragraph exists and is valid.

=head2 Haiku-OS CPAN Tester

The built-in test F<t/06datetime.t> fails on Haiku-OS because there is no
way to extract the timezone name from the system parameters. This failure does
not affect the core functions of L<Astro::Sunrise>.

=head1 SEE ALSO

perl(1).

L<DateTime::Event::Sunrise>

L<DateTime::Event::Jewish::Sunrise>

The text F<doc/astronomical-notes.pod> (or its original French version
F<doc/notes-astronomiques>) in this distribution.

L<https://stjarnhimlen.se/comp/riset.html> 

=cut
