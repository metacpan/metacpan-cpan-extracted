# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl DateTime extension for computing the sunrise/sunset on a given day
#     Copyright (C) 1999-2004, 2013-2014 Ron Hill and Jean Forget
#
#     See the license in the embedded documentation below.
#
package DateTime::Event::Sunrise;

use strict;
use warnings;
require Exporter;
use POSIX qw(floor);
use Math::Trig;
use Carp;
use DateTime;
use DateTime::Set;
use Params::Validate qw(:all);
use Set::Infinite qw(inf $inf);
use vars qw( $VERSION $RADEG $DEGRAD @ISA );
@ISA     = qw( Exporter );
$VERSION = '0.0505';
$RADEG   = ( 180 / pi );
$DEGRAD  = ( pi / 180 );
my $INV360 = ( 1.0 / 360.0 );

# Julian day number for the 0th January 2000 (that is, 31st December 1999)
my $jd_2000_Jan_0 = DateTime->new(year => 1999, month => 12, day => 31, time_zone => 'UTC')->jd;


sub new {
    my $class = shift;

    if (@_ % 2 != 0) {
      croak "Odd number of parameters";
    }
    my %args = @_;
    if (exists $args{iteration} && exists $args{precise}) {
      croak "Parameter 'iteration' is deprecated, use only 'precise'";
    }

    %args = validate(
      @_, {
          longitude => { type => SCALAR, optional => 1, default => 0 },
          latitude  => { type => SCALAR, optional => 1, default => 0 },
          altitude  => {
              type    => SCALAR,
              default => '-0.833',
              regex   => qr/^(-?\d+(?:\.\d+)?)$/
          },
          iteration  => { type => SCALAR, default => '0' },
          precise    => { type => SCALAR, default => '0' },
          upper_limb => { type => SCALAR, default => '0' },
          silent     => { type => SCALAR, default => '0' },
      }
    );

    # Making old and new parameters synonymous
    unless (exists $args{precise}) {
      $args{precise} = $args{iteration};
    }
    # TODO : get rid of the old parameters after this point
    $args{iteration} = $args{precise};

    return bless \%args, $class;
}

    #
    #
    # FUNCTIONAL SEQUENCE for sunrise 
    #
    # _GIVEN
    # A sunrise object that was created by the new method
    #
    # _THEN
    #
    # setup subs for following/previous sunrise times  
    #   
    #
    # _RETURN
    #
    # A new DateTime::Set recurrence object 
    #
sub sunrise {

    my $class = shift;
    my $self  = $class->new(@_);
    return DateTime::Set->from_recurrence(
      next => sub {
          return $_[0] if $_[0]->is_infinite;
          $self->_following_sunrise( $_[0] );
      },
      previous => sub {
          return $_[0] if $_[0]->is_infinite;
          $self->_previous_sunrise( $_[0] );
      } );
}

    #
    #
    # FUNCTIONAL SEQUENCE for sunset  
    # 
    # _GIVEN
    # 
    # A sunrise object that was created by the new method
    # _THEN
    #
    # Setup subs for following/previous sunset times
    # 
    #
    # _RETURN
    #
    # A new DateTime::Set recurrence object
    #
sub sunset {

    my $class = shift;
    my $self  = $class->new(@_);
    return DateTime::Set->from_recurrence(
      next => sub {
          return $_[0] if $_[0]->is_infinite;
          $self->_following_sunset( $_[0] );
      },
      previous => sub {
          return $_[0] if $_[0]->is_infinite;
          $self->_previous_sunset( $_[0] );
      } );
}

    #
    #
    # FUNCTIONAL SEQUENCE for sunset_datetime
    #
    # _GIVEN
    # 
    # A sunrise object
    # A DateTime object
    # 
    # _THEN
    #
    #  Validate the DateTime object is valid  
    #  Compute sunrise and sunset  
    #      
    #
    # _RETURN
    #
    #  DateTime object that contains the sunset time
    #
sub sunset_datetime {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( undef, $tmp_set ) = _sunrise( $self, $dt );
    return $tmp_set;
}

    #
    #
    # FUNCTIONAL SEQUENCE for sunrise_datetime
    #
    # _GIVEN
    # 
    # A sunrise object
    # A DateTime object
    # 
    # _THEN
    #
    #  Validate the DateTime object is valid  
    #  Compute sunrise and sunset  
    #      
    #
    # _RETURN
    #
    #  DateTime object that contains the sunrise times
    #
sub sunrise_datetime {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( $tmp_rise, undef ) = _sunrise( $self, $dt );
    return $tmp_rise;
}

    #
    #
    # FUNCTIONAL SEQUENCE for sunrise_sunset_span
    #
    # _GIVEN
    # 
    # A sunrise object
    # A DateTime object
    # 
    # _THEN
    #
    #  Validate the DateTime object is valid  
    #  Compute sunrise and sunset  
    #      
    #
    # _RETURN
    #
    #  DateTime Span object that contains the sunrise/sunset times
    #
sub sunrise_sunset_span {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( $tmp_rise, $tmp_set ) = _sunrise( $self, $dt );

    return DateTime::Span->from_datetimes(
      start => $tmp_rise,
      end   => $tmp_set
    );
}

#
# FUNCTIONAL SEQUENCE for is_polar_night
#
# _GIVEN
# 
# A sunrise object
# A DateTime object
# 
# _THEN
#
#  Validate the DateTime object is valid  
#  Compute sunrise and sunset
#
# _RETURN
#
#  A boolean flag telling whether the sun will stay under the horizon or not
#
sub is_polar_night {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( undef, undef, $rise_season, $set_season ) = _sunrise( $self, $dt, 1 );
    return ($rise_season < 0 || $set_season < 0);
}

#
# FUNCTIONAL SEQUENCE for is_polar_day
#
# _GIVEN
# 
# A sunrise object
# A DateTime object
# 
# _THEN
#
#  Validate the DateTime object is valid  
#  Compute sunrise and sunset
#
# _RETURN
#
#  A boolean flag telling whether the sun will stay above the horizon or not
#
sub is_polar_day {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( undef, undef, $rise_season, $set_season ) = _sunrise( $self, $dt, 1 );
    return ($rise_season > 0 || $set_season > 0);
}

#
# FUNCTIONAL SEQUENCE for is_day_and_night
#
# _GIVEN
# 
# A sunrise object
# A DateTime object
# 
# _THEN
#
#  Validate the DateTime object is valid  
#  Compute sunrise and sunset
#
# _RETURN
#
#  A boolean flag telling whether the sun will rise and set or not
#
sub is_day_and_night {

    my $self  = shift;
    my $dt    = shift;
    my $class = ref($dt);

    if ( ! $dt->isa('DateTime') ) {
        croak("Dates need to be DateTime objects");
    }
    my ( undef, undef, $rise_season, $set_season ) = _sunrise( $self, $dt, 1 );
    return ($rise_season == 0 && $set_season == 0);
}

    #
    #
    # FUNCTIONAL SEQUENCE for _following_sunrise 
    #
    # _GIVEN
    # 
    # A sunrise object
    # A DateTime object
    # 
    # _THEN
    #
    #  Validate the DateTime object is valid  
    #  Compute sunrise and return if it is greater 
    #  than the original if not add one day and recompute
    #      
    #
    # _RETURN
    #
    #  A new DateTime object that contains the sunrise time
    #
sub _following_sunrise {

    my $self = shift;
    my $dt   = shift;
    croak( "Dates need to be DateTime objects (" . ref($dt) . ")" )
      unless ( $dt->isa('DateTime') );
    my ( $tmp_rise, undef ) = _sunrise( $self, $dt );
    return $tmp_rise if $tmp_rise > $dt;
    my $d = DateTime::Duration->new(
      days => 1,
    );
    my $new_dt = $dt + $d;
    ( $tmp_rise, undef ) = _sunrise( $self, $new_dt );
    return $tmp_rise if $tmp_rise > $dt;
    $new_dt = $new_dt + $d;
    ( $tmp_rise, undef ) = _sunrise( $self, $new_dt );
    return $tmp_rise;
}

    #
    #
    # FUNCTIONAL SEQUENCE for _previous_sunrise 
    #
    # _GIVEN
    # A sunrise object
    # A DateTime object
    #
    # _THEN
    #
    # Validate the DateTime Object
    # Compute sunrise and return if it is less than
    # the original object if not subtract one day and recompute
    #
    # _RETURN
    #
    # A new DateTime Object that contains the sunrise time 
    #
sub _previous_sunrise {

    my $self = shift;
    my $dt   = shift;
    croak( "Dates need to be DateTime objects (" . ref($dt) . ")" )
      unless ( $dt->isa('DateTime') );
    my ( $tmp_rise, undef ) = _sunrise( $self, $dt );
    return $tmp_rise if $tmp_rise < $dt;
    my $d = DateTime::Duration->new(
      days => 1,
    );
    my $new_dt = $dt - $d;
    ( $tmp_rise, undef ) = _sunrise( $self, $new_dt );
    return $tmp_rise if $tmp_rise < $dt;
    $new_dt = $new_dt - $d;
    ( $tmp_rise, undef ) = _sunrise( $self, $new_dt );
    return $tmp_rise;
}

    #
    #
    # FUNCTIONAL SEQUENCE for _following_sunset  
    #
    # _GIVEN
    # A sunrise object
    # A DateTime object
    #
    # _THEN
    #
    #  Validate the DateTime object is valid  
    #  Compute sunset and return if it is greater 
    #  than the original if not add one day and recompute
    #
    # _RETURN
    #
    #  A DateTime object with sunset time
    #
sub _following_sunset {

    my $self = shift;
    my $dt   = shift;
    croak( "Dates need to be DateTime objects (" . ref($dt) . ")" )
      unless ( ref($dt) eq 'DateTime' );
    my ( undef, $tmp_set ) = _sunrise( $self, $dt );
    return $tmp_set if $tmp_set > $dt;
    my $d = DateTime::Duration->new(
      days => 1,
    );
    my $new_dt = $dt + $d;
    ( undef, $tmp_set ) = _sunrise( $self, $new_dt );
    return $tmp_set if $tmp_set > $dt;
    $new_dt = $new_dt + $d;
    ( undef, $tmp_set ) = _sunrise( $self, $new_dt );
    return $tmp_set;
}

    #
    #
    # FUNCTIONAL SEQUENCE for _previous_sunset 
    #
    # _GIVEN
    #  A sunrise object
    #  A DateTime object
    #
    # _THEN
    #
    # Validate the DateTime Object
    # Compute sunset and return if it is less than
    # the original object if not subtract one day and recompute
    #  
    # _RETURN
    #
    # A DateTime object with sunset time 
    #
sub _previous_sunset {

    my $self = shift;
    my $dt   = shift;
    croak( "Dates need to be DateTime objects (" . ref($dt) . ")" )
      unless ( $dt->isa('DateTime') );
    my ( undef, $tmp_set ) = _sunrise( $self, $dt );
    return $tmp_set if $tmp_set < $dt;
    my $d = DateTime::Duration->new(
      days => 1,
    );
    my $new_dt = $dt - $d;
    ( undef, $tmp_set ) = _sunrise( $self, $new_dt );
    return $tmp_set if $tmp_set < $dt;
    $new_dt = $new_dt - $d;
    ( undef, $tmp_set ) = _sunrise( $self, $new_dt );
    return $tmp_set;
}

    #
    #
    # FUNCTIONAL SEQUENCE for _sunrise 
    #
    # _GIVEN
    #  A sunrise object and a DateTime object
    #
    # _THEN
    #
    # Check if precise is set to one if so
    # initially compute sunrise/sunset (using division
    # by 15.04107 instead of 15.0) then recompute rise/set time
    # using exact moment last computed. IF precise is set
    # to zero devide by 15.0 (only once)
    # 
    # Bug in this sub, I was blindly setting the hour and min without
    # checking if it was neg. a neg. value for hours/min is not correct
    # I changed the routine to use a duration then add the duration.
    #
    # _RETURN
    # 
    # two DateTime objects with the date and time for sunrise and sunset
    # two season flags for sunrise and sunset respectively
    #
sub _sunrise {

    my ($self, $dt, $silent) = @_;
    my $cloned_dt = $dt->clone;
    my $altit     = $self->{altitude};
    my $precise   = defined( $self->{precise} ) ? $self->{precise} : 0;
    unless (defined $silent) {
      $silent    = defined( $self->{silent}  ) ? $self->{silent}  : 0;
    }
    $cloned_dt->set_time_zone('floating');

    if ($precise) {

        # This is the initial start

        my $d = days_since_2000_Jan_0($cloned_dt) + 0.5 - $self->{longitude} / 360.0;
        my ($tmp_rise_1, $tmp_set_1, $rise_season) = _sunrise_sunset( $d, $self->{longitude}, $self->{latitude}, $altit,
                                                                     15.04107, $self->{upper_limb}, $silent);
        my $set_season = $rise_season;

        # Now we have the initial rise/set times next recompute d using the exact moment
        # recompute sunrise

        my $tmp_rise_2 = 9;
        my $tmp_rise_3 = 0;

        my $counter = 0;
        until ( equal( $tmp_rise_2, $tmp_rise_3, 8 ) ) {

            my $d_sunrise_1 = $d + $tmp_rise_1 / 24.0;
            ($tmp_rise_2, undef, undef) = _sunrise_sunset($d_sunrise_1, $self->{longitude}, $self->{latitude},
                                                          $altit, 15.04107, $self->{upper_limb}, $silent);
            $tmp_rise_1 = $tmp_rise_3;
            my $d_sunrise_2 = $d + $tmp_rise_2 / 24.0;
            ($tmp_rise_3, undef, $rise_season) = _sunrise_sunset($d_sunrise_2, $self->{longitude}, $self->{latitude},
                                                                 $altit, 15.04107, $self->{upper_limb}, $silent);
            last if ++$counter > 10;
        }

        my $tmp_set_2 = 9;
        my $tmp_set_3 = 0;

        $counter = 0;
        until ( equal( $tmp_set_2, $tmp_set_3, 8 ) ) {

            my $d_sunset_1 = $d + $tmp_set_1 / 24.0;
            (undef, $tmp_set_2, undef) = _sunrise_sunset( $d_sunset_1, $self->{longitude}, $self->{latitude},
                                                          $altit, 15.04107, $self->{upper_limb}, $silent);
            $tmp_set_1 = $tmp_set_3;
            my $d_sunset_2 = $d + $tmp_set_2 / 24.0;
            (undef, $tmp_set_3, $set_season) = _sunrise_sunset( $d_sunset_2, $self->{longitude}, $self->{latitude},
                                                                $altit, 15.04107, $self->{upper_limb}, $silent);
            last if ++$counter > 10;

        }

        my ( $second_rise, $second_set ) = convert_hour( $tmp_rise_3, $tmp_set_3 );

        # This is to fix the datetime object to use a duration
        # instead of blindly setting the hour/min
        my $rise_dur = DateTime::Duration->new( seconds => $second_rise );
        my $set_dur  = DateTime::Duration->new( seconds => $second_set );

        my $tmp_dt1 = DateTime->new(
          year      => $dt->year,
          month     => $dt->month,
          day       => $dt->day,
          hour      => 0,
          minute    => 0,
          time_zone => 'UTC'
        );

        my $rise_time = $tmp_dt1 + $rise_dur;
        my $set_time  = $tmp_dt1 + $set_dur;
        my $tz        = $dt->time_zone;
        $rise_time->set_time_zone($tz) unless $tz->is_floating;
        $set_time->set_time_zone($tz) unless $tz->is_floating;
        return ( $rise_time, $set_time, $rise_season, $set_season );
    }
    else {
        my $d = days_since_2000_Jan_0($cloned_dt) + 0.5 - $self->{longitude} / 360.0;
        my ( $h1, $h2, $season ) = _sunrise_sunset( $d, $self->{longitude}, $self->{latitude}, $altit, 15.0, $self->{upper_limb}, $silent);
        my ( $seconds_rise, $seconds_set ) = convert_hour( $h1, $h2 );
        my $rise_dur = DateTime::Duration->new( seconds => $seconds_rise );
        my $set_dur  = DateTime::Duration->new( seconds => $seconds_set );
        my $tmp_dt1  = DateTime->new(
          year      => $dt->year,
          month     => $dt->month,
          day       => $dt->day,
          hour      => 0,
          minute    => 0,
          time_zone => 'UTC'
        );

        my $rise_time = $tmp_dt1 + $rise_dur;
        my $set_time  = $tmp_dt1 + $set_dur;
        my $tz        = $dt->time_zone;
        $rise_time->set_time_zone($tz) unless $tz->is_floating;
        $set_time->set_time_zone($tz) unless $tz->is_floating;
        return ( $rise_time, $set_time, $season, $season );
    }

}

    #
    #
    # FUNCTIONAL SEQUENCE for _sunrise_sunset 
    #
    # _GIVEN
    # 
    #  days since Jan 0 2000, longitude, latitude, reference sun height $h and the "upper limb" and "silent" flags
    # _THEN
    #
    #  Compute the sunrise/sunset times for that day   
    #      
    # _RETURN
    #
    #  sunrise and sunset times as hours (GMT Time) 
    #  season flag: -1 for polar night, +1 for midnight sun, 0 for day and night
    #
sub _sunrise_sunset {

    my ( $d, $lon, $lat, $altit, $h, $upper_limb, $silent ) = @_;

    # Compute local sidereal time of this moment
    my $sidtime = revolution(GMST0($d) + 180.0 + $lon);

    # Compute Sun's RA + Decl + distance at this moment
    my ($sRA, $sdec, $sr) = sun_RA_dec($d);

    # Compute time when Sun is at south - in hours UT
    my $tsouth  = 12.0 - rev180( $sidtime - $sRA ) / $h;

    # Compute the Sun's apparent radius, degrees
    my $sradius = 0.2666 / $sr;

    # Do correction to upper limb, if necessary
    if ($upper_limb) {
        $altit -= $sradius;
    }

    # Compute the diurnal arc that the Sun traverses to reach 
    # the specified height altit:

    my $cost = (sind($altit) - sind($lat) * sind($sdec))
               / (cosd($lat) * cosd($sdec));

    my $t;
    my $season = 0;
    if ( $cost >= 1.0 ) {
        unless ($silent) {
          carp "Sun never rises!!\n";
        }
        $t = 0.0;    # Sun always below altit
        $season = -1;
    }
    elsif ( $cost <= -1.0 ) {
        unless ($silent) {
          carp "Sun never sets!!\n";
        }
        $t = 12.0;    # Sun always above altit
        $season = +1;
    }
    else {
        $t = acosd($cost) / 15.0;    # The diurnal arc, hours
    }

    # Store rise and set times - in hours UT 

    my $hour_rise_ut = $tsouth - $t;
    my $hour_set_ut  = $tsouth + $t;
    return ( $hour_rise_ut, $hour_set_ut, $season );

}

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
    # at 0h UT (i.e. the sidereal time at the Greenwhich meridian at  
    # 0h UT).  GMST is then the sidereal time at Greenwich at any     
    # time of the day.
    # 
    #
    # _RETURN
    #
    # Sidtime
    #
sub GMST0 {
    my ($d) = @_;
    my $sidtim0 = revolution( ( 180.0 + 356.0470 + 282.9404 ) + ( 0.9856002585 + 4.70935E-5 ) * $d );
    return $sidtim0;
}

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
    my $Eccentric_anomaly = $Mean_anomaly_of_sun
                            + $Eccentricity_of_Earth_orbit * $RADEG
                              * sind($Mean_anomaly_of_sun)
                              * ( 1.0 + $Eccentricity_of_Earth_orbit * cosd($Mean_anomaly_of_sun) );

    my $x = cosd($Eccentric_anomaly) - $Eccentricity_of_Earth_orbit;

    my $y = sqrt( 1.0 - $Eccentricity_of_Earth_orbit * $Eccentricity_of_Earth_orbit )
            * sind($Eccentric_anomaly);

    my $Solar_distance = sqrt( $x * $x + $y * $y );    # Solar distance
    my $True_anomaly = atan2d( $y, $x );               # True anomaly

    my $True_solar_longitude =
      $True_anomaly + $Mean_longitude_of_perihelion;    # True solar longitude

    if ( $True_solar_longitude >= 360.0 ) {
        $True_solar_longitude -= 360.0;    # Make it 0..360 degrees
    }

    return ( $Solar_distance, $True_solar_longitude );
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

    my ($d) = @_;

    # Compute Sun's ecliptical coordinates 
    my ( $r, $lon ) = sunpos($d);

    # Compute ecliptic rectangular coordinates (z=0) 
    my $x = $r * cosd($lon);
    my $y = $r * sind($lon);

    # Compute obliquity of ecliptic (inclination of Earth's axis) 
    my $obl_ecl = 23.4393 - 3.563E-7 * $d;

    # Convert to equatorial rectangular coordinates - x is unchanged 
    my $z = $y * sind($obl_ecl);
    $y = $y * cosd($obl_ecl);

    # Convert to spherical coordinates 
    my $RA  = atan2d( $y, $x );
    my $dec = atan2d( $z, sqrt( $x * $x + $y * $y ) );

    return ( $RA, $dec, $r );

}    # sun_RA_dec

    #
    #
    # FUNCTIONAL SEQUENCE for days_since_2000_Jan_0 
    #
    # _GIVEN
    # A Datetime object
    #
    # _THEN
    #
    # process the DateTime object for number of days
    # since Jan,1 2000  (counted in days)
    # Day 0.0 is at Jan 1 2000 0.0 UT
    #
    # _RETURN
    #
    # day number
    #
sub days_since_2000_Jan_0 {
    my ($dt) = @_;
    return int($dt->jd - $jd_2000_Jan_0);
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
    # any angle in degrees
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
    # any angle in degrees
    #
    # _THEN
    #
    # Reduce input to within +180..+180 degrees
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

    #
    #
    # FUNCTIONAL SEQUENCE for equal
    #
    # _GIVEN
    # 
    # Two floating point numbers and Accuracy
    #
    # _THEN
    #
    # Use sprintf to format the numbers to Accuracy
    # number of decimal places
    #
    # _RETURN
    #
    # True if the numbers are equal 
    #
sub equal {

    my ( $A, $B, $dp ) = @_;

    return sprintf( "%.${dp}g", $A ) eq sprintf( "%.${dp}g", $B );
}

    #
    #
    # FUNCTIONAL SEQUENCE for convert_hour 
    #
    # _GIVEN
    # Hour_rise, Hour_set 
    # hours are in UT
    #
    # _THEN
    #
    # split out the hours and minutes
    # Oct 20 2003
    # will convert hours to seconds and return this
    # let DateTime handle the conversion
    #
    # _RETURN
    #
    # number of seconds
sub convert_hour {

    my ( $hour_rise_ut, $hour_set_ut ) = @_;
    my $seconds_rise = floor( $hour_rise_ut * 60 * 60 );
    my $seconds_set  = floor( $hour_set_ut * 60 * 60 );

    return ( $seconds_rise, $seconds_set );
}

1962; # Hint: sung by RZ, better known as BD

=encoding utf8

=head1 NAME

DateTime::Event::Sunrise - Perl DateTime extension for computing the sunrise/sunset on a given day

=head1 SYNOPSIS

  use DateTime;
  use DateTime::Event::Sunrise;

  # generating DateTime objects from a DateTime::Event::Sunrise object
  my $sun_Kyiv = DateTime::Event::Sunrise->new(longitude => +30.85,  # 30°51'E
                                               latitude  => +50.45); # 50°27'N
  for (12, 13, 14) {
    my $dt_yapc_eu = DateTime->new(year      => 2013,
                                   month     =>    8,
                                   day       =>   $_,
                                   time_zone => 'Europe/Kiev');
    say "In Kyiv (50°27'N, 30°51'E) on ", $dt_yapc_eu->ymd, " sunrise occurs at ", $sun_Kyiv->sunrise_datetime($dt_yapc_eu)->hms,
                                                         " and sunset occurs at ", $sun_Kyiv->sunset_datetime ($dt_yapc_eu)->hms;
  }

  # generating DateTime objects from DateTime::Set objects
  my $sunrise_Austin = DateTime::Event::Sunrise->sunrise(longitude => -94.73,  # 97°44'W
                                                         latitude  => +30.3);  # 30°18'N
  my $sunset_Austin  = DateTime::Event::Sunrise->sunset (longitude => -94.73,
                                                         latitude  => +30.3);
  my $dt_yapc_na_rise = DateTime->new(year      => 2013,
                                      month     =>    6,
                                      day       =>    3,
                                      time_zone => 'America/Chicago');
  my $dt_yapc_na_set = $dt_yapc_na_rise->clone;
  say "In Austin (30°18'N, 97°44'W), sunrises and sunsets are";
  for (1..3) {
    $dt_yapc_na_rise = $sunrise_Austin->next($dt_yapc_na_rise);
    $dt_yapc_na_set  = $sunset_Austin ->next($dt_yapc_na_set);
    say $dt_yapc_na_rise, ' ', $dt_yapc_na_set;
  }

  # If you deal with a polar location
  my $sun_in_Halley = DateTime::Event::Sunrise->new(
                                 longitude => -26.65, # 26°39'W
                                 latitude  => -75.58, # 75°35'S
                                 precise   => 1,
                                 );
  my $Alex_arrival = DateTime->new(year  => 2006, # approximate date, not necessarily the exact one
                                   month =>    1,
                                   day   =>   15,
                                   time_zone => 'Antarctica/Rothera');
  say $Alex_arrival->strftime("Alex Gough (a Perl programmer) arrived at Halley Base on %Y-%m-%d.");
  if ($sun_in_Halley->is_polar_day($Alex_arrival)) {
    say "It would be days, maybe weeks, before the sun would set.";
  }
  elsif ($sun_in_Halley->is_polar_night($Alex_arrival)) {
    say "It would be days, maybe weeks, before the sun would rise.";
  }
  else {
    my $sunset = $sun_in_Halley->sunset_datetime($Alex_arrival);
    say $sunset->strftime("And he saw his first antarctic sunset at %H:%M:%S.");
  }

=head1 DESCRIPTION

This module will computes the time of sunrise and sunset for a given date
and a given location. The computation uses Paul Schlyter's algorithm.

Actually, the module creates a DateTime::Event::Sunrise object or a
DateTime::Set object, which are used to generate the sunrise or the sunset
times for a given location and for any date.

=head1 METHODS

=head2 new

This is the DateTime::Event::Sunrise constructor. It takes keyword
parameters, which are:

=over 4

=item longitude

This is the longitude of the location where the sunrises and sunsets are observed.
It is given as decimal degrees: no minutes, no seconds, but tenths and hundredths of degrees.
Another break with the normal usage is that Eastern longitude are positive, Western longitudes
are negative.

Default value is 0, that is Greenwich or any location on the eponymous meridian.

=item latitude

This is the latitude of the location where the sunrises and sunsets are observed.
As for the longitude, it is given as decimal degrees. Northern latitudes are positive
numbers, Southern latitudes are negative numbers.

Default value is 0, that is any location on the equator.

=item altitude

This is the height of the Sun at sunrise or sunset. In astronomical context, the altitude or
height is the angle between the Sun and the local horizon. It is expressed as degrees, usually
with a negative number, since the Sun is I<below> the horizon.

Default value is -0.833, that is when the sun's upper limb touches the horizon, while
taking in account the light refraction.

Positive altitude are allowed, in case the location is near a mountain range
behind which the sun rises or sets.

=item precise

Boolean to control which algorithm is used. A false value gives a simple algorithm, but
which can lead to inaccurate sunrise times and sunset times. A true value gives
a more elaborate algorithm, with a loop to refine the sunrise and sunset times
and obtain a better precision.

Default value is 0, to choose the simple algorithm.

This parameter replaces the C<iteration> deprecated parameter.

=item upper_limb

Boolean to choose between checking the Sun's upper limb or its center.
A true value selects the upper limb, a false value selects the center.

This parameter is significant only when the altitude does not already deal with the sun radius.
When the altitude takes into account the sun radius, this parameter should be false.

Default value is 0, since the upper limb correction is already
taken in account with the default -0.833 altitude.

=item silent

Boolean to control the output of some warning messages.
With polar locations and dates near the winter solstice or the summer solstice,
it may happen that the sun never rises above the horizon or never sets below.
If this parameter is set to false, the module will send warnings for these
conditions. If this parameter is set to true, the module will not pollute
your F<STDERR> stream.

Default value is 0, for backward compatibility.

=back

=head2 sunrise, sunset

Although they come from the DateTime::Event::Sunrise module, these methods
are C<DateTime::Set> constructors. They use the same parameters as the C<new>
constructor, but they give objects from a different class.

=head2 sunrise_datetime, sunset_datetime

These two methods apply to C<DateTime::Event::Sunrise> objects (that is, created
with C<new>, not C<sunrise> or C<sunset>). They receive one parameter in addition
to C<$self>, a C<DateTime> object. They return another C<DateTime> object,
for the same day, but with the time of the sunrise or sunset, respectively.

=head2 sunrise_sunset_span

This method applies to C<DateTime::Event::Sunrise> objects. It accepts a 
C<DateTime> object as the second parameter. It returns a C<DateTime::Span>
object, beginning at sunrise and ending at sunset.

=head2 is_polar_night, is_polar_day, is_day_and_night

These methods apply to C<DateTime::Event::Sunrise> objects. They accept a 
C<DateTime> object as the second parameter. They return a boolean indicating
the following condutions:

=over 4

=item * is_polar_night is true when the sun stays under the horizon. Or rather
under the altitude parameter used when the C<DateTime::Event::Sunrise> object was created.

=item * is_polar_day is true when the sun stays above the horizon,
resulting in a "Midnight sun". Or rather when it stays above the
altitude parameter used when the C<DateTime::Event::Sunrise> object was created.

=item * is_day_and_night is true when neither is_polar_day, nor is_polar_night
are true.

=back

=head2 next current previous contains as_list iterator

See DateTime::Set.

=head1 EXTENDED EXAMPLES

  my $dt = DateTime->new( year   => 2000,
                         month  => 6,
                         day    => 20,
                  );

  my $sunrise = DateTime::Event::Sunrise ->sunrise (
                        longitude =>'-118',
                        latitude =>'33',
                        altitude => '-0.833',
                        precise   => '1'
                  );

  my $sunset = DateTime::Event::Sunrise ->sunset (
                        longitude =>'-118',
                        latitude =>'33',
                        altitude => '-0.833',
                        precise   => '1'
                  );

  my $tmp_rise = $sunrise->next( $dt ); 
 
  my $dt2 = DateTime->new( year   => 2000,
                         month  => 12,
                         day    => 31,
                   );
 
  # iterator
  my $dt_span = DateTime::Span->new( start =>$dt, end=>$dt2 );
  my $set = $sunrise->intersection($dt_span);
  my $iter = $set->iterator;
  while ( my $dt = $iter->next ) {
    print ' ',$dt->datetime;
  }

  # is it day or night?
  my $day_set = DateTime::SpanSet->from_sets( 
    start_set => $sunrise, end_set => $sunset );
  print $day_set->contains( $dt ) ? 'day' : 'night';

  my $dt = DateTime->new( year   => 2000,
		   month  => 6,
		   day    => 20,
		   time_zone => 'America/Los_Angeles',
		    );

  my $sunrise = DateTime::Event::Sunrise ->new(
		       longitude =>'-118' ,
		       latitude  => '33',
		       altitude  => '-0.833',
		       precise   => '1'

  );

  my $tmp = $sunrise->sunrise_sunset_span($dt);
  print "Sunrise is:" , $tmp->start->datetime , "\n";
  print "Sunset is:" , $tmp->end->datetime;

=head1 NOTES

=head2 Longitude Signs

Remember, contrary to the usual convention,

EASTERN longitudes are POSITIVE,

WESTERN longitudes are NEGATIVE.

On the other hand, the latitude signs follow the usual convention:

Northen latitudes are positive,

Southern latitudes are negative.
 
=head2 Sun Height

There are a number of sun heights to choose from. The default is
-0.833 because this is what most countries use. Feel free to
specify it if you need to. Here is the list of values to specify
the sun height with:

=over 4

=item * B<0> degrees

Center of Sun's disk touches a mathematical horizon

=item * B<-0.25> degrees

Sun's upper limb touches a mathematical horizon

=item * B<-0.583> degrees

Center of Sun's disk touches the horizon; atmospheric refraction accounted for

=item * B<-0.833> degrees

Sun's supper limb touches the horizon; atmospheric refraction accounted for

=item * B<-6> degrees

Civil twilight (one can no longer read outside without artificial illumination)

=item * B<-12> degrees

Nautical twilight (navigation using a sea horizon no longer possible)

=item * B<-15> degrees

Amateur astronomical twilight (the sky is dark enough for most astronomical observations)

=item * B<-18> degrees

Astronomical twilight (the sky is completely dark)

=back

=head2 Notes on the Precise Algorithm

The original method only gives an approximate value of the Sun's rise/set times. 
The error rarely exceeds one or two minutes, but at high latitudes, when the Midnight Sun 
soon will start or just has ended, the errors may be much larger. If you want higher accuracy, 
you must then select the precise variant of the algorithm. This feature is new as of version 0.7. Here is
what I have tried to accomplish with this.


=over 4

=item a)

Compute sunrise or sunset as always, with one exception: to convert LHA from degrees to hours,
divide by 15.04107 instead of 15.0 (this accounts for the difference between the solar day 
and the sidereal day.

=item b)

Re-do the computation but compute the Sun's RA and Decl, and also GMST0, for the moment 
of sunrise or sunset last computed.

=item c)

Iterate b) until the computed sunrise or sunset no longer changes significantly. 
Usually 2 iterations are enough, in rare cases 3 or 4 iterations may be needed.

=back

=head2 Notes on polar locations

If the location is beyond either polar circle, and if the date is 
near either solstice, there can be midnight sun or polar night.
In this case, there is neither sunrise nor sunset, and
the module C<carp>s that the sun never rises or never sets.
Then, it returns the time at which the sun is at its highest
or lowest point.

=head1 DEPENDENCIES

This module requires:

=over 4

=item *

DateTime

=item *

DateTime::Set

=item *

DateTime::Span

=item *

Params::Validate

=item *

Set::Infinite

=item *

POSIX

=item *

Math::Trig

=back

=head1 BUGS AND CAVEATS

Using a latitude of 90 degrees (North Pole or South Pole) gives curious results.
I guess that it is linked with a ambiguous value resulting from a 0/0 computation.

Using a longitude of 177 degrees, or any longitude near the 180 meridian, may also give
curious results, especially with the precise algorithm.

The precise algorithm should be overhauled.

=head1 AUTHORS

Original author: Ron Hill <rkhill@firstlight.net>

Co-maintainer: Jean Forget <JFORGET@cpan.org>

=head1 SPECIAL THANKS

=over 4

=item Robert Creager [Astro-Sunrise@LogicalChaos.org]

for providing help with converting Paul's C code to perl.

=item Flávio S. Glock [fglock@pucrs.br]

for providing the the interface to the DateTime::Set
module.

=back

=head1 CREDITS

=over 4

=item Paul Schlyter, Stockholm, Sweden 

for his excellent web page on the subject.

=item Rich Bowen (rbowen@rbowen.com)

for suggestions.

=item People at L<http://geocoder.opencagedata.com/>

for noticing an endless loop condition in L<Astro::Sunrise> and for fixing it.

=back

=head1 COPYRIGHT and LICENSE

=head2 Perl Module

This program is distributed under the same terms as Perl 5.16.3:
GNU Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<http://www.perlfoundation.org/artistic_license_1_0>
and L<http://www.gnu.org/licenses/gpl-1.0.html>.

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
Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

=head2 Original C program

Here is the copyright information provided by Paul Schlyter
for the original C program:

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

=head1 SEE ALSO

perl(1).

DateTime Web page at http://datetime.perl.org/

DateTime::Set

DateTime::SpanSet

Astro::Sunrise

DateTime::Event::Jewish::Sunrise

Paul Schlyter's homepage at http://stjarnhimlen.se/english.html

=cut

