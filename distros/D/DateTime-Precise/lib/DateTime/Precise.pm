# DateTime::Precise              -*- Perl -*-
#
# This code is a heavily modified version of Greg Fast's
# (gdfast@usgs.gov) DateTime.pm package.  This version includes
# subsecond precision on all calculations and a whole bunch of
# additional method calls.
#
# Latest author: Blair Zajac (blair@orcaware.com).
# Original author: Greg Fast (gdfast@usgs.gov).

package DateTime::Precise;

require 5.004_04;
use strict;
use Carp qw(carp cluck croak confess);
use Exporter;
require 'DateTime/Math/bigfloat.pl';

# Try to load the Time::HiRes module to get the high resolution
# version of time.
BEGIN {
  eval {
    my $module  =  'Time::HiRes';
    my $package =  "$module.pm";
    $package    =~ s#::#/#g;
    require $package;
    import $module qw(time);
  };
}

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS
            $AUTOLOAD
            $VERSION
            $TZ @LC_AMPM
            %SET_MASK %SET_START_VALUE %SET_MULTIPLER_VALUE
            $USGSMidnight
            $is_internal_format_re
            @MonthDays @MonthName @MonthAbbrev @WeekName @WeekAbbrev
            %_month_name
            $Days_per_5_months $Days_per_4_years $Days_per_400_years);

# Definitions for overloaded operators:
# Overloaded operators: +/-, <=>, cmp, stringify.
# Addition handles seconds, subtraction handles secs or date
# differences.  Comparisons also work.
use overload
  'neg' => sub { cluck "neg is an invalid operator for " . ref($_[0]); $_[0] },
  '""'  => 'stringify',
  '+'   => 'ovld_add',
  '-'   => sub { $_[2] ? &ovld_sub($_[1],$_[0]) : &ovld_sub; },
  '<=>' => sub { $_[2] ? DateTime::Math::fcmp("$_[1]","$_[0]") :
                 DateTime::Math::fcmp("$_[0]","$_[1]") },
  'cmp' => sub { $_[2] ? ("$_[1]" cmp "$_[0]") : ("$_[0]" cmp "$_[1]") };

$VERSION   = sprintf '%d.%02d', '$Revision: 1.05 $' =~ /(\d+)\.(\d+)/;
@ISA       = qw(Exporter);
@EXPORT_OK = qw($USGSMidnight
                @MonthDays @MonthName @MonthAbbrev @WeekName @WeekAbbrev
                &Secs_per_week &Secs_per_day &Secs_per_hour &Secs_per_minute
                &JANUARY_1_1970 &JANUARY_6_1980
                &IsLeapYear &DaysInMonth);
%EXPORT_TAGS = (TimeVars => [qw(@MonthDays @MonthName @MonthAbbrev
                                @WeekName @WeekAbbrev
                                &Secs_per_week &Secs_per_day
                                &Secs_per_hour &Secs_per_minute
                                &JANUARY_1_1970 &JANUARY_6_1980)] );

#
# Global, internal variables.
#

# This is the regular expression to test if a string represents an
# internal representation of the time.
$is_internal_format_re = '^\d{14}(\.\d*)?$';

# USGS, god knows why, likes midnight to be 24:00:00, not 00:00:00.
# If $USGSMidnight is set to 1, dprintf will always print midnight as
# 24:00:00.  Time is always stored internally as real midnight.
$USGSMidnight = 0;

# @MonthDays:   days per month, 1-indexed (0=dec, 13=jan).
# @MonthName:   Names of months, one-indexed.
# @MonthAbbrev: 3-letter abbrevs of months.  one-indexed.
# @WeekName:    Names of days of the week.  zero-indexed.
# @WeekAbbrev:  3-letter abbrevs.  zero-indexed.
@MonthDays   = (31,31,28,31,30,31,30,31,31,30,31,30,31,31);
@MonthName   = ('December','January','February','March','April','May','June','July','August','September','October','November','December','January');
@MonthAbbrev = ('Dec','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan');
@WeekName    = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
@WeekAbbrev  = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');

# SDN is serial day number (the SDN conversion code isn't mine).
# SDN_Offset: deep magic from the dawn of time.
# Days_per_5_months: number of days in a five month block (mar-jul)
# Days_per_4_years: number of days in a leap year cycle
# Days_per_400_years: number of days in a *real* leap year cycle
sub SDN_Offset         () {  32045; }
sub Days_per_5_months  () {    153; }
sub Days_per_4_years   () {   1461; }
sub Days_per_400_years () { 146097; }

# Secs_per_week: number of seconds in one week (7 days)
# Secs_per_day: number of seconds in one day (24 hours)
# Secs_per_hour: number of seconds in one hour
# Secs_per_minute: number of seconds in one minute
sub Secs_per_week   () { 604800; }
sub Secs_per_day    () {  86400; }
sub Secs_per_hour   () {   3600; }
sub Secs_per_minute () {     60; }

# There's no portable way to find the system default timezone, so
# set it to GMT.
$TZ = 'GMT';
# These are locales specific variables.  Change these to suit your
# local format.
@LC_AMPM  = ('AM', 'PM');
# This time represents Unix time 0 of January 1, 1970 UTC.
sub JANUARY_1_1970 () { DateTime::Precise->new('1970.01.01 00:00:00'); }
# This time represents GPS time 0 of January 6, 1980.
sub JANUARY_6_1980 () { DateTime::Precise->new('1980.01.06 00:00:00'); }
# Modified Julian Day #0 is 40587 days after January 1, 1970 UTC.
sub MODIFIED_JULIAN_DAY () { 40587; }

# These constants are used in the internal representation of the date
# and time, which is a reference to an array.  These constants are
# indices into the appropriate location in the array to get the
# particular portion of the date/time.
sub YEAR     () { 0; }
sub MONTH    () { 1; }
sub DAY      () { 2; }
sub HOUR     () { 3; }
sub MINUTE   () { 4; }
sub SECOND   () { 5; }
sub FRACTION () { 6; }

# %_unit_name: translate function names to component indices.
my %_unit_name = (second	=> SECOND,
                  sec		=> SECOND,
                  minute	=> MINUTE,
                  min		=> MINUTE,
                  hour		=> HOUR,
                  day		=> DAY,
                  month		=> MONTH,
                  mo		=> MONTH,
                  year		=> YEAR);

# %_unit_name: which function names to allow (see AUTOLOADER).
my %_func_name = ('inc'=>1, 'dec'=>1, 'floor'=>1, 'ceil'=>1, 'round'=>1);

# @_half_unit: when to round up.
my @_half_unit = (0, 6, 15, 12, 30, 30, 0.5);

# @_full_unit: full size of unit.
my @_full_unit = map(2*$_, @_half_unit);

my %_month_name;
foreach (1..12) {
    $_month_name{lc $MonthName[$_]}   = $_;
    $_month_name{lc $MonthAbbrev[$_]} = $_;
}

# These variables are used for setting the time using the set_time and
# new methods.  Time is set using a template of key letters and an
# array containing any needed arguments for each key.  Each letter
# represents a different method of setting the time.  Associated with
# each key is a mask storred in %SET_MASK that identifies the
# propterties of the key.  The keys are bitwise ANDed between four
# keys, MASK_ABSOLUTE, MASK_NO_ARG, MASK_FRACTIONAL_ARG, and
# MASK_MULTIPLIER_ARG.  Key letters that set the time to an absolute
# value are marked with the MASK_ABSOLUTE flag.  If the key does not
# have MASK__ABSOLUTE, then the time is set relative to the current
# time value.  If the key does not use a argument, then MASK_NO_ARG is
# set.  If non-integer arguments to the keys are allowed, then the
# MASK_FRACTIONAL_ARG is set.  Finally, if the key needs a multipler
# value to convert the argument into seconds, then MASK_MULTIPLIER_ARG
# is set.
sub MASK_ABSOLUTE        () { 1; }
sub MASK_NO_ARG          () { 2; }
sub MASK_USES_PARTIAL    () { 4; }
sub MASK_USES_MULTIPLIER () { 8; }

# Define combinations of these flags.
%SET_MASK = (
	     # set time to now
	     'N' => MASK_ABSOLUTE | MASK_NO_ARG,
	     # set time to GPS time 0
	     'G' => MASK_ABSOLUTE | MASK_NO_ARG,
	     # set to beginning on year
	     'Y' => MASK_ABSOLUTE | MASK_USES_PARTIAL,
	     # set to modfied Julian date
	     'J' => MASK_ABSOLUTE | MASK_USES_PARTIAL,
	     # set to seconds since January 1, 1970 UTC
	     's' => MASK_ABSOLUTE | MASK_USES_PARTIAL,
	     # add month of year
	     'B' => MASK_USES_PARTIAL,
	     # add number of weeks
	     'W' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
	     # add number of days from 1
	     'D' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
	     # add number of days from 0
	     'd' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
	     # add hours
	     'H' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
	     # add minutes
	     'M' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
	     # add seconds
	     'S' => MASK_USES_PARTIAL | MASK_USES_MULTIPLIER,
);

# These define the starting values for the different keys in SET_MASK.
%SET_START_VALUE = ('s' => 0,
                    'W' => 0,
                    'D' => 1,
                    'd' => 0,
                    'H' => 0,
                    'M' => 0,
                    'S' => 0);

# These are the multipler from the key into seconds.
%SET_MULTIPLER_VALUE = ('s' => 1,
                        'W' => Secs_per_week,
                        'D' => Secs_per_day,
                        'd' => Secs_per_day,
                        'H' => Secs_per_hour,
                        'M' => Secs_per_minute,
                        'S' => 1);

#----------------------------------------
# ARG1 $year: year
# RETVAL: true/false
# EXAMPLE: print "Yes!" if DateTime::Precise::IsLeapYear(2000);
# ACCESS: public nonmethod
sub IsLeapYear {
  my $year = int($_[0]);
  ((($year%4) == 0) && ((($year%100) != 0) || (($year%400) == 0)));
}
# IsLeapYear

#----------------------------------------
# ARG1 $month: month in question
# ARG2 $year: year, for figuring leap years if it's feb.
# RETVAL: number of days in month
# ACCESS: public nonmethod
sub DaysInMonth {
  my $month = shift;
  my $year  = shift;
  $MonthDays[$month] + ($month==2 && IsLeapYear($year));
}
# DaysInMonth


#
# Internal helper functions.
#

#----------------------------------------
# NOTES: fix to 24:00:00 midnight.
# RETVAL: 1 if the date was modified, 0 otherwise
# ACCESS: method
sub USGSDumbMidnightFix {
  my $self = shift;
  my $modified_date = 0;
  $self->_FixDate;
  if ($self->[FRACTION] == 0 && $self->[SECOND] == 0 &&
      $self->[MINUTE]   == 0 && $self->[HOUR]   == 0) {
    $modified_date = 1;
    $self->[HOUR] = '24';
    $self->[DAY]--;
    if ($self->[DAY] < 1) {
      $self->[MONTH]--;
      $self->[DAY] = DaysInMonth($self->[MONTH], $self->[YEAR]);
      if ($self->[MONTH] < 1) {
	$self->[MONTH] = 12;
	$self->[YEAR]--;
      }
    }
  }
  $modified_date;
}
# USGSDumbMidnightFix

#----------------------------------------
# NOTES: Check date for validity.
# NOTES: 24:00:00 is ok, but will be changed internally to 00:00:00.
# ARG1 @a: component array to check for real-ness
# RETVAL: true/false
# ACCESS: private nonmethod
sub IsOkDate {
  ($_[MONTH]    >= 1 && $_[MONTH]    <= 12 &&
   $_[DAY]      >= 1 && $_[DAY]      <= DaysInMonth($_[MONTH], $_[YEAR]) &&
   $_[HOUR]     >= 0 && $_[HOUR]     <= 24 &&
   $_[MINUTE]   >= 0 && $_[MINUTE]   <= 59 &&
   $_[SECOND]   >= 0 && $_[SECOND]   <= 59 &&
   $_[FRACTION] >= 0 && $_[FRACTION] <   1);
}
# IsOkDate

#----------------------------------------
# NOTES: Fix overshoots or undershoots in component increments.
# ARG1 @a: component array
# RETVAL: component array
# ACCESS: private method
sub _FixDate {
  my $self = shift;
  # Fix fractions of seconds.
  if ($self->[FRACTION] < 0 ||
      $self->[FRACTION] >= 1 ||
      (int($self->[SECOND]) != $self->[SECOND])) {
    # Get the integer and fractional part of the seconds.  Add the
    # integer part to the seconds field.  Keep the remaining
    # fractional seconds in the fractional seconds field.  Remember
    # the standard accuracy for the fraction.
    my $total    = DateTime::Math::fadd(@$self[SECOND, FRACTION]);
    my $second   = int($total);
    my $fraction = 0 + DateTime::Math::fsub($total, $second);
    # Handle when the fractional seconds are negative.  Sometimes when
    # very small negative fractional numbers are added by 1 the number
    # becomes 1.  In this case, subtract by 1 again.
    if ($fraction < 0) {
      --$second;
      ++$fraction;
    }
    if ($fraction >= 1) {
      ++$second;
      --$fraction;
    }
    $self->[SECOND]   = $second;
    $self->[FRACTION] = $fraction;
  }

  # Fix seconds.
  while ($self->[SECOND] > 59) {
    $self->[SECOND] -= 60;
    $self->[MINUTE]++;
  }
  while ($self->[SECOND] < 0) {
    $self->[SECOND] += 60;
    $self->[MINUTE]--;
  }

  # Fix minutes.
  while ($self->[MINUTE] > 59) {
    $self->[MINUTE] -= 60;
    $self->[HOUR]++;
  }
  while ($self->[MINUTE] < 0) {
    $self->[MINUTE] += 60;
    $self->[HOUR]--;
  }

  # Fix hours.
  while ($self->[HOUR] > 23) {
    $self->[HOUR] -= 24;
    $self->[DAY]++;
  }
  while ($self->[HOUR] < 0) {
    $self->[HOUR] += 24;
    $self->[DAY]--;
  }

  # Fixing the days and months is a little complicated.  Because the
  # number of days in the month is not constant and we're using a
  # function to calculate the number of days in the month, be careful.
  # Go into a loop, fix the month first, then fix the days.  If
  # anything gets fixed, redo the loop.
    FIX_DAY_MONTH:
  {
    # Fix months.
    while ($self->[MONTH] > 12) {
      $self->[MONTH] -= 12;
      $self->[YEAR]++;
    }
    while ($self->[MONTH] < 1) {
      $self->[MONTH] += 12;
      $self->[YEAR]--;
    }

    # Fix days.
    if ($self->[DAY] > DaysInMonth($self->[MONTH], $self->[YEAR])) {
      $self->[DAY] -= DaysInMonth($self->[MONTH], $self->[YEAR]);
      $self->[MONTH]++;
      redo FIX_DAY_MONTH;
    }
    if ($self->[DAY] < 1) {
      $self->[MONTH]--;
      $self->[DAY] += DaysInMonth($self->[MONTH], $self->[YEAR]);
      redo FIX_DAY_MONTH;
    }
  }
  $self;
}
# _FixDate

# Parse the internal string of the form yyyymmddhmmss.fff.
sub InternalStringToInternal {
  my $in = shift;
  my @a = unpack('a4a2a2a2a2a2a*', $in);
  $a[6] = 0 unless $a[6];
  if (IsOkDate(@a)) {
    return @a;
  } else {
    return
  }
}

#----------------------------------------
# NOTES: Convert a datetime string to the components of an array.
# ARG1 $in: datetime string ("19YY.MM.DD hh:mm:ss.sss")
# RETVAL: Return an array cleaned and validified or an empty list
# RETVAL: in a list context, an undefined value in a scalar context,
# RETVAL: or nothing in a void context if the datetime string does
# RETVAL: not pass muster.
# ACCESS: private nonmethod
sub DatetimeToInternal {
  my $in = shift;

  # Restructure date time into a consistent fixed width format
  # suitable for easy parsing.  Need to handle formats like:
  # 1974.11.02
  # 1974/11/02
  # 1974.11.02 12:33:44.538
  # 19741102123344.538
  # yyyymmddhhmmss.fff

  # The return array.
  my @ret = ();

  # Try to match different patterns.
  if ($in =~ /$is_internal_format_re/o) {
    @ret = InternalStringToInternal($in);
  } else {
    # 1) Protect the fractional seconds period.
    $in =~ s/(:\d+)\.(.*)/$1\200$2/;
    # 2) Convert periods to spaces.
    $in =~ s/\./ /g;
    # 3) Convert back to the period for fractional seconds.
    $in =~ s/\200/\./;

    # Cycle through the numbers and set each element of the object.
    my @a = map { 0; } (YEAR..FRACTION);
    my $i = 0;
    while ($i<=FRACTION && $in =~ m/(\d+(\.\d*)?)/g) {
      $a[$i++] = $1;
    }

    # We need to read in either 3 or 6 numbers.
    return if ($i != 3 and $i != 6);

    if ($i == 6) {
      # Split the seconds into the integer and the fractional part.
      # Store only the normal accuracy for the fractional part.
      my $sec      = $a[SECOND];
      $a[SECOND]   = int($sec);
      $a[FRACTION] = 0 + DateTime::Math::fsub($sec, $a[SECOND]);
    }
    @ret = @a;
  }
  if (@ret) {
    return @ret;
  } else {
    return;
  }
}
# DatetimeToInternal

#----------------------------------------
# NOTES: Convert a (hh, mm, ss, fs) into fraction of a day.
# RETVAL: fraction of a day (0 <= f < 1) with very large precision.
# ACCESS: private nonmethod
sub HMSToFraction {
  my ($h, $m, $s, $fs) = @_;
  defined($fs) or $fs = 0;
  # Do the math that doesn't require high precision.
  $s += 60*($m+60*$h);
  # Now take into account high precision math.
  $s = DateTime::Math::fadd($s, $fs);
  DateTime::Math::fdiv($s, Secs_per_day);
}

#----------------------------------------
# NOTES: Convert a fraction of a day into (hh, mm, ss, fs).
# RETVAL: array of (hh, mm, ss, fs).
# ACCESS: private nonmethod
sub FractionToHMS {
  my $number = shift;

  # Remove the integer part of the number.
  my $fraction = DateTime::Math::fsub($number, int($number));

  $fraction = DateTime::Math::fmul($fraction, 24.0);
  my $h     = int($fraction);
  $fraction = DateTime::Math::fsub($fraction, $h);
  $fraction = DateTime::Math::fmul($fraction, 60.0);
  my $m     = int($fraction);
  $fraction = DateTime::Math::fsub($fraction, $m);
  $fraction = DateTime::Math::fmul($fraction, 60.0);
  my $s     = int($fraction);
  $fraction = 0+DateTime::Math::fsub($fraction, $s);
  ($h, $m, $s, $fraction);
}
# FractionToHMS

#----------------------------------------
# NOTES: Convert a time (hh:mm:ss:fs) to seconds since midnight.
# RETVAL: Seconds since midnight.
# ACCESS: private nonmethod
sub SecsSinceMidnight {
  my ($h, $m, $s, $fs) = @_;
  defined($fs) or $fs = 0;
  # Do the fast calculation with normal precision.
  $s += 60*($m + 60*$h);
  # Do the slow, very precise calculation.
  DateTime::Math::fadd($s, $fs);
}
# SecsSinceMidnight

#----------------------------------------
# NOTES: Convert a Gregorian day (yr,mo,day) to a serial day number, 
# NOTES: ie, return number of days since the beginning of time.
# NOTES: SDN 1 is 25 Nov 4714 B.C.
# NOTES: Negative input years are B.C.
# NOTES: Returns 0 on error.
# NOTES: This and SDNToDay were basically lifted whole-cloth 
# NOTES: from Scott E. Lee... details to follow... someday...
# ARG1 $y:  year
# ARG2 $mo: month
# ARG3 $d:  day
# RETVAL:   SDN
# ACCESS:   private nonmethod
sub DayToSDN {
  my ($y, $mo, $d) = @_;
  # NOTES: This is internal, so I assume all inputs are valid.  Caveat felis.

  # Make the year positive.
  $y += 4800 + ($y<0);
  # Adjust to nice start of year.
  if ($mo > 2) {
    $mo -= 3;
  } else {
    $mo += 9;
    $y--;
  }

  # Calculate sdn.
  use integer;
  (((($y/100)*Days_per_400_years)/4) + 
   ((($y%100)*Days_per_4_years)  /4) +
   ( ($mo*Days_per_5_months + 2) /5) + $d - SDN_Offset);
}
# DayToSDN

#----------------------------------------
# NOTES: Convert a SDN day back to normal time (yr,mo,day).
# NOTES: See DayToSDN().
# ARG1 $sdn
# RETVAL: array of (yr,mo,day)
# ACCESS: private nonmethod
sub SDNToDay {
  my $sdn = shift;

  # A mass of confused calculations.
  use integer;
  my $temp = ($sdn+SDN_Offset)*4-1;
  my $cent = $temp/Days_per_400_years;
  $temp    = (($temp%Days_per_400_years) / 4) * 4 + 3;
  my $y    = ($cent*100)+($temp/Days_per_4_years);
  my $doy  = ($temp%Days_per_4_years)/4+1;
  $temp    = $doy*5-3;
  my $m    = $temp/Days_per_5_months;
  my $d    = ($temp%Days_per_5_months)/5+1;
  # Convert to a real date.
  if ($m < 10) {
    $m += 3;
  } else {
    $m -= 9;
    $y++;
  }
  $y -= 4800;
  $y-- if ($y <= 0);
  ($y, $m, $d);
}
# SDNToDay

sub stringify {
  my $self = shift;
  my $sec = $self->[SECOND] + $self->[FRACTION];
  if ($sec == int($sec)) {
    return sprintf('%04d%02d%02d%02d%02d%02d', @$self[0..SECOND]);
  } else {
    my $str;
    if ($sec >= 10) {
      $str = sprintf('%04d%02d%02d%02d%02d%f', @$self[0..MINUTE], $sec);
    } else {
      $str = sprintf('%04d%02d%02d%02d%02d0%f', @$self[0..MINUTE], $sec);
    }
    # Trim any trailing 0's.
    $str =~ s/\.?0*$//;
    return $str;
  }
}

#
# Public DateTime::Precise class methods
#


#----------------------------------------
# NOTES: Constructor.
# NOTES: Return blessed reference to a array.  If the input is not
# NOTES: is not valid, then return an empty list in a list context, an
# NOTES: undefined value in a scalar context, or nothing in a void
# NOTES: context.
# ARG1 $dt: Initial date+time to set object to (optional)
# ACCESS: method
# EXAMPLE: $dt = DateTime::Precise->new('1998.03.25 20:25:30');
# EXAMPLE: $dt = DateTime::Precise->new('1974.11.02');
# EXAMPLE: $dt = DateTime::Precise->new('19741102123344');
# EXAMPLE: $dt = DateTime::Precise->new();
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Create the blessed array with the correct number of elements.
  my $self  = bless [YEAR .. FRACTION], $class;

  # Parse the input arguments depending upon the number of arguments.
  if (@_ == 0) {
    $self->set_gmtime_from_epoch_time;
  } elsif (@_ == 1) {
    # If there is only one argument, it is either the Unix epoch time
    # or a date string.  First try to match the exact internal format
    # and parse it using InternalStringToInternal.  Otherwise, see if
    # it is a number and treat it as an epoch time.  Finally, treat
    # the string as a gernal time/date format.
    my $arg = shift;
    if ($arg =~ /$is_internal_format_re/o) {
      @$self = InternalStringToInternal($arg);
      @$self or return;
    } elsif ($arg =~ /^\d+(\.\d*)?$/) {
      $self->set_gmtime_from_epoch_time($arg);
    } else {
      @$self = DatetimeToInternal($arg);
      @$self or return;
    }
  } elsif (@_ > 1) {
    $self->set_time(@_) or return;
  }

  $self;
}
# new

sub unix_seconds_since_epoch {
  $_[0] - JANUARY_1_1970;
}

sub gps_seconds_since_epoch {
  $_[0] - JANUARY_6_1980;
}

sub gps_week_seconds_day {
  my $self          = shift;
  my $epoch_seconds = $self->gps_seconds_since_epoch;
  my $week          = int($epoch_seconds/Secs_per_week);
  my $seconds       = $epoch_seconds - $week*Secs_per_week;
  my $day           = int($seconds/Secs_per_day);
  ($week, $seconds, $day);
}

sub gps_week {
  ($_[0]->gps_week_seconds_day)[0];
}

sub gps_seconds {
  ($_[0]->gps_week_seconds_day)[1];
}

sub gps_day {
  ($_[0]->gps_week_seconds_day)[2];
}

sub asctime {
  my $self = shift;

  sprintf("%s %s %2d %02d:%02d:%02d %s %4d",
	  $WeekAbbrev[$self->weekday],
	  $MonthAbbrev[$self->month],
	  $self->day,
	  $self->hours,
	  $self->minutes,
	  $self->seconds,
	  $TZ,
	  $self->year);
}

sub strftime {
  my $self     = shift;
  my $template = shift;
  $template    = '' unless defined $template;

  # Go through the template and substitute for all known patterns.
  # Change %% to \200 to protect it and not have it attach itself to
  # other characters.
  $template =~ s/%%/\200/g;
  my %strftime_values = %{$self->_strftime_values};
  while (my ($key, $value) = each %strftime_values) {
    $template =~ s/%$key/$value/g;
  }
  $template =~ s/\200/%/g;
  return $template;
}

sub set_time {
  my $self     = shift;
  my $template = shift;
  my @values   = @_;

  # Make a copy of the current DateTime::Precise object to work on.
  my $work = $self->copy;

  # If the input fails, then return an empty list in a list context, an
  # undefined value in a scalar context, or nothing in a void context.

  # The template should not be empty.
  return unless defined $template;

  # Split up the template into individual characters.  There should be
  # some keys.
  my @keys = split(//, $template);
  return unless @keys;

  # The first key must be an absolute time specifier.
  return unless ($SET_MASK{$keys[0]} & MASK_ABSOLUTE);

  # The rest of the keys must be relative.
  foreach my $key (@keys[1..$#keys]) {
    return if ($SET_MASK{$key} & MASK_ABSOLUTE);
  }

  # Go through each key and set the time from it.
  foreach my $key (@keys) {
    # Get the argument if the key requires it.  Leave the subroutine
    # if there is no value for the key.
    my $arg = 0;
    unless ($SET_MASK{$key} & MASK_NO_ARG) {
      return unless @values;
      $arg = shift(@values);
    }

    # Arguments can either be numerical or month names.
    my $partial = 0;
    if ($arg !~ /[a-zA-Z]/) {
      # Get the non-integer part of the argument.
      $partial = ($arg - int($arg)) if ($SET_MASK{$key} & MASK_USES_PARTIAL);
      $arg = int($arg);
    }

    # These keys set the time completely.
    if ($SET_MASK{$key} & MASK_ABSOLUTE) {
      # Set time to now.
      $key eq 'N' and $work->set_gmtime_from_epoch_time, next;
      # Set time to GPS time 0.
      $key eq 'G' and $work->clone(JANUARY_6_1980), next;
      # Set time to seconds since January 1, 1970 UTC.
      $key eq 's' and do {
        $work->set_gmtime_from_unix_epoch($arg);
        $work->addSec($partial);
        next;
      };
      # Set time to year and fractional year.
      $key eq 'Y' and do {
	$work->year($arg);
	$work->month(1);
	$work->day(1);
	$work->hours(0);
	$work->minutes(0);
	$work->seconds(0);
	$work->addSec($partial * Secs_per_day *
		      (IsLeapYear($arg) ? 366 : 365));
	next;
      };
      # Set time to modified fractional year.
      $key eq 'J' and do {
        my $time = ($arg + MODIFIED_JULIAN_DAY + $partial) * Secs_per_day;
        $work->set_gmtime_from_unix_epoch($time);
        next;
      };
      cluck "DateTime::Precise::set_time: unknown absolute key '$key'";
      next;
    }

    # The remaining keys set the time relative to the current time.
    if ($SET_MASK{$key} & MASK_USES_MULTIPLIER) {
      # If the key requires a multiplier, take care of it.
      $arg     -= $SET_START_VALUE{$key};
      $arg     *= $SET_MULTIPLER_VALUE{$key};
      $partial *= $SET_MULTIPLER_VALUE{$key};
      $work->addSec($arg + $partial);
      next;
    }

    # Otherwise we're using a special key.
    # Set time to the month.
    $key eq 'B' and do {
      $work->inc_month($arg);
      next;
    };
    cluck "DateTime::Precise::set_time: unknown relative key '$key'";
  }

  # Set the real DateTime::Precise to the working one.
  $self->clone($work);
}

sub get_time {
  my ($self, $template) = @_;

  # For each conversion, add one more value to an output array
  # containing the requested value.
  my %strftime_values = %{$self->_strftime_values};
  my @values;
  foreach my $char (split(//, $template)) {
    push(@values, $strftime_values{$char}) if defined($strftime_values{$char});
  }
  @values;
}

# Take in the day of the year, the year, the first day of the week (0
# = Sunday, 1 = Monday) and wether days before the first week of the
# year return as 0 or 53.  The last option, if true, uses the ISO 8601
# standard that January 4th is in week1.  Set the last two options to
# be true to get the %V behavior for strftime.
sub _week_of_year {
  my ($doy, $year, $week_begin, $previous, $jan4week1) = @_;

  # Calculate the day of the week for January 1.
  my $dow = DateTime::Precise->new("$year 1 1")->weekday;

  # Calculate number of days between Jan 1 and the beginning of the
  # first week.
  my $diff = $week_begin - $dow;
  $diff < 0 and $diff += 7;

  # Calculate the day of the year for the beginning of the first week.
  my $first_weekday = 1 + $diff;

  # If January 4th has to be in the first week and it currently isn't,
  # then add 7 to the day of the year.  January 4th isn't in the first
  # week if the difference between the first day of the first week and
  # January 1 is greater than 3.
  if ($jan4week1) {
    $diff > 3 and $doy += 7;
  }

  # If the day of the year is less than the beginning of the first
  # week, then either return 0 or 53.
  return ($previous ? 53 : 0) if ($doy < $first_weekday);

  # Return the week.
  ($doy - $first_weekday)/7 + 1;
}


sub _strftime_values {
  my $self = shift;

  # These values are strings preceeded by 0 if they don't fill all of
  # the space.
  my $y  = sprintf('%04d', $self->year);
  my $mo = sprintf('%02d', $self->month);
  my $d  = sprintf('%02d', $self->day);
  my $h  = sprintf('%02d', $self->hours);
  my $mn = sprintf('%02d', $self->minutes);
  my $s  = sprintf('%02d', $self->seconds);

  # These are numerical values.
  my $week_day                           = $self->weekday;
  my $day_of_year                        = $self->day_of_year;
  my $gps_seconds_since_epoch            = $self->gps_seconds_since_epoch;
  my $unix_seconds_since_epoch           = $self->unix_seconds_since_epoch;
  my ($gps_week, $gps_seconds, $gps_day) = $self->gps_week_seconds_day;

  # These are the initial values for strftime.  The remaining ones
  # that get put togther with these are below.
  my %values = (
    # same as %
    '%' => '%',

    # the abbreviated weekday name
    'a' => $WeekAbbrev[$week_day],

    # the full weekday name
    'A' => $WeekName[$week_day],

    # the abbreviated month name
    'b' => $MonthAbbrev[$mo],

    # the full month name
    'B' => $MonthName[$mo],

    # the appropriate date and time representation
    'c' => $self->asctime,

    # century number; single digits are preceded by 0
    'C' => sprintf('%02u', int($y/100)),

    # the day of month [1,31]; single digits are preceded by 0
    'd' => $d,

    # the day of month [1,31]; single digits are preceded by a space
    'e' => sprintf('%2s', $d+0),

    # the abbreviated month name
    'h' => $MonthAbbrev[$mo],

    # hour (24-hour clock) [0,23]; single digits are preceded by 0
    'H' => $h,

    # hour (12-hour clock) [1,12]; single digits are preceded by 0
    'I' => sprintf('%02d', (($h % 12) == 0) ? 12 : ($h % 12)),

    # the day of year
    'j' => sprintf('%03d', $day_of_year),

    # the hour (24-hour clock) [0,23]; single digits are preceded by a blank
    'k' => sprintf('%2s', $h+0),

    # the hour (12-hour clock) [1,12]; single digits are preceded by a blank
    'l' => sprintf('%2s', (($h % 12) == 0) ? 12 : ($h % 12)),

    # the month number [1,12]; single digits are preceded by 0
    'm' => $mo,

    # the minute [00,59]
    'M' => $mn,

    # insert a newline
    'n' => "\n",

    # the equivalent of either a.m. or p.m.
    'p' => $LC_AMPM[$h > 11],

    # the seconds [00,59]
    'S' => $s,

    # insert a tab
    't' => "\t",

    # the weekday as a decimal number [1,7] with Monday being 1
    'u' => $week_day == 0 ? 7 : $week_day,

    # week number of year as a decimal number [00,53] with Sunday
    # as the first day of week 1
    'U' => sprintf('%02d', _week_of_year($day_of_year, $y, 0, 0, 0)),

    # week number of the year as a decimal number [01,53], with
    # Monday as the first day of the week.  If the week containing
    # 1 January has four or more days in the new year, then it is
    # considered week 1; otherwise, it is week 53 of the previous
    # year, and the next week is week 1.
    'V' => sprintf('%02d', _week_of_year($day_of_year, $y, 1, 1, 1)),

    # the weekday as a decimal number [0,6], with 0 representing Sunday
    'w' => $week_day,

    # the week number of year as a decimal number [00,53], with Monday
    # as the first day of week 1
    'W' => sprintf('%02d', _week_of_year($day_of_year, $y, 1, 0, 0)),

    # year within century [00,99]
    'y' => sprintf('%02d', $y % 100),

    # the year, including the century (for example 1998)
    'Y' => sprintf('%04d', $y),

    # time zone name or abbreviation, or no bytes if no time zone
    # information exists
    'Z' => $TZ
  );

  # These are values built up using the previous ones.

  # the date as %m/%d/%y
  $values{'D'} = "$values{'m'}/$values{'d'}/$values{'y'}";
  # appropriate time representation in 12-hour clock format with %p
  $values{'r'} = "$values{'I'}:$values{'M'}:$values{'S'} $values{'p'}";
  # time as %H:%M
  $values{'R'} = "$values{'H'}:$values{'M'}";
  # time as %H:%M:%S
  $values{'T'} = "$values{'H'}:$values{'M'}:$values{'S'}",
  # the appropriate date representation
  $values{'x'} = "$values{'m'}/$values{'d'}/$values{'y'}";
  # the appropriate time representation
  $values{'X'} = $values{'T'};

  # Now add some nonstandard values.

  # seconds since UTC January 1, 1970
  $values{'s'} = $unix_seconds_since_epoch;
  # the GPS week (4 digits with leading 0's)
  $values{'G'} = sprintf("%04d", $gps_week);
  # the GPS seconds into the GPS week with no leading zeros
  $values{'g'} = $gps_seconds;
  # the GPS day (1 digit)
  $values{'f'} = $gps_day;
  # the GPS day (1 digit)
  $values{'F'} = $gps_day + 1;
  \%values;
}

#------------------------------------------- 
# NOTES: Set this DateTime::Precise equal to another.
# ARG2 $other: Other DateTime::Precise object to set by.
# ACCESS: method
# EXAMPLE: $dt->clone($other_dt);
sub clone {
  @{$_[0]} = @{$_[1]};
}
# clone

#------------------------------------------- 
# NOTES: Create a copy of this DateTime::Precise.
# ACCESS: method
# EXAMPLE: $t1 = $t2->copy;
sub copy {
  bless [ @{$_[0]} ], ref($_[0]);
}


# NOTES: Set (if param), or return the stringified DateTime::Precise.
# NOTES: See copy() for a better way to copy DateTime::Precises.
# ARG2 $in: (optional) estring to set internal to.
# RETVAL: estring
# ACCESS: method
# EXAMPLE: print $dt->internal('19980325202530'), " compressed\n";
sub internal {
  my ($self, $in) = @_;
  if ($in) {
    my @a = InternalStringToInternal($in);
    @$self = @a if @a;
  }
  "$self";
}
# internal

#----------------------------------------
# some days have bouncers and won't let you in.
# NOTES: Set date/time from passed datetime string.
# ARG2 $dt: string in datetime format ("YYYY.MM.DD hh:mm:ss")
# ACCESS: method
# RETVAL: return 1 if the date was sucessfully set, an empty list in
# RETVAL: a list context, an undefined value in a scalar context, or
# RETVAL: nothing in a void context.
# EXAMPLE: $dt->set_from_datetime("1998.03.23 16:58:11");
sub set_from_datetime {
  my ($self, $dt, $ret) = @_;
  if (defined $dt) {
    my @a = DatetimeToInternal($dt);
    if (@a) {
      @$self = @a;
      $ret = 1;
    }
  }
  if ($ret) {
    return $self;
  } else {
    return;
  }
}
# set_from_datetime

#----------------------------------------
# NOTES: Set date/time from decimal day of year, where day 1 is
# NOTES: midnight January 1.
# ARG2 $j: day of year
# ARG3 $y: year
# RETVAL: 1 if the date was sucessfully set, an empty list in a list
# RETVAL: context, an undefined value in a scalar context, or nothing
# RETVAL: in a void context.
# ACCESS: method
# EXAMPLE: $dt->set_from_day_of_year(1998, 1.325);
sub set_from_day_of_year {
  my $self = shift;
  my $y    = shift;
  my $j    = shift;

  unless (defined $y) {
    cluck "DateTime::Precise::set_from_day_of_year called without year parameter";
    return;
  }
  $y = int($y);

  unless (defined $j) {
    cluck "DateTime::Precise::set_from_day_of_year called without day of year parameter";
    return;
  }

  my $leap = IsLeapYear($y);
  return if ($j < 1);
  return if ($j >= ($leap ? 367 : 366));

  my @a = ($y);
  @a[HOUR..FRACTION] = FractionToHMS($j);

  # Calculate the month and the day.  Shift the first value in the
  # MonthDays array since it represents the number of days in
  # December.
  my @days_in_month = @MonthDays;
  $leap and ++$days_in_month[2];
  shift(@days_in_month);

  # Count the number of number of months into the year this date is.
  my ($m, $d) = (0, 0);
  $j = int($j);
  while ($j>0) {
    $m++;
    if ($j <= $days_in_month[0]) {
      $d = int($j);
      $j = 0;
    } else {
      $j -= $days_in_month[0];
      shift(@days_in_month);
    }
  }
  $a[YEAR]  = $y;
  $a[MONTH] = $m;
  $a[DAY]   = $d;
  @$self    = (@a);
  $self->_FixDate;
}
# set_from_day_of_year

#----------------------------------------
# NOTES: Returns the SDN representing the date, plus a fraction
# NOTES: representing the time since midnight (ie, noon=0.5).
# RETVAL: large, fractional number (eg, 2645455.075)
# ACCESS: method
sub serial_day {
  my $self = shift;
  DateTime::Math::fadd(DayToSDN(@$self), HMSToFraction(@$self[HOUR..FRACTION]));
}
# serial_day

#----------------------------------------
# NOTES: Set date/time from the serial day.
# ARG1: serial day
# RETVAL: 1 if the date was sucessfully set, an empty list in a list
# RETVAL: context, an undefined value in a scalar context, or nothing
# RETVAL: in a void context if the date was not set.
# ACCESS: method
# EXAMPLE: $dt->set_from_serial_day(4312343.325);
sub set_from_serial_day {
  my $self = shift;
  my $sdn  = shift;

  unless (defined $sdn) {
    cluck "DateTime::Precise::set_from_serial_day called without serial day parameter";
    return;
  }

  # Split the serial day into day and fraction of day.
  my $days           = int($sdn);
  my @a              = SDNToDay($days);
  @a[HOUR..FRACTION] = FractionToHMS($sdn);
  @$self             = @a;
  $self->_FixDate;
}
# set_from_serial_day

#----------------------------------------
# NOTES: Set from epoch time (to local date/time).
# ARG2 $epoch: seconds since 1904 (MacOS) or 1970 (most other systems, ie Unix)
# RETVAL: 1 if the date was sucessfully set.  If the date could not
# RETVAL: be set, then it returns an empty list in a list context, an
# RETVAL: undefined value in a scalar context, or nothing in a void
# RETVAL: context.
# ACCESS: method
# EXAMPLE: $dt->set_localtime_from_epoch_time(time);
sub set_localtime_from_epoch_time {
  my $self          = shift;
  my $time          = shift;
  $time             = time unless defined $time;
  my $epoch         = int($time);
  my @a             = localtime($epoch);
  $self->[YEAR]     = 1900 + $a[5];
  $self->[MONTH]    = $a[4] + 1;
  $self->[DAY]      = $a[3];
  $self->[HOUR]     = $a[2];
  $self->[MINUTE]   = $a[1];
  $self->[SECOND]   = $a[0];
  $self->[FRACTION] = $time - $epoch;
  $self;
}
# set_localtime_from_epoch_time

#----------------------------------------
# NOTES: Set from epoch time (to local date/time).
# ARG2 $epoch: seconds since 1904 (MacOS) or 1970 (most other systems, ie Unix)
# RETVAL: 1 if the date was sucessfully set.  If the date could not
# RETVAL: be set, then it returns an empty list in a list context, an
# RETVAL: undefined value in a scalar context, or nothing in a void
# RETVAL: context.
# ACCESS: method
# EXAMPLE: $dt->set_gmtime_from_epoch_time(time);
sub set_gmtime_from_epoch_time {
  my $self  = shift;
  my $time          = shift;
  $time             = time unless defined $time;
  my $epoch         = int($time);
  my @a             = gmtime($epoch);
  $self->[YEAR]     = 1900 + $a[5];
  $self->[MONTH]    = $a[4] + 1;
  $self->[DAY]      = $a[3];
  $self->[HOUR]     = $a[2];
  $self->[MINUTE]   = $a[1];
  $self->[SECOND]   = $a[0];
  $self->[FRACTION] = $time - $epoch;
  $self;
}
# set_gmtime_from_epoch_time

sub set_from_gps_week_seconds {
  my $self        = shift;
  my $gps_week    = shift;
  my $gps_seconds = shift;

  unless (defined $gps_week) {
    cluck "DateTime::Precise::set_from_gps_week_seconds called without gps_week parameter";
    return;
  }

  unless (defined $gps_seconds) {
    cluck "DateTime::Precise::set_from_gps_week_seconds called without gps_seconds parameter";
    return;
  }

  $self->clone(JANUARY_6_1980);
  $self->addSec($gps_week * 7, DAY);
  $self->addSec($gps_seconds);

  $self;
}

#----------------------------------------
# NOTES: Return the day of the year including the fraction of the day.
# ACCESS: method
# EXAMPLE: $j = $dt->day_of_year;
sub day_of_year {
  my $self = shift;
  my $y = $self->[YEAR];
  my $m = $self->[MONTH];
  my $d = $self->[DAY];
  for (my $i=1; $i<$m; ++$i) {
    $d += DaysInMonth($i, $y);
  }
  DateTime::Math::fadd($d, HMSToFraction(@$self[HOUR..FRACTION]));
}
# day_of_year

#----------------------------------------
# NOTES: Return the Julian day of the year including the fraction of
# NOTES: the day.
# ACCESS: method
# EXAMPLE: $j = $dt->julian_day;
sub julian_day {
  DateTime::Math::fsub($_[0]->day_of_year, 1);
}
# julian_day

#----------------------------------------
# NOTES: Return the year and optionally set it.
# ACCESS: method
# EXAMPLE: my $year = $dt->year(); $dt->year(1988);
sub year {
  my $self = shift;

  if (@_) {
    $self->[YEAR] = int(shift);
  }

  $self->[YEAR];
}
# year

#----------------------------------------
# NOTES: Return the month and optionally set it.
# ACCESS: method
# EXAMPLE: my $month = $dt->month(); $dt->month(11);
sub month {
  my $self = shift;

  if (@_) {
    $self->[MONTH] = int(shift);
    $self->_FixDate;
  }

  $self->[MONTH];
}
# month

#----------------------------------------
# NOTES: Return the day and optionally set it.
# ACCESS: method
# EXAMPLE: my $day = $dt->day(); $dt->day(21);
sub day {
  my $self = shift;

  if (@_) {
    $self->[DAY] = int(shift);
    $self->_FixDate;
  }

  $self->[DAY];
}
# day

#----------------------------------------
# NOTES: Return the hours and optionally set them.
# ACCESS: method
# EXAMPLE: my $hours = $dt->hours(); $dt->hours(13);
sub hours {
  my $self = shift;

  if (@_) {
    $self->[HOUR] = int(shift);
    $self->_FixDate;
  }

  $self->[HOUR];
}
# hours

#----------------------------------------
# NOTES: Return the minutes and optionally set them.
# ACCESS: method
# EXAMPLE: my $minutes = $dt->minutes(); $dt->minutes(49);
sub minutes {
  my $self = shift;

  if (@_) {
    $self->[MINUTE] = int(shift);
    $self->_FixDate;
  }

  $self->[MINUTE];
}
# minutes

#----------------------------------------
# NOTES: Return the seconds and optionally set them.
# ACCESS: method
# EXAMPLE: my $seconds = $dt->seconds(); $dt->seconds(29);
sub seconds {
  my $self = shift;

  if (@_) {
    $self->[SECOND]   = shift;
    $self->[FRACTION] = 0;
    $self->_FixDate;
  }

  $self->[SECOND] + $self->[FRACTION];
}
# seconds

#----------------------------------------
# NOTES: Returns the parameter string with substitutions:
# see Note at Bottom (??)
# NOTES:   %x    number zero-padded to 2 digits (ie, '02')<br>
# NOTES:   %-x   number space-padded to 2 digits (ie, ' 2')<br>
# NOTES:   %^x   unpadded number (ie, '2')<br>
# NOTES:   %~x   3-letter abbrev corresponding to value (%M and %w only)<br>
# NOTES:   %*x   full name corresponding to value (%M and %w only)<br>
# NOTES:   %%    '%'<br>
#
# NOTES: ...where x is one of: Y (year), M (month), D (day), h (hour),
# NOTES: m (minutes), s (seconds), w (day of the week).
# NOTES: Also supported are W (water year) and E (internal format).
# i'm taking out %J now, since no one's using them.
# ARG2 $form: format string (see notes)
# RETVAL: string, formatted at requested.
# ACCESS: method
# EXAMPLE: print $dt->dprintf("%^Y.%M.%D %h:%m:%s"); # datetime
# EXAMPLE: print $dt->dprintf("%~w %~M %-D %h:%m:%s CST %^Y"); # ctime
sub dprintf {
  my $self = shift;
  my $form = shift;

  # Fix the date if the special USGS midnight treatment needs to be
  # applied.
  my $usgs_midnight_fix_applied = 0;
  if ($USGSMidnight) {
    $usgs_midnight_fix_applied = $self->USGSDumbMidnightFix;
  }

  my @form = split(//,$form);	# make a list of all the chars in the format
  my ($y, $mo, $d, $h, $m, $s) = @$self[YEAR,MONTH,DAY,HOUR,MINUTE,SECOND];
  my @retn;

  # We shouldn't ever store in non-USGS midnight.  Check each char in
  # the format for formatting.
  while (@form) {
    my $char = shift(@form);
    if ($char eq '%') {	# found a format
      # the second char...  mod becomes the formatting char (~^*-)
      my $mod = shift(@form);
      if ($mod eq '%') {	     # %%
	# only push one '%'
	push(@retn, '%');
      } else {
	# $type is the letter (field specifier)
	my $type = $mod;		
	$type = shift(@form) unless ($mod=~/[a-zA-Z]/);
	# put the value to push into $field
        my $field = '';
        if ($type eq 's') {
          $field = $s;
        } elsif ($type eq 'm') {
          $field = $m;
        } elsif ($type eq 'h') {
          $field = $h;
        } elsif ($type eq 'D') {
          $field = $d;
        } elsif ($type eq 'M') {
          $field = $mo;
        } elsif ($type eq 'Y') {
          $field = $y;
        } elsif ($type eq 'W') {
          # This is water year.
          $field = $y;
	  $field++ if ($mo > 9);
        } elsif ($type eq 'w') {
          $field = $self->weekday;
        } elsif ($type eq 'E') {
          $mod   = '^';
          $field = "$self";
        }

	# Push an approprite char onto the return stack.
	if ($mod eq '*') { # %*
	  push(@retn, $MonthName[$field]) if ($type eq 'M');
	  push(@retn, $WeekName[$field]) if ($type eq 'w');
	} elsif ($mod eq '~') { # %~
	  push(@retn, $MonthAbbrev[$field]) if ($type eq 'M');
	  push(@retn, $WeekAbbrev[$field]) if ($type eq 'w');
	} elsif ($mod eq '^') { # %^
	  push(@retn, $field);
	} elsif ($mod eq '-') { # %-
	  push(@retn, sprintf("%2d",$field));
	} else {
	  $field=~s/^\d{2}// if ($type eq 'Y');
	  push(@retn, sprintf("%02d",$field));
	}
      }
    } else {
      # Just a plain character.
      push(@retn, $char);
    }
  }

  # If the USGS midnight fix was applied to the date, then undo it.
  if ($usgs_midnight_fix_applied) {
    $self->_FixDate;
  }
  
  return join('', @retn);
}
# dprintf

#----------------------------------------
# NOTES: Returns a reference to a tags hash, or a string containing
# NOTES: an error message.  Used by dprintf() and dscanf().
# ARG2 $format: format string (see dprintf())
# ARG3 $string: string to parse with $format
# this will confuse you, but that's ok, you shouldn't be using it anyhow.
# ACCESS: method private
sub extract_format {
  my $format = shift;
  my $string = shift;
  my($regex, $arg, %tags);
  my($mod,$type,$x,@ghost,$i);

  # xform the format string into a handy regex
  # remember what $ns go with what ()s
  $arg = 0;
  $regex = '';
  $format .= ' '; # add trailing space for luck
  while ($format) {
    # munge $format one character (or two) at a time
    if ($format =~ s/^\s+//) { # all whitespace is equal
      $regex .= '\s+';
    } elsif ($format =~ s/^%(.)(.)//) { # %MT
      $mod = $1;
      $type = $2;
      if ($1 eq '*' or $1 eq '~') { # it's %*M or %~M
	# it better be
	return "error in format: '%$1$2'?" unless $type eq 'M';
	if ($mod eq '~') {
	  $regex .= '(\w{3})';
	} else {
	  $regex .= '(\w+)';
	}
	$tags{'M'} = $arg++; # remember which () this is
      } else {
	unless ($mod=~/\d/) { # no width spec?
	  $format = $type . $format;	# put it back
	  $type = $mod; # and move things to the right place
	  $mod = '';
	}    
	if ($type eq 'c') { # chunk of random (non-ws) crap
	  $regex .= ($mod ? "[^\\s]{$mod}" : '[^\s]+?');
	} elsif ($type eq 'p') { # ignore any width spec for %p
	  $regex .= '([a|p]m?)';
	  $tags{'p'} = $arg++;
	} else { # anything else is digits
	  $regex .= ($mod ? "(\\d{$mod})" : '(\d+)');
	  $tags{$type} = $arg++;
	}
      }
    } elsif ($format =~ s/^(.)//) { # it's not %MT
      #($x = $1) =~ s/([\Q^$\{}*+?-./[]|()\E])/\\$1/; 
      # replace when you get the chance to test for typos
      ($x = $1) =~ s/([\^\$\\\{\}\*\+\?\-\.\/\[\]\|\(\)])/\\$1/; # sob
      $regex .= $x; # just toss it into the regex
    } else {
      return "I'm baffled by your format";
    }
  }
  # apply our nice new regex
  $regex =~ s/(.*\)).*$/$1/; # trim crap off the end
  @ghost = ($string =~ /$regex/);
  return "format does not match string" unless @ghost;
  # fill hash with matched values
  foreach $i (keys %tags) {
    $tags{$i} = $ghost[$tags{$i}];
  }	
  # seconds aren't necessarily given, but should be defined.
  $tags{'s'} = 0 unless exists($tags{'s'});
  # return
  \%tags;
}
# extract_format

#----------------------------------------
# NOTES: Takes a format string, and uses it to suck the date and 
# NOTES: time fields from the supplied string.  Current setting is
# NOTES: unchanged if dscanf() fails.
# 
# NOTES: All format characters recognized by dprintf() are valid.
# NOTES: Unless exact characters are supplied or format characters are
# NOTES: concatenated, will separate on non-matching chars.
# ARG2 $format: format string
# ARG3 $string: string to get date and time from
# RETVAL: undef on success, string containing error message on failure.
# ACCESS: method
# EXAMPLE: # this is the same as $dt->set_from_datetime(...)
# EXAMPLE: $dt->dscanf("%^Y.%M.%D %h:%m:%s", "1998.03.25 20:25:23");
#
# EXAMPLE: if ($msg = $dt->dscanf("%~M", $input)) {
# EXAMPLE:    print "Must enter a three-letter month abbrev.\n";
# EXAMPLE: }
sub dscanf {
  my $self   = shift;
  my $format = shift;
  my $string = shift;
  my(@form, @source, @ret);
  my($char, $mod, $type, $i, $x);
  my($arg, %tags, $regex, @ghost);
  my($msg); # is good for you

  $msg = extract_format($format, $string);
  return $msg unless (ref($msg)); # there was an error, got a string.
  %tags = %{$msg};

  # put things in the right place
  if (exists $tags{'U'}) {
    $self->set_localtime_from_epoch_time($tags{U});
  } elsif (exists $tags{'u'}) {
    $self->set_gmtime_from_epoch_time($tags{u});
  } elsif (exists $tags{'E'}) {
    return 'bad %E format' unless ($tags{'E'} =~ /^\d{14}$/);
    my @a = DatetimeToInternal($tags{'E'});
    if (@a) {
      @$self = @a;
    } else {
      return 'bad %E format';
    }
  } else {
    # check for sanity
    return 'bad seconds' unless ($tags{'s'} >= 0 and $tags{'s'} < 60);
    return 'bad minutes' unless ($tags{'m'} >= 0 and $tags{'m'} < 60);
    # check am/pm, if given
    if (exists($tags{p}) and $tags{'p'}=~/p/i) { # pm
      $tags{'h'}+=12 unless $tags{'h'}==12; # noon is 1200
    } elsif ($tags{'h'}==12) { # midnight?
      $tags{'h'}=0 if defined $tags{'p'};
    }
    return 'bad hours' unless ($tags{'h'} >= 0 and $tags{'h'} <= 24);

    # translate month names/abbrevs
    $tags{'M'} = $_month_name{lc $tags{'M'}} if ($tags{'M'}=~/[^\d]/);
    return 'bad month' unless ($tags{'M'} >= 1 and $tags{'M'} <= 12);

    if (defined $tags{'W'}) { # water year?
      carp "overriding %Y with %W" if defined $tags{'Y'};
      $tags{'Y'} = $tags{'W'};
      $tags{'Y'}-- if ($tags{'M'} < 9);
    }
    if ($tags{'Y'} =~ /^\d\d$/) {
      # we'll assume that no dates under AD 100 will be entered :)
      $tags{'Y'}+=1900;
    } else {
      return 'bad year' unless ($tags{'Y'}>=100 and $tags{'Y'}<10000);
    }

    return 'bad days' unless
	($tags{'D'} >= 1 
	 and $tags{'D'} <= DaysInMonth($tags{'M'},$tags{'Y'}));

    return 'no (or incomplete) date given'
	unless (defined $tags{D} && defined $tags{M} && defined $tags{Y});

    $self->[YEAR]     = $tags{'Y'};
    $self->[MONTH]    = $tags{'M'};
    $self->[DAY]      = $tags{'D'};
    $self->[HOUR]     = $tags{'h'};
    $self->[MINUTE]   = $tags{'m'};
    $self->[SECOND]   = $tags{'s'};
    $self->[FRACTION] = 0;
  }
  # return
  $self->_FixDate;
  return;
}
# dscanf



#----------------------------------------
# NOTES: return the day of the week, 0..6 (sun..sat).
# NOTES: SDN 0 is a saturday.  Used by dprintf().
# ACCESS: method private
sub weekday {
  ($_[0]->serial_day + 1) % 7;
}
# weekday

#----------------------------------------
# NOTES: Increment by addition of seconds.  Requires conversion to and
# NOTES: from SDN time.
# NOTES: Used by inc_* and overloaded add.
# ARG2 $secs: seconds
# ARG3 $unit: units (5,4,3,2) = (s,m,h,d) (negative increments are ok)
# ACCESS: method private
sub addSec {
  my $self      = shift;
  my $increment = shift;
  my $unit      = shift;
  $unit         = SECOND unless defined $unit;

  if ($increment == 0) {
    return $self;
  }

  # If the units are year or month then we cannot add the proper number
  # of seconds.
  cluck "DateTime::Precise::addSec cannot add with unit=$unit" if ($unit<DAY);

  # Take the increment and subtract from it any larger units.
  for (my $i=DAY; $i<$unit; $i++) {
    my $factor = 1;
    for (my $j=$i+1; $j<=$unit; $j++) {
      $factor *= $_full_unit[$j];
    }
    my $inc = $increment/$factor;
    if (my $int = int($inc)) {
      $self->[$i] += $int;
      $increment -= $int*$factor;
    }
  }

  # Chop up $increment into units and fractions of units.
  for (my $i=$unit; $i<FRACTION; $i++) {
    my $int = int($increment);
    $self->[$i] += $int;
    my $frac = $increment - $int;
    $increment = $frac*$_full_unit[$i+1];
    last if ($frac == 0);
  }

  # Anything remaining is added to the fractional part.
  $self->[FRACTION] += $increment;
  $self->_FixDate;
}
# addSec    

#----------------------------------------
# NOTES: Increment (or decrement) date.
# inc-decs by looping, unless you want more than 10 increments, at
# which point it's faster to break the date down and use addSec()
# (this should be re-checked)
# NOTES: This is generally called by AUTOLOAD, not by the end user (qv.)
# ARG2 $unit: unit to increment by
# ARG3 $increment: (opt, defaults to 1) number of units to inc, may be neg.
# ACCESS: method private
# EXAMPLE: $dt->inc(2, 13);  # add 13 days
# EXAMPLE: $dt->inc_day(13); # does the same thing.  see AUTOLOAD().
sub inc {
  my $self      = shift;
  my $unit      = shift;
  my $increment = shift;

  if (defined $increment) {
    if ($increment == 0) {
      return $self;
    }
  } else {
    $increment = 1;
  }

  if (!defined $unit) {
    $unit = SECOND;
    cluck "DateTime::Precise::inc Cannot increment without your unit";
  }

  # Just increment the appropriate unit.  Even if the increment is
  # very large, addSed combined with _FixDate can handle it.  If we're
  # incrementing the year or month, then just add the integer part of
  # the increment to the appropriate unit.  Otherwise, use the general
  # addSec, which can add fractions of units.
  if ($unit == YEAR or $unit == MONTH) {
    $self->[$unit] += int($increment);
  } else {
    $self->addSec($increment, $unit);
  }
  $self->_FixDate;
}    
# inc

#----------------------------------------
# NOTES: floor and ceil stuff
# NOTES: this is typically called through AUTOLOAD, not by hand.
# ARG2 $unit: unit to floor/ceil/round
# ARG3 $function: what to do: 0=floor, 1=ceil, 2=round
# ACCESS: method private
sub floorceil {
  my $self = shift;
  my $unit = shift;
  cluck "DateTime::Precise::floorceil cannot floor or ceiling without a unit" unless defined $unit;
  my $function = shift;	# 1 for ceil, 0 for floor, 2 for round
  # inc unit, so we play with the appropriate parts
  $unit++;
  # if round, redo function appropriately
  if ($function==2) {
    $function = ($self->[$unit] > $_half_unit[$unit]) ? 1 : 0;
  }
  # everything wants to be floored.
  foreach my $i ($unit..FRACTION) {
    $self->[$i] = 0 + ($i < HOUR);
  }
  # if ceil, inc the next 'greater' (lesser) unit
  if ($function==1) {
    $self->[$unit-1]++;
  }
  $self->_FixDate;
}
# floorceil

#----------------------------------------
# NOTES: Find the difference between two DateTime::Precises.
# NOTES: diff $a $b returns "$a-$b", in seconds.
# NOTES: Used by overloaded subtract.
# ARG2 $other: ref to another DateTime::Precise
# RETVAL: seconds of difference between $self and $other
# ACCESS: method
# EXAMPLE: $secstolunch = $lunch->diff($dt); # how much longer!@?@!?
# EXAMPLE: $secstolunch = $lunch - $dt;      # same thing
sub diff {
  my $self  = shift;
  my $other = shift;
  my $neg   = 0;		# want to sub lesser from greater.
  if ($self < $other) {
    # Swap $self and $other, and set $neg to 1.
    my $tmp = $self;
    $self   = $other;
    $other  = $tmp;
    $neg    = 1;
  }
  my @top = (DayToSDN(@$self),  SecsSinceMidnight(@$self[HOUR..FRACTION]));
  my @bot = (DayToSDN(@$other), SecsSinceMidnight(@$other[HOUR..FRACTION]));
  # Carry the seconds if need be.
  if ($bot[1] > $top[1]) {
    $top[1] = DateTime::Math::fadd($top[1], Secs_per_day);
    $top[0]--;
  }
  # Subtract and return seconds.
  my $diff = ($top[0] - $bot[0])*Secs_per_day;
  $diff = DateTime::Math::fadd($diff, DateTime::Math::fsub($top[1], $bot[1]));
  if ($neg) {
    $diff = DateTime::Math::fneg($diff);
  }
  $diff;
}
# diff

#----------------------------------------
# NOTES: AUTOLOAD - handle 'func_unit' sub names.
# NOTES: Allowable 'func' parts are in %_func_names
# NOTES: Allowable 'unit' parts are in %_unit_names
#
# NOTES: Provides the following functions:<br>
# NOTES: inc dec floor ceil round<br>
# NOTES: For the following units:<br>
# NOTES: second (or sec) minute (or min) hour day month (or mo) year<br>
#
# NOTES: inc adds the specified number of units to the date.
# NOTES: dec subtracts the units from the date.
# NOTES: floor sets the date to the largest whole given unit less than the
# NOTES: current date setting.
# NOTES: ceil sets the date to the smallest whole given unit greater 
# NOTES: than the current date setting.
# NOTES: round rounds the date to the closest whole given unit.
# ACCESS: method private
sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self) || cluck "DateTime::Precise::AUTOLOAD $self is not an object ($AUTOLOAD)";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;		# strip qualifier(s)
  my $func = $name;
  my($unit,$increment);
  return if $func eq 'DESTROY';
  $func =~ /(\w+)_(\w+)/;
  ($func, $unit) = ($1,$2);
  unless (exists($_func_name{$func}) && exists($_unit_name{$unit})) {
    cluck "DateTime::Precise::AUTOLOAD $name is not a valid function for object $type";
  }
  if ($func eq 'inc') {
    $self->inc($_unit_name{$unit}, @_);
  } elsif ($func eq 'dec') {
    $increment = shift;
    $increment = 1 unless defined $increment;
    $self->inc($_unit_name{$unit}, -$increment);
  } elsif ($func eq 'floor') {
    $self->floorceil($_unit_name{$unit}, 0);
  } elsif ($func eq 'ceil') {
    $self->floorceil($_unit_name{$unit}, 1);
  } elsif ($func eq 'round') {
    $self->floorceil($_unit_name{$unit}, 2);
  } else {
    cluck "DateTime::Precise::AUTOLOAD seems to have fallen out the bottom using $name";
  }
}
# AUTOLOAD


#
# overloaded operator functions
#

#----------------------------------------
# NOTES: add some seconds to a date
# ARG1 $a: DateTime::Precise
# ARG2 $n: number of seconds to add to $a
# ACCESS: private
sub ovld_add {
  my $a = shift;
  my $n = shift;
  cluck "DateTime::Precise::ovld_add $n is really really huge (did you try to add two dates?)"
      if ("$n" > "10000000000");
  $a->copy->addSec($n);
}
# ovld_add

#----------------------------------------
# NOTES: subtract some time from a date, or two dates from each other
# ARG1 $a: DateTime::Precise
# ARG2 $n: DateTime::Precise, or number of seconds to subtract.
# ACCESS: private
sub ovld_sub {
  my $a = shift;		# this be a DateTime::Precise or a subclass
  my $n = shift;		# this may be a DateTime::Precise
  if ("$n" > "10000000000") {	# subing two DateTime::Precises
    return $a->diff($n);
  } else {
    return $a->copy->addSec(-$n);
  }
}
# ovld_sub

1;

__END__

=pod

=head1 NAME

DateTime::Precise - Perform common time and date operations with
additional GPS operations

=head1 SYNOPSIS

 use DateTime::Precise;

 use DateTime::Precise qw(:TimeVars);

 # Constructors and ways to set time.
 $t1 = DateTime::Precise->new;
 $t2 = DateTime::Precise->new('1998. 4. 3 12:13:44.054');
 $t3 = DateTime::Precise->new(time() - 100.23456);
 $t4 = DateTime::Precise->new('1998.04.24');
 $t1->set_localtime_from_epoch_time;
 $t1->set_gmtime_from_epoch_time(time + 120.987);
 $t1->set_from_datetime('1998.03.23 16:58:14.65');
 $t1->set_time('YDHMS', 1998, 177, 9, 15, 26.5);

 # This is the same as $d3->set_from_datetime(...)
 $t3->dscanf("%^Y.%M.%D %h:%m:%s", "1998.03.25 20:25:23");
 if ($msg = $d1->dscanf("%~M", $input)) {
     print "error: $msg\n";
     print "Must enter a three-letter month abbrev.\n";
 }

 # Get different parts of the time.
 $year    = $t3->year;
 $month   = $t3->month;
 $day     = $t3->day;
 $hours   = $t3->hours;
 $minutes = $t3->minutes;
 $seconds = $t3->seconds;
 ($year, $day_of_year) = $t3->get_time('Yj');

 # Print times and dates.
 print $t2->asctime;
 print $t2->strftime('%T %C%n');
 print $t2->dprintf("%^Y.%M.%D %h:%m:%s");           # datetime
 print $t2->dprintf("%~w %~M %-D %h:%m:%s CST %^Y"); # ctime

 # Copy times.
 my $t4 = $t2->copy;

 # Set one time object to the same time as another: set $t3 equal to $t2.
 $t3->clone($t2);

 # Find the difference between two times.
 $secs_from_midnight = $t4 - $t1;
 $secs_from_midnight = $t4->diff($t1);

 # Add seconds, days, months, etc to time.
 $t1 = $t4 + 3600;                      # $t1 is now an hour after midnight
 $t1->inc_month(2);                     # add two months to $t1
 $t1->floor_month;                      # set $t1 to the first of the month
 $t1 -= 0.25;                           # subtract 1/4 of a second from $t1

 # Can compare and sort DateTime::Precise.
 print "It's late!!!" if ($t1 > $t4);
 @sorted = sort @birthdays;             # normal comparisons work fine

 # Get the GPS weeks, seconds and day.
 $gps_week    = $t1->gps_week;
 $gps_seconds = $t1->gps_seconds;
 $gps_day     = $t1->gps_day;
 ($gps_week, $gps_seconds, $gps_day) = $t1->gps_week_seconds_day;

=head1 DESCRIPTION

The purpose of this library was to replace our dependence on Unix
epoch time, which, being limited to a range of about 1970 to 2030, is
inadequate for our purposes (we have data as old as 1870).  This date
library effectively handles dates from A.D. 1000 to infinity, and
would probably work all the way back to 0 (ignoring, of course, the
switch-over to the Gregorian calendar).  The useful features of Unix
epoch time (ease of date difference calculation and date comparison,
strict ordering) are preserved, and elements such as human-legibility
are added.  The library handles fractional seconds and some date/time
manipulations used for the Global Positioning Satellite system.

The operators +/-, <=>, cmp, stringify are overloaded.  Addition
handles seconds and fractions of seconds, subtraction handles seconds
or date differences, compares work, and stringification returns the a
representation of the date.

The US Geological Survey (USGS) likes midnight to be 24:00:00 of the
previous day, not 00:00:00 of the day people expect.  If
$DateTime::Precise::USGSMidnight is set, dprintf will always print
midnight as 24:00:00 and the date returned from dprintf will have the
previous day's date.  Regardless, time is always stored internally as
00:00:00.

=head1 CONSTRUCTOR

=over 4

=item B<new>

=item B<new>('1998. 4. 3 12:13:44')

=item B<new>(time() - 100.23456)

=item B<new>('YDHMS', 1998, 200, 13, 16, 49.5)

This creates a new time object.  If no argument is passed, then the
time object is initialized with the time returned from I<gmtime>
(I<time>()).  The second form is used to set the time explicitly.  The
argument can be in one of three formats: "YYYY.MM.DD hh:mm:ss.ffff",
"YYYY.MM.DD" (midnight assumed), or "YYYYMMDDhhmmss.ffff".  Here ffff
are the fractions of seconds.  The third form sets the time using
I<gmtime>() with fractional seconds allowed.  The fourth form sets the
time using a format as the first argument followed by the particular
date adjustments as the following arguments.  See set_time() for more
information.  If the new fails, then new returns an empty list in a
list context, an undefined value in a scalar context, or nothing in a
void context.

Because the second and third forms pass only one argument to new(),
there must be a way of distinguishing them.  Currently the following
test is used: if any non-digit characters are found in the argument or
if the string form of the argument is longer than 10 character, then
assume it to be a string to parse for the date.  Otherwise it is the
time since the Unix epoch.  The string length of 10 was chosen since
when the Unix epoch time flips to 11 digits, it'll be roughly year
2287.

=back 4

=head1 METHODS

=over 4

=item B<set_from_datetime> I<datetime>

Set date/time from passed date/time string "YYYY.MM.DD hh:mm:ss.fff".
If B<set_from_datetime> successfully parses I<datetime>, then the
newly set date/time object is returned, otherwise it returns an empty
list in a list context, an undefined value in a scalar context, or
nothing in a void context.

=item B<set_localtime_from_epoch_time> [I<epoch>]

Set from epoch time into the local time zone.  If I<epoch> is passed,
then use that time to set the current time, otherwise use the time as
returned from I<time>() or from I<Time::HiRes::time>() if the
Time::HiRes module can be loaded.  If the Time::HiRes::time() can be
imported, then the resulting loaded time most likely will contain a
fractional second component.  The newly set date/time object is
returned.  The epoch can contain fractional seconds.

=item B<set_gmtime_from_epoch_time> [I<epoch>]

Set from the epoch time into the standard Greenwich time zone.  If
I<epoch> is passed, then use that time to set the current time,
otherwise use the time as returned from I<time>() or from
I<Time::HiRes::time>() if the Time::HiRes module can be loaded.  If
the Time::HiRes::time() can be imported, then the resulting loaded
time most likely will contain a fractional second component.  The
newly set date/time object is returned.  The epoch can contain
fractional seconds.

=item B<set_from_day_of_year> I<year> I<day_of_year>

Set date/from from the year and the decimal day of the year.  Midnight
January 1st is day 1, noon January 1st is 1.5, etc.  If the date was
successfully set, then the newly set date/time object is returned,
otherwise it returns an empty list in a list context, an undefined
value in a scalar context, or nothing in a void context.

=item B<set_from_serial_day> I<serial_day_number>

Set the date/time from the serial day.  See also serial_day().  If the
date was successfully set, then the newly set date/time object is
returned, otherwise is returns an empty list in a list context, an
undefined value in a scalar context, or nothing in a void context.

=item B<set_from_gps_week_seconds> I<gps_week> I<gps_seconds>

Set the current time using the number of weeks and seconds into the
week since GPS epoch (January 6, 1980 UTC).  If the date was
successfully set, then the newly set date/time object is returned,
otherwise is returns an empty list in a list context, an undefined
value in a scalar context, or nothing in a void context.

=item B<set_time> I<format> [I<arg>, [I<arg>, ...]]

Set the time.  I<format> is a string composed of a select set of
characters.  Some characters may take an optional argument, which are
listed following the I<format> argument in the same order as the
characters.  The first character must be an absolute time:

    N => Set time to now.  No argument taken.
    G => Set time to GPS time 0 (January 6, 1980).  No argument taken.
    Y => Set time to beginning of the year.  Argument taken.
    J => Set time to modified Julian date.  Argument taken.
    s => Set time to seconds since January 1, 1970.  Argument taken.

These characters represent modifiers to the time set using the above
characters:

    B => Add months to time.  Argument taken.
    W => Add weeks to time.  Argument taken.
    D => Add days counted from 1 to time.  Argument taken.
    d => Add days counted from 0 to time.  Argument taken.
    H => Add hours to time.  Argument taken.
    M => Add minutes to time.  Argument taken.
    S => Add seconds to time.  Argument taken.

If the date and time was successfully set, then it returns the newly
set date/time object, otherwise I<set_time>() returns an empty list in
a list context, an undefined value in a scalar context, or nothing in
a void context and the date and time remain unchanged.

=item B<get_time> I<string>

Return an array, where each element of the array corresponds to the
corresponding I<strftime>() value.  This string should not contain %
characters.  This method is a much, much better and faster way of
doing

    map {$self->strftime("%$_")} split(//, $string)

=item B<year> [I<year>]

Return the year.  If an argument is passed to B<year>, then set the
year to the the integer part of the argument and then return the newly
set year.

=item B<month> [I<month>]

Return the numerical month (1 = January, 12 = December).  If an
argument is passed to B<month>, then set the month to the integer part
of the argument and return the newly set month.

=item B<day> [I<day>]

Return the day of the month.  If an argument is passed to B<day>, then
set the day to the integer part of the argument and return the newly
set day.

=item B<hours> [I<hours>]

Return the hours in the day.  If an argument is passed to B<hours>,
then set the hours to the integer part of the argument and return the
newly set hours.

=item B<minutes> [I<minutes>]

Return the minutes in the hour.  If an argument is passed to
B<minutes>, then set the minutes to the integer part of the argument
and return the newly set minutes.

=item B<seconds> [I<seconds>]

Return the seconds in the minutes.  If an argument is passed to
B<seconds>, then set the seconds to the argument and return the newly
set seconds.  This argument accepts fractional seconds and will return
the fractional seconds.

=item B<serial_day>

Returns a serial day number representing the date, plus a fraction
representing the time since midnight (i.e., noon=0.5).  This is for
applications which need an scale index (we use it for positioning a
date on a time-series graph axis).  See also set_from_serial_day().

=item B<day_of_year>

Return the day of the year including the fraction part of the day.
Midnight January 1st is day 1, noon January 1st is 1.5, etc.

=item B<julian_day>

Return the day of the year including the fraction part of the day
where time is 0 based.  Midnight January 1st is day 0, noon January
1st is 0.5, noon January 2nd is 1.5, etc.

=item B<unix_seconds_since_epoch>

Return the time in seconds between the object and January 1, 1970 UTC.

=item B<gps_seconds_since_epoch>

Return the time in seconds between the object and January 6, 1980 UTC.

=item B<gps_week_seconds_day>

Return an array consisting of the GPS week 0 filled to four spaces,
the number of seconds into the GPS week, and the GPS day, where day 0
is Sunday.

=item B<gps_week>

Return the GPS week of the object.  The returned number is 0 filled to
four digits.

=item B<gps_seconds>

Return the number of seconds into the current GPS week for the current
object.

=item B<gps_day>

Return the GPS day of the week for the current object, where day 0 is
Sunday.

=item B<copy>

Return an identical copy of the current object.

=item B<clone> I<other_dt>
    
Set this DateTime::Precise equal to I<other_dt>.

=item B<dprintf> I<string>
    
Returns I<string> with substitutions:
    
    %x     number zero-padded to 2 digits (ie, '02')
    %C<-x> number space-padded to 2 digits (ie, ' 2')
    %^x    unpadded number (ie, '2')
    %~x    3-letter abbrev corresponding to value (%M and %w only)
    %*x    full name corresponding to value (%M and %w only)
    %%     '%'

where x is one of:
    
    h      hours (0..23)
    m      minutes (0..59)
    s      seconds (0..59)
    D      day of the month (1..31)
    M      month (1..12)
    Y      years since 1900 (ie, 96)
    W      USGS water year (year+1 for months Oct-Dec)
    w      day of the week (0..6, or "Mon", etc.)
    E      internal string (no ~^*-)

so, for example, to get a string in datetime format, you would pass a
string of '%^Y.%M.%D %h:%m:%s', or, to get a ctime-like string, you
would pass: C<'%~w %~M %-D %h:%m:%s CDT %^Y'> (presuming you're in the
CDT.  Maybe timezone support will show up some day).

The US Geological Survey (USGS) likes midnight to be 24:00:00 of the
previous day, not 00:00:00 of the day people expect.  If
$DateTime::Precise::USGSMidnight is set, dprintf will always print
midnight as 24:00:00 and the date returned from dprintf will have the
previous day's date.  Regardless, time is always stored internally as
00:00:00.

=item B<dscanf> I<format> I<string>

Takes a format string I<format>, and use it to read the date and time
fields from the supplied I<string>.  The current date and time is
unchanged if B<dscanf> fails.

All format characters recognized by dprintf() are valid.  Two
additional characters are recognized, 'U' which sets the time to the
local time/date using the number of seconds since Unix epoch time and
'u' which sets the time to GMT time/date using the number of seconds
since Unix epoch time.  Unless exact characters are supplied or format
characters are concatenated, will separate on non-matching characters.

=item B<strftime> I<format>

Just like the I<strftime>() function call.  This version is based on
the Solaris manual page.  I<format> is a string containing of zero or
more conversion specifications.  A specification character consists of
a '%' (percent) character followed by one conversion characters that
determine the conversion specifications behavior.  All ordinary
characters are copied unchanged to the return string.

The following GPS specific conversions are supported in this strftime:
    %s    the seconds since UTC January 1, 1970
    %G    the GPS week (4 digits with leading 0's)
    %g    the GPS seconds into the GPS week with no leading zeros
    %f    the GPS day where 0 = Sunday, 1 = Monday, etc
    %F    the GPS day where 1 = Sunday, 2 = Monday, etc

The following standard conversions are understood:

    %%    the same as %
    %a    the abbreviated weekday name
    %A    the full weekday name
    %b    the abbreviated month name
    %B    the full month name
    %c    the appropriate date and time representation
    %C    century number (the year divided by 100 and truncated to an
          integer as a decimal number [1,99]); single digits are
          preceded by 0
    %d    day of month [1,31]; single digits are preceded by 0
    %D    date as %m/%d/%y
    %e    day of month [1,31]; single digits are preceded by a space
    %h    locale's abbreviated month name
    %H    hour (24-hour clock) [0,23]; single digits are preceded by 0
    %I    hour (12-hour clock) [1,12]; single digits are preceded by 0
    %j    day number of year [1,366]; single digits are preceded by 0
    %k    hour (24-hour clock) [0,23]; single digits are preceded by
          a blank
    %l    hour (12-hour clock) [1,12]; single digits are preceded by
          a blank
    %m    month number [1,12]; single digits are preceded by 0
    %M    minute [00,59]; leading zero is permitted but not required
    %n    insert a newline
    %p    either AM or PM
    %r    appropriate time representation in 12-hour clock format with
          %p
    %R    time as %H:%M
    %S    seconds [00,61]
    %t    insert a tab
    %T    time as %H:%M:%S
    %u    weekday as a decimal number [1,7], with 1 representing Sunday
    %U    week number of year as a decimal number [00,53], with Sunday
          as the first day of week 1
    %V    week number of the year as a decimal number [01,53], with
          Monday as the first day of the week. If the week containing 1
          January has four or more days in the new year, then it is
          considered week 1; otherwise, it is week 53 of the previous
          year, and the next week is week 1.
    %w    weekday as a decimal number [0,6], with 0 representing Sunday
    %W    week number of year as a decimal number [00,53], with Monday
          as the first day of week 1
    %x    locale's appropriate date representation
    %X    locale's appropriate time representation
    %y    year within century [00,99]
    %Y    year, including the century (for example 1993)
    %Z    Always GMT

=item B<asctime>

Return a string such as 'Fri Apr 3 12:13:44 GMT 1998'.  This is
equivalent to I<strftime>('%c').

=back 4

=head2 Incrementing and rounding

There are many subroutines of the format 'func_unit', where func is
one of (inc, dec, floor, ceil, round) and unit is one of (second,
minute, hour, day, month, year) [second and minute can be abbreviated
as sec and min respectively].

I<inc_unit>(i) increments the date by i I<unit>s (i defaults to 1 if
no parameter is supplied).  For days through seconds, fractional
increments are allowed.  However, for months and years, only the
integer part of the increment is used.

I<dec_unit>(i) identical to I<inc_unit>(C<-i>).

I<round_unit>() rounds the date to the nearest I<unit>.  Rounds years
down for Jan-Jun, and up for Jul-Dec; months down for 1st-15th and up
for 16th and later; days round up on or after 12:00:00; hours on or
after xx:30:00, minutes on or after 30 seconds; seconds on or after
0.5 seconds.

I<floor_unit>() rounds the date I<down> to the earliest time for the
current I<unit>.  For example, I<floor_month>() rounds to midnight of
the first day of the current month, floor_day() to midnight of the
current day, and I<floor_hour>() to xx:00:00.

I<ceil_unit>() is the complementary function to floor.  It rounds the
date I<up>, to the earliest time in the I<next> unit.  E.g.,
I<ceil_month>() makes the date midnight of the first day of the next
month.

=head2 Overloaded operators

Addition, subtraction, and comparison operators are overloaded, as
well as the string representation of a date object.

    # create a new object
    $x = DateTime::Precise->new('1996.05.05 05:05:05');
    # copy it
    $y = $x;
    # increment x by one second
    $x++;
    # decrement by a day
    $y = $y - 86400;
    # test em
    print ($x < $y ? "x is earlier\n" : "y is earlier\n");
    # get the difference
    print "The difference between x and y is ", $x-$y, " seconds.\n";

If $x is a date object, C<$x + $i> is identical to $x->inc_sec($i).

There are two possible results from subtraction.  C<$x - $i>, where $i
is a number, will return a new date, $i seconds before $x. C<$x - $y>,
where $y is another date object, is identical to $x->diff($y).

Comparison operators (<,>,==,etc) work as one would expect.

=head1 PUBLIC CONSTANTS

The following variables are not imported into your package by default.
If you want to use them, then use

    use DateTime::Precise qw(:TimeVars);

in your package.  Otherwise, you can use the fully qualified package
name, such as $DateTime::Precise::USGSMidnight.

=item B<$USGSMidnight>

Set this to 1 if you want midnight represented as 24:00:00 of the
previous day.  The default value is 0 which does not change the
behavior of midnight.  To use this variable in your code, load the
DateTime::Precise module like this:

    use DateTime::Precise qw($USGSMidnight);

Setting this only changes the output of dprintf for date and times
that are exactly midnight.

=item B<@MonthDays>

Days per month in a non-leap year.  This array is 1 indexed, so 0 is
December, 1 is January, etc.

=item B<@MonthName>

Month names.  This array is 1 indexed, so 0 is December, 1 is January,
etc.

=item B<@MonthAbbrev>

Month abbreviated names.  This array is 1indexed, so 0 is Dec, 1 is
Jan, etc.

=item B<@WeekName>

Names of the week, 0 indexed.  So 0 is Sunday, 1 is Monday, etc.

=item B<@WeekAbbrev>

Abbreviated names of the week, 0 indexed.  So 0 is Sun, 1 is Mon, etc.

=item B<&Secs_per_week>

The number of seconds in one week (604800).

=item B<&Secs_per_day>

The number of seconds in one day (86400).

=item B<&Secs_per_hour>

The number of seconds in one hour (3600).

=item B<&Secs_per_minute>

The number of seconds in one minute (60).

=item B<&JANUARY_1_1970>

Subroutine returning the Unix epoch time January 1, 1970 UTC.

=item B<&JANUARY_6_1980>

Subroutine returning the GPS epoch time January 6, 1980 UTC.

=head1 PUBLIC SUBROUTINES

=over 4

=item B<IsLeapYear>(year)

Returns true if the argument is a leap year.

=item B<DaysInMonth>(month, year)

Returns the number of days in the month.

=back 4

=head1 IMPLEMENTATION

This package is based on the DateTime package written by Greg Fast
<gdfast@usgs.gov>.  The _week_of_year routine is based on the
Date_WeekOfYear routine from the Date::DateManip package written by
Sullivan Beck.

Instead of using the string representation used in the original
DateTime package, this package represents the time internally as a
seven element array, where the elements correspond to the year, month,
day, hours, minutes, seconds, and fractional seconds.

=head1 AUTHOR

Contact: Blair Zajac <blair@orcaware.com>.  The original version of
this module was based on DateTime written by Greg Fast
<gdfast@usgs.gov>.

=cut
