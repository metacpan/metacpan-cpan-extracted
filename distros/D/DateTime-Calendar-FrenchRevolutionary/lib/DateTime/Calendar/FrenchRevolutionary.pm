# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for converting to/from the French Revolutionary calendar
# Copyright (c) 2003, 2004, 2010, 2011, 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary;

use utf8;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.17';

use Params::Validate qw(validate SCALAR BOOLEAN OBJECT);
use Roman;
use DateTime;
use DateTime::Calendar::FrenchRevolutionary::Locale;

my $BasicValidate =
    { year   => { type => SCALAR },
      month  => { type => SCALAR, default => 1,
                  callbacks =>
                  { 'is between 1 and 13' =>
                    sub { $_[0] >= 1 && $_[0] <= 13 }
                  },
                },
      day    => { type => SCALAR, default => 1,
                  callbacks =>
                  { 'is between 1 and 30' =>
                    sub { $_[0] >= 1 && $_[0] <= 30 },
                  },
                },
      hour   => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 9' =>
                    sub { $_[0] >= 0 && $_[0] <= 9 },
                  },
                },
      minute => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 99' =>
                    sub { $_[0] >= 0 && $_[0] <= 99 },
                  },
                },
      second => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 99' =>
                    sub { $_[0] >= 0 && $_[0] <= 99 },
                  },
                },
      abt_hour   => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 23' =>
                    sub { $_[0] >= 0 && $_[0] <= 23 },
                  },
                },
      abt_minute => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 59' =>
                    sub { $_[0] >= 0 && $_[0] <= 59 },
                  },
                },
      abt_second => { type => SCALAR, default => 0,
                  callbacks =>
                  { 'is between 0 and 61' =>
                    sub { $_[0] >= 0 && $_[0] <= 61 },
                  },
                },
      nanosecond => { type => SCALAR, default => 0,
                      callbacks =>
                      { 'cannot be negative' =>
                        sub { $_[0] >= 0 },
                      }
                    },
      locale    => { type => SCALAR | OBJECT,
                      callbacks =>
                      { "only 'fr', 'en', 'es' and 'it' possible" =>
                        sub { ($_[0] eq 'fr') or ($_[0] eq 'en')
                                              or ($_[0] eq 'es')
                                              or ($_[0] eq 'it')
                                              or ref($_[0]) =~ /(?:en|es|fr|it)$/ },
                      },
                     default => DefaultLocale() },
    };

my $NewValidate =
    { %$BasicValidate,
      time_zone => { type => SCALAR | OBJECT,
                      callbacks =>
                      { "only 'floating' possible" =>
                        sub { ($_[0] eq 'floating') or ref($_[0]) and $_[0]->is_floating },
                      },
                     default => 'floating' },
    };
my $Lastday_validate = { %$BasicValidate };
delete $Lastday_validate->{day};

# Constructors
sub new {
    my $class = shift;
    my %args = validate( @_, $NewValidate );

    my $self = {};

    $self->{tz} = DateTime::TimeZone->new(name => 'floating');
    if ( ref $args{locale} )
      { $self->{locale} = $args{locale} }
    else
      { $self->{locale} = DateTime::Calendar::FrenchRevolutionary::Locale->load( $args{locale} ) }

    $self->{local_rd_days} = $class->_ymd2rd(@args{qw(year month day)});
    my $abtsecs = $class->_time_as_abt_seconds(@args{qw(abt_hour abt_minute abt_second)});
    my $decsecs = $class->_time_as_seconds(@args{qw(hour minute second)});
    warn("You cannot specify both 24x60x60 time and 10x100x100 time when initializing a date")
        if $^W && $abtsecs && $decsecs;
    # We prefer decimal time over Anglo-Babylonian time when initializing a date
    $self->{local_rd_secs} = $decsecs ? $decsecs : $abtsecs;
    $self->{rd_nano} =  $args{nanosecond};

    bless $self, $class;
    $self->_calc_local_components;
    $self->_calc_utc_rd;

    return $self;
}

sub from_epoch {
  my $class = shift;
  my %args = validate( @_,
                         { epoch => { type => SCALAR },
                          locale => { type => SCALAR | OBJECT,
                                      default => $class->DefaultLocale },

                         }
                       );

  my $date = DateTime->from_epoch(%args);
  return $class->from_object(object => $date);
}

# use scalar time in case someone's loaded Time::Piece
sub now { shift->from_epoch(epoch => (scalar time), @_) }

sub from_object {
  my $class = shift;
  my %args = validate(@_,
                         { object => { type => OBJECT,
                                       can => 'utc_rd_values',
                                     },
                           locale => { type => SCALAR | OBJECT,
                                      default => $class->DefaultLocale },
                         },
                       );

  my $object = delete $args{object};
  $object = $object->clone->set_time_zone('floating')
      if $object->can('set_time_zone');

  my ($rd_days, $rd_secs, $rd_nano) = $object->utc_rd_values;

  my %p;
  @p{ qw(year  month   day) }     = $class->_rd2ymd($rd_days);
  # ABT seconds preferred over decimal seconds, because of precision loss
  @p{ qw(abt_hour  abt_minute  abt_second) }  = $class->_abt_seconds_as_components($rd_secs);
  # nanoseconds are copied, never converted ABT to decimal or reverse
  $p{nanosecond} = $rd_nano || 0;
  #@p{ qw(hour minute second) } = $class->_seconds_as_components($rd_secs);

  my $new = $class->new(%p, %args, time_zone => 'floating');

  return $new;
}

sub last_day_of_month {
    my $class = shift;
    my %p = validate( @_, $Lastday_validate);
    my $day = $p{month} <= 12 ? 30 : $class->_is_leap_year($p{year}) ? 6 : 5;
    return $class->new(%p, day => $day);
}

sub clone { bless { %{ $_[0] } }, ref $_[0] }

# Many of the same parameters as new() but all of them are optional,
# and there are no defaults.
my $SetValidate =
    { map { my %copy = %{ $BasicValidate->{$_} };
            delete $copy{default};
            $copy{optional} = 1;
            $_ => \%copy }
      keys %$BasicValidate };
sub set
{
    my $self = shift;
    my %p = validate( @_, $SetValidate );

    my %old_p =
        ( map { $_ => $self->$_() }
          qw( year month day hour minute second nanosecond locale )
        );

    my $new_dt = (ref $self)->new( %old_p, %p );

    %$self = %$new_dt;

    return $self;
}

sub set_time_zone { } # do nothing, only 'floating' allowed

# Internal functions
use constant REV_BEGINNING  => 654415; # RD value for 1 Vendémiaire I in the Revolutionary calendar
use constant NORMAL_YEAR    => 365;
use constant LEAP_YEAR      => 366;
use constant FOUR_YEARS     =>  4 * NORMAL_YEAR + 1; # one leap year every four years
use constant CENTURY        => 25 * FOUR_YEARS - 1;  # centuries aren't leap years...
use constant FOUR_CENTURIES =>  4 * CENTURY + 1;     # ...except every four centuries that are.
use constant FOUR_MILLENIA  => 10 * FOUR_CENTURIES - 1; # ...except every four millenia that are not.

# number of days between the start of the revolutionary calendar, and the
# beginning of year n - 1 as long as the equinox rule is in effect
my @YEARS_BEGINS=    (0, 365, 730, 1096, 1461, 1826, 2191, 2557, 2922, 3287, 3652,
                   4018, 4383, 4748, 5113, 5479, 5844);
sub _is_leap_year {
    my ($self, $year) = @_;

    # Autumn equinox from I to XIX
    return 1 if ($year == 3) or ($year == 7) or ($year == 11) or ($year == 15);
    return 0 if ($year < 20);

    # Romme rule from XX on
    return 0 if $year %    4; # not a multiple of 4 -> normal year
    return 1 if $year %  100; # a multiple of 4 but not of 100 is a leap year
    return 0 if $year %  400; # a multiple of 100 but not of 400 is a normal year
    return 1 if $year % 4000; # a multiple of 400 but not of 4000 is leap
    return 0; # a multiple of 4000 is a normal year
}

sub _calc_utc_rd {
  my $self = shift;

  delete $self->{utc_c};

  if ($self->{tz}->is_utc)
    {
      $self->{utc_rd_days} = $self->{local_rd_days};
      $self->{utc_rd_secs} = $self->{local_rd_secs};
      return;
    }

  $self->{utc_rd_days} = $self->{local_rd_days};
  $self->{utc_rd_secs} = $self->{local_rd_secs} - $self->_offset_from_local_time;
  _normalize_seconds($self->{utc_rd_days}, $self->{utc_rd_secs}, $self->{rd_nano});
}

sub _calc_local_rd {
  my $self = shift;

  delete $self->{local_c};

  # We must short circuit for UTC times or else we could end up with
  # loops between DateTime.pm and DateTime::TimeZone
  if ($self->{tz}->is_utc)
    {
      $self->{local_rd_days} = $self->{utc_rd_days};
      $self->{local_rd_secs} = $self->{utc_rd_secs};
    }
   else
    {
      $self->{local_rd_days} = $self->{utc_rd_days};
      $self->{local_rd_secs} = $self->{utc_rd_secs} + $self->offset;
      _normalize_seconds($self->{local_rd_days}, $self->{local_rd_secs});
    }

    $self->_calc_local_components;
}

sub _normalize_seconds {
  my ($d, $s) = @_;
  my $adj;
  if ($s < 0)
    { $adj = int(($s - 86399) / 86400) }
  else
    { $adj = int($s / 86400) }
  $_[0] += $adj;
  $_[1] -= $adj * 86400;
}

sub _calc_local_components {
  my $self = shift;
  @{ $self->{local_c} }{ qw(year month day day_of_decade day_of_year) } 
        = $self->_rd2ymd($self->{local_rd_days}, 1);
  @{ $self->{local_c} }{ qw(abt_hour abt_minute abt_second) }
        = $self->_abt_seconds_as_components($self->{local_rd_secs});
  @{ $self->{local_c} }{ qw(hour minute second) }
        = $self->_seconds_as_components($self->{local_rd_secs});
}

sub _calc_utc_components {
  my $self = shift;
  @{ $self->{utc_c} }{ qw(year month day) } = $self->_rd2ymd($self->{utc_rd_days});
  @{ $self->{utc_c} }{ qw(abt_hour abt_minute abt_second) }
          = $self->_abt_seconds_as_components($self->{utc_rd_secs});
  @{ $self->{utc_c} }{ qw(hour minute second) } 
          = $self->_seconds_as_components($self->{utc_rd_secs});
}

sub _ymd2rd {
    my ($self, $y, $m, $d) = @_;
    my $rd = REV_BEGINNING - 1; # minus 1 for the zeroth Vendémiaire
    $y --;  #get years *before* this year.  Makes math easier.  :)
    # first, convert year into days. . .
    if ($y < 0 || $y >= 16) {
      # Romme rule in effect, or nearly so
      my $x = int($y/4000);
      --$x if $y <= 0;
      $rd += $x * FOUR_MILLENIA;
      $y  %= 4000;
      $rd += int($y/400)* FOUR_CENTURIES;
      $y  %= 400;
      $rd += int($y/100)* CENTURY;
      $y  %= 100;
      $rd += int($y/4)* FOUR_YEARS;
      $y  %= 4;
      $rd += $y * NORMAL_YEAR;
    }
    else {
      # table look-up for the programmer-hostile equinox rule
      $rd += $YEARS_BEGINS[$y];
    }

    # now, month into days.
    $rd += 30 * ($m - 1) + $d;
    return $rd;
}

sub _rd2ymd {
    my ($self, $rd, $extra) = @_;

    my $doy;
    my $y;
    # note:  years and days are initially days *before* today, rather than
    # today's date.  This is because of fenceposts.  :)
    $doy =  $rd - REV_BEGINNING;
    if ($doy >= 0 && $doy < $YEARS_BEGINS[16]) {
      $y = scalar grep { $_ <= $doy } @YEARS_BEGINS;
      $doy -= $YEARS_BEGINS[$y - 1];
      $doy++;
    }
    else {
      #$doy --;
      my $x;
      $x    = int ($doy / FOUR_MILLENIA);
      --$x  if $doy < 0; # So pre-1792 dates will give something that look about right
      $y   += $x * 4000;
      $doy -= $x * FOUR_MILLENIA;

      $x    = int ($doy / FOUR_CENTURIES);
      $y   += $x * 400;
      $doy -= $x * FOUR_CENTURIES;

      $x    = int ($doy / CENTURY);
      $x    = 3 if $x == 4; # last day of the 400-year period; see comment below
      $y   += $x * 100;
      $doy -= $x * CENTURY;

      $x    = int ($doy / FOUR_YEARS);
      $y   += $x * 4;
      $doy -= $x * FOUR_YEARS;

      $x    = int ($doy / NORMAL_YEAR);
      # The integer division above divides the 4-year period, 1461 days,
      # into 5 parts: 365, 365, 365, 365 and 1. This mathematically sound operation
      # is wrong with respect to the calendar, which needs to divide
      # into 4 parts: 365, 365, 365 and 366. Therefore the adjustment below.
      $x    = 3 if $x == 4; # last day of the 4-year period
      $y   += $x;
      $doy -= $x * NORMAL_YEAR;

      ++$y; # because of 0-based mathematics vs 1-based chronology
      ++$doy;
    }
    my $d  = $doy % 30 || 30;
    my $m = ($doy - $d) / 30 + 1;
    if ($extra)
      {
        # day_of_decade, day_of_year
        my $dod = ($d % 10) || 10;
        return $y, $m, $d, $dod, $doy;
      }
    return $y, $m, $d;
}

# Aliases provided for compatibility with DateTime; if DateTime switches
# over to _ymd2rd and _rd2ymd, these will be removed eventually.
*_greg2rd = \&_ymd2rd;
*_rd2greg = \&_rd2ymd;

#
# Accessors
#
sub year    { $_[0]->{local_c}{year} }

sub month   { $_[0]->{local_c}{month} }
*mon = \&month;

sub month_0 { $_[0]->{local_c}{month} - 1 };
*mon_0 = \&month_0;

sub month_name {
    my $self = shift;
    return $self->{locale}->month_name($self);
    #return $months[$self->month_0]
}

sub month_abbr {
    my $self = shift;
    return $self->{locale}->month_abbreviation($self);
    #return $months_short[$self->month_0]
}

sub day_of_month { $_[0]->{local_c}{day} }
*day  = \&day_of_month;
*mday = \&day_of_month;

sub day_of_month_0 { $_[0]->{local_c}{day} - 1 }
*day_0  = \&day_of_month_0;
*mday_0 = \&day_of_month_0;

sub day_of_decade { $_[0]->{local_c}{day} % 10 || 10 }
*dod         = \&day_of_decade;
*dow         = \&day_of_decade;
*wday        = \&day_of_decade;
*day_of_week = \&day_of_decade;

sub day_of_decade_0 { ($_[0]->{local_c}{day} - 1) % 10 }
*dod_0         = \&day_of_decade_0;
*dow_0         = \&day_of_decade_0;
*wday_0        = \&day_of_decade_0;
*day_of_week_0 = \&day_of_decade_0;

sub day_name {
    my $self = shift;
    return $self->{locale}->day_name($self);
    #return $decade_days[$self->day_of_decade_0];
}

sub day_abbr {
    my $self = shift;
    return $self->{locale}->day_abbreviation($self);
    #return $decade_days_short[$self->day_of_decade_0];
}

sub day_of_year { $_[0]->{local_c}{day_of_year} }
*doy = \&day_of_year;

sub day_of_year_0 { $_[0]->{local_c}{day_of_year} - 1 }
*doy_0 = \&day_of_year_0;

sub feast_short {
  my ($dt) = @_;
  return $dt->{locale}->feast_short($dt);
}
*feast = \&feast_short;

sub _raw_feast {
  my ($dt) = @_;
  return $dt->{locale}->_raw_feast($dt);
}

sub feast_long {
  my ($dt) = @_;
  return $dt->{locale}->feast_long($dt);
}

sub feast_caps {
  my ($dt) = @_;
  return $dt->{locale}->feast_caps($dt);
}

sub ymd {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;
    return sprintf("%0.4d%s%0.2d%s%0.2d",
                   $self->year, $sep,
                   $self->{local_c}{month}, $sep,
                   $self->{local_c}{day});
}
*date = \&ymd;

sub mdy {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;
    return sprintf("%0.2d%s%0.2d%s%0.4d",
                   $self->{local_c}{month}, $sep,
                   $self->{local_c}{day},   $sep,
                   $self->year);
}

sub dmy {
  my ($self, $sep) = @_;
  $sep = '-' unless defined $sep;
  return sprintf("%0.2d%s%0.2d%s%0.4d",
                 $self->{local_c}{day},   $sep,
                 $self->{local_c}{month}, $sep,
                 $self->year);
}

# Anglo-Babylonian (or sexagesimal) time
sub abt_hour   { $_[0]->{local_c}{abt_hour} }
sub abt_minute { $_[0]->{local_c}{abt_minute} } *abt_min = \&abt_minute;
sub abt_second { $_[0]->{local_c}{abt_second} } *abt_sec = \&abt_second;
sub abt_hms {
  my ($self, $sep) = @_;
  $sep = ':' unless defined $sep;
  return sprintf("%0.2d%s%0.2d%s%0.2d",
                    $self->{local_c}{abt_hour},   $sep,
                    $self->{local_c}{abt_minute}, $sep,
                    $self->{local_c}{abt_second});
}

sub nanosecond { $_[0]->{rd_nano} }

# Decimal time
sub hour   { $_[0]->{local_c}{hour} }
sub minute { $_[0]->{local_c}{minute} } *min = \&minute;
sub second { $_[0]->{local_c}{second} } *sec = \&second;

sub hms {
    my ($self, $sep) = @_;
    $sep = ':' unless defined $sep;
    return sprintf("%0.1d%s%0.2d%s%0.2d",
                    $self->{local_c}{hour},   $sep,
                    $self->{local_c}{minute}, $sep,
                    $self->{local_c}{second} );
}
# don't want to override CORE::time()
*DateTime::Calendar::FrenchRevolutionary::time = \&hms;

sub iso8601 {
  my $self = shift;
  return join 'T', $self->ymd, $self->hms(':');
}
*datetime = \&iso8601;

sub is_leap_year { $_[0]->_is_leap_year($_[0]->year) }

sub decade_number {
  my $self = shift;
  return 3 * $self->month + int(($self->day - 1) / 10) - 2;
}
*week_number = \&decade_number;

sub decade {
  my $self = shift;
  return ($self->year, $self->decade_number);
}
*week = \&decade;

#sub time_zone { $_[0]->{tz} }

sub offset { $_[0]->{tz}->offset_for_datetime($_[0]) }
sub _offset_from_local_time { $_[0]->{tz}->offset_for_local_datetime($_[0]) }

#sub is_dst { $_[0]->{tz}->is_dst_for_datetime($_[0]) }

#sub time_zone_short_name { $_[0]->{tz}->short_name_for_datetime($_[0]) }

sub locale { $_[0]->{locale} }

sub utc_rd_values { @{ $_[0] }{ 'utc_rd_days', 'utc_rd_secs', 'rd_nano' } }

# Anglo-Babylonian time
sub   utc_rd_as_abt_seconds    { ($_[0]->{utc_rd_days}   * 86400) + $_[0]->{utc_rd_secs} }
sub local_rd_as_abt_seconds    { ($_[0]->{local_rd_days} * 86400) + $_[0]->{local_rd_secs} }
sub    _time_as_abt_seconds    { $_[1] * 3600 + $_[2] * 60 + $_[3] }
sub _abt_seconds_as_components { int($_[1] / 3600), int($_[1] % 3600 / 60), $_[1] % 60 }

# Decimal time
sub _time_as_seconds { .864 * ($_[1] * 10000 + $_[2] * 100 + $_[3]) }
sub _seconds_as_components { 
  my $sec = int(.5 + $_[1] / .864); 
  int($sec / 10000), int($sec % 10000 / 100), $sec % 100 
}

# RD 1 is JD 1,721,424.5 - a simple offset
sub jd {
  my $self = shift;
  my $jd = $self->{utc_rd_days} + 1_721_424.5;
  return $jd + ($self->{utc_rd_secs} / 86400);
}

sub mjd { $_[0]->jd - 2_400_000.5 }

my %formats = (
        'a' => sub { $_[0]->day_abbr }
      , 'A' => sub { $_[0]->day_name }
      , 'b' => sub { $_[0]->month_abbr }
      , 'B' => sub { $_[0]->month_name }
      , 'c' => sub { $_[0]->strftime( $_[0]->{locale}->default_datetime_format ) }
      , 'C' => sub { int($_[0]->year / 100) }
      , 'd' => sub { sprintf '%02d', $_[0]->day_of_month }
      , 'D' => sub { $_[0]->strftime('%m/%d/%y') }
      , 'e' => sub { sprintf('%2d', $_[0]->day_of_month) }
      , 'f' => sub { sprintf('%2d', $_[0]->month) }
      , 'F' => sub { $_[0]->ymd('-') }
      , 'g' => sub { substr($_[0]->year, -2) }
      , 'G' => sub { sprintf '%04d', $_[0]->year }
      , 'h' => sub { $_[0]->month_abbr }
      , 'H' => sub { sprintf('%d', $_[0]->hour) }
      , 'I' => sub { my $h = $_[0]->hour || 10; sprintf('%d', $h) }
      , 'j' => sub { sprintf '%03d', $_[0]->day_of_year }
      , 'k' => sub { sprintf('%2d', $_[0]->hour) }
      , 'l' => sub { my $h = $_[0]->hour || 10; sprintf('%2d', $h) }
      , 'L' => sub { sprintf '%04d', $_[0]->year }
      , 'm' => sub { sprintf '%02d', $_[0]->month }
      , 'M' => sub { sprintf '%02d', $_[0]->minute }
      , 'n' => sub { "\n" } # should this be OS-sensitive?
      , 'p' => sub {    $_[0]->{locale}->am_pm($_[0]) }
      , 'P' => sub { lc $_[0]->{locale}->am_pm($_[0]) }
      , 'r' => sub { $_[0]->strftime('%I:%M:%S %p') }
      , 'R' => sub { $_[0]->strftime('%H:%M') }
      , 's' => sub { $_[0]->epoch }
      , 'S' => sub { sprintf('%02d', $_[0]->second) }
      , 't' => sub { "\t" }
      , 'T' => sub { $_[0]->strftime('%H:%M:%S') }
      , 'u' => sub { sprintf '%2d', $_[0]->day_of_decade },
      , 'U' => sub { $_[0]->decade_number }
      , 'V' => sub { $_[0]->decade_number }
      , 'w' => sub { $_[0]->day_of_decade % 10 }
      , 'W' => sub { $_[0]->decade_number }
      , 'y' => sub { sprintf('%02d', substr( $_[0]->year, -2 )) }
      , 'Y' => sub { sprintf '%04d', $_[0]->year }
      , 'z' => sub { DateTime::TimeZone::offset_as_string( $_[0]->offset ) }
      , 'Z' => sub { $_[0]->{tz}->short_name_for_datetime($_[0]) }
      , '+' => sub { '+' }
      , '%' => sub { '%' }
      , 'EY' => sub { Roman $_[0]->year || $_[0]->year }
      , 'Ey' => sub { roman $_[0]->year || $_[0]->year }
      , '*'  => sub { $_[0]->feast_long }
      , 'Ej' => sub { $_[0]->feast_long }
      , 'EJ' => sub { $_[0]->feast_caps }
      , 'Oj' => sub { $_[0]->feast_short }

    );

$formats{h} = $formats{b};

sub strftime {
  my $self = shift;
  # make a copy or caller's scalars get munged
  my @formats = @_;

  my @r;
  foreach my $f (@formats)
    {
      # regex from DateTime from Date::Format - thanks Graham and Dave!
      # but there is a twist: 3-char format specifiers such as '%Ey' are
      # allowed. All 3-char specifiers begin with a '%E' or '%O' prefix.
      # At the same time, if the user wants %Em or %Om, which do not exist, it defaults to %m
      # And if the user asks for %E!,
      # it defaults to E! because neither %E! nor %! exist.
      $f =~ s/
                \%([EO]?([*%a-zA-Z]))
              | \%\{(\w+)\}
             /
              $3 ? ($self->can($3) ? $self->$3() : "\%{$3}")
                 : ($formats{$1} ? $formats{$1}->($self)
                             : $formats{$2} ? $formats{$2}->($self) : $1)
             /sgex;
      return $f unless wantarray;
      push @r, $f;
    }
  return @r;
}

sub epoch {
  my $self = shift;
  my $greg = DateTime->from_object(object => $self);
  return $greg->epoch;
}

sub DefaultLocale {
  'fr'
}

#my %events = ();
sub on_date {
  my ($dt, $lan) = @_;
  my $locale;

  if (defined $lan)
    { $locale = DateTime::Calendar::FrenchRevolutionary::Locale->load( $lan )}
  else
    { $locale = $dt->{locale} }
  return $locale->on_date($dt);

}

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Liberté, égalité, fraternité
ou la mort !";

__END__

=encoding utf8

=head1 NAME

DateTime::Calendar::FrenchRevolutionary - Dates in the French Revolutionary Calendar

=head1 SYNOPSIS

  use DateTime::Calendar::FrenchRevolutionary;

  # Use the date "18 Brumaire VIII" (Brumaire being the second month)
  $dt = DateTime::Calendar::FrenchRevolutionary->new( year  =>  8,
                                                      month =>  2,
                                                      day   => 18,
                                       );

  # convert from French Revolutionary to Gregorian...
  $dtgreg = DateTime->from_object( object => $dt );

  # ... and back again
  $dtrev = DateTime::Calendar::FrenchRevolutionary->from_object( object => $dtgreg );

=head1 DESCRIPTION

DateTime::Calendar::FrenchRevolutionary    implements    the    French
Revolutionary  Calendar.   This  module  implements  most  methods  of
DateTime; see the DateTime(3) manpage for all methods.

=head1 HISTORICAL NOTES

=head2 Preliminary Note

The documentation  uses the  word I<décade> (the  first "e"  having an
acute  accent). This  French word  is  I<not> the  translation of  the
English  word  "decade"  (ten-year  period).  It  means  a  ten-I<day>
period.

For  your  information, the  French  word  for  a ten-year  period  is
I<décennie>.

=head2 Description

The Revolutionary calendar was in  use in France from 24 November 1793
(4 Frimaire  II) to 31  December 1805 (10  Nivôse XIV). An  attempt to
apply  the  decimal rule  (the  basis of  the  metric  system) to  the
calendar. Therefore, the week  disappeared, replaced by the décade. In
addition, all months have exactly 3 décades, no more, no less.

At first,  the year was  beginning on the  equinox of autumn,  for two
reasons.  First, the  republic had  been established  on  22 September
1792, which  happened to be the  equinox, and second,  the equinox was
the symbol of equality, the day and the night lasting exactly 12 hours
each. It  was therefore  in tune with  the republic's  motto "Liberty,
Equality, Fraternity". But  it was not practical, so  Romme proposed a
leap year rule similar to the Gregorian calendar rule.

In his book I<The French Revolution>, the XIXth century writer Thomas
Carlyle proposes these translations for the month names:

=over 4

=item Vendémiaire -> Vintagearious

=item Brumaire -> Fogarious

=item Frimaire -> Frostarious

=item Nivôse -> Snowous

=item Pluviôse -> Rainous

=item Ventôse -> Windous

=item Germinal -> Buddal

=item Floréal -> Floweral

=item Prairial -> Meadowal

=item Messidor -> Reapidor

=item Thermidor -> Heatidor

=item Fructidor -> Fruitidor

=back

Each month has  a duration of 30 days. Since a  year lasts 365.25 days
(or so), five  additional days (or six on leap  years) are added after
Fructidor. These days  are called I<Sans-Culottides>.  For programming
purposes, they are  considered as a 13th month  (much shorter than the
12 others).

There was also an attempt to decimalize the day's subunits, with 1 day
= 10 hours, 1 hour = 100 minutes and 1 minute = 100 seconds.  But this
reform was put on hold after two years or so and it never reappeared.

Other reforms to decimalize the time has been proposed during the last
part of  the XIXth  Century, but these  reforms were not  applied too.
And they are irrelevant for this French Revolutionary calendar module.

=head1 METHODS

Since  the week  has been  replaced by  the décade,  the corresponding
method  names  still   are  C<decade_number>,  C<day_of_decade>,  etc.
English  speakers, please  note that  this has  nothing to  do  with a
10-year period.

The module supports both  Anglo-Babylonian time (24x60x60) and decimal
time.    The  accessors  for   ABT  are   C<abt_hour>,  C<abt_minute>,
C<abt_second>  and  C<abt_hms>, the  accessors  for  decimal time  are
C<hour>,  C<minute>,   C<second>  and  C<hms>.   The  C<strftime>  and
C<iso8601>  methods use  only  decimal time.   The  ABT accessors  are
provided to be historically correct, since the decimal time reform was
never put  in force. Yet,  emphasis is on  decimal time because  it is
more fun than sexagesimal time,  which anyhow can be obtained with the
standard Gregorian C<DateTime.pm> module.

=head2 Constructors

=over 4

=item * new(...)

Creates a new date object. This class accepts the following parameters:

=over 4

=item * C<year>

Year  number, mandatory. Year  1 corresponds  to Gregorian  years late
1792 and early 1793.

=item * C<month>

Month  number, in the  range 1..12,  plus number  13 to  designate the
end-of-year additional days.

=item * C<day>

Day number,  in the range 1..30.  In the case of  additional days, the
range is 1..5 or 1..6 depending on the year (leap year or normal).

=item * C<hour>, C<minute>, C<second>

Decimal hour number, decimal  minute number and decimal second number.
The hour is in the 0..9  range, both other parameters are in the 0..99
range. These parameters cannot  be specified with the sexagesimal time
parameters C<abt_>I<xxx> (see below).

=item * C<abt_hour>, C<abt_minute>, C<abt_second>

Sexagesimal  hour number,  sexagesimal minute  number  and sexagesimal
second number.  The hour is  in the 0..23 range, both other parameters
are in the 0..59 range.  These parameters cannot be specified with the
decimal time parameters (see above).

=item * C<locale>

Only the values  C<fr> (French), C<en> (English),  C<es> (Spanish) and
C<it> (Italian)  are allowed. Default  is French. No other  values are
possible, even territory variants such as C<fr_BE> or C<en_US>.

=back

=item * from_epoch( epoch => $epoch )

Creates a  date object from a  timestamp value. This  timestamp is the
number of seconds since the computer epoch, not the calendar epoch.

=item * now( )

Creates  a date  object that  corresponds to  the precise  instant the
method is called.

=item * from_object( object => $object, ... )

Creates a date  object by converting another object  from the DateTime
suite.  The preferred way for calendar to calendar conversion.

=item * last_day_of_month( ... )

Same as C<new>,  except that the C<day> parameter  is forbidden and is
automatically set to  the end of the month.  If the C<month> parameter
is 13 for the additional days, the  day is set to the end of the year,
either the 5th or the 6th additional day.

=item * clone

Creates a replica of the original date object.

=item * set( .. )

This method can be used to change the local components of a date time,
or  its locale.   This method  accepts  any parameter  allowed by  the
C<new()> method.

This  method performs  parameters validation  just as  is done  in the
C<new()> method.

=back

=head2 Accessors

=over 4

=item * year

Returns the year. C<%Y> or C<%G> in C<strftime>.

=item * month

Returns the month in the 1..12 range. If the date is an additional day
at  the end  of the  year, returns  13, which  is not  really  a month
number. C<%m> or C<%f> in C<strftime>.

=item * month_0

Returns the month in the 0..11 range. If the date is an additional day
at the end of the year, returns 12, which is not really a month number.

=item * month_name

Returns the  French name of the  month or its  English translation. No
other language is  supported yet.  For the additional  days at the end
of  the  year,  returns  "jour  complémentaire",  the  translation  of
"additional day". C<%B> in C<strftime>.

Note: The  English translations for  the month names come  from Thomas
Carlyle's book.

=item * month_abbr

Returns a 3-letter abbreviation of  the month name. For the additional
days at the  end of the year, returns  "S-C", because these additional
days  were also  known as  the I<Sans-culottides>.  C<%b> or  C<%h> in
C<strftime>.

=item * day_of_month, day, mday

Returns the day of the month, from 1..30. C<%d> or C<%e> in C<strftime>.

=item * day_of_decade, dod, day_of_week, dow, wday

Returns the day of the I<décade>,  from 1..10. The C<dow>, C<wday> and
C<day_of_week>  names   are  there   for  compatibility's   sake  with
C<DateTime>,  even   if  the  word   "week"  is  improper.   C<%u>  in
C<strftime>, but not C<%w> (because the value differs on I<décadi>).

=item * day_name

Returns  the  name of  the  current day  of  the  I<décade>. C<%A>  in
C<strftime>.

=item * day_abbr

Returns   the   abbreviated  name   of   the   current   day  of   the
I<décade>. C<%a> in C<strftime>.

=item * day_of_year, doy

Returns the day of the year. C<%j> in C<strftime>.

=item * feast, feast_short, feast_long, feast_caps

Returns the  plant, animal, mineral  or tool associated with  the day.
The  default format is  C<short>. If  requested, you  can ask  for the
C<long> format,  with a C<jour  de...> prefix, or the  C<caps> format,
with the first  letter of the prefix and  feast capitalized.  Example:
for 11 Vendémiaire, we have:

   feast, feast_short  pomme de terre
   feast_long          jour de la pomme de terre
   feast_caps          Jour de la Pomme de terre

C<%Ej>, C<%EJ>, C<%Oj> or C<%*> in C<strftime>.

Note: the  English translation for  the feasts comes mainly  from Alan
Taylor's website "Preserving the French Republican Calendar".

=item * ymd, dmy, mdy

Returns the  date in the  corresponding composite format.  An optional
parameter  allows  you  to  choose  the  separator  between  the  date
elements. C<%F> in C<strftime>.

=item * abt_hour, abt_minute, abt_min, abt_second, abt_sec

Return  the corresponding  time elements,  using a  sexagesimal scale.
This is also sometimes known as the I<Anglo-Babylonian Time>.

=item * hour, minute, min, second, sec

Return the corresponding time elements, using a decimal scale, with 10
hours per day, 100 minutes per hour and 100 seconds per minute. C<%H>,
C<%M> and C<%S> in C<strftime>.

=item * abt_hms

Returns  a composite  string with  the three  time elements.  Uses the
I<Anglo-Babylonian Time>.  An optional  parameter allows you to choose
the separator (C<:> by default).

=item * hms

Returns  a composite  string with  the three  time elements.  Uses the
decimal  time.   An  optional  parameter  allows  you  to  choose  the
separator (C<:> by default).

=item * iso8601

Returns the  date and time  is a format  similar to what  ISO-8601 has
specified for the Gregorian calendar.

=item * is_leap_year

Returns a true value if the year is a leap year, false else.

=item * decade_number, week_number

Returns the I<décade> number. C<%U>, C<%V> or C<%W> in C<strftime>.

=item * decade, week

Returns a 2-element list, with  the year number and the décade number.
Since the  I<décade> is always  aligned with a  month and then  with a
year, the year element is always the same as the date's year.  Anyhow,
this is done for compatibility with DateTime's C<week> method.

=item * utc_rd_values

Returns the  current UTC Rata Die  days, seconds and  nanoseconds as a
3-element list.  This exists primarily to allow other calendar modules
to create objects based on the values provided by this object.

=item * jd, mjd

These  return the Julian  Day and  Modified Julian  Day, respectively.
The value returned is a floating point number.  The fractional portion
of the number represents the time portion of the datetime.

=item * utc_rd_as_seconds

Returns the current UTC Rata Die days and seconds purely as seconds.
This is useful when you need a single number to represent a date.

=item * local_rd_as_seconds

Returns the current local Rata Die days and seconds purely as seconds.

=item * strftime( $format, ... )

This  method  implements functionality  similar  to the  C<strftime()>
method in C.  However, if  given multiple format strings, then it will
return multiple elements, one for each format string.

See the L<strftime Specifiers|/strftime Specifiers> section for a list
of all possible format specifiers.

=item * epoch

Return the UTC epoch value  for the datetime object.  Internally, this
is  implemented  C<epoch>  from   C<DateTime>,  which  in  turn  calls
C<Time::Local>,  which uses  the Unix  epoch even  on machines  with a
different epoch (such  as Mac OS).  Datetimes before  the start of the
epoch will be returned as a negative number.

Since epoch times cannot represent  many dates on most platforms, this
method may simply return undef in some cases.

Using your system's  epoch time may be error-prone,  since epoch times
have such a limited range  on 32-bit machines.  Additionally, the fact
that different  operating systems  have different epoch  beginnings is
another source of bugs.

=item * on_date

Gives  a  few historical  events  that took  place  on  the same  date
(day+month, irrespective of the  year).  These events occur during the
period of use  of the calendar, that is, no  later than Gregorian year
1805. The  related  events either  were  located  in  France, or  were
battles in which a French army was involved.

This  method accepts  one  optional argument,  the  language. For  the
moment, only  "en" for English and  "fr" for French  are available. If
not given, the method will use the date object's current locale.

Not all eligible events are portrayed there. The events database will
be expanded in future versions.

Most  military events  are extracted  from I<Calendrier  Militaire>, a
book written by an anonymous author in VII (1798) or so. I guess there
is  no longer  any  copyright attached.  Please  note that  this is  a
propaganda  book, which  therefore gives  a  very biased  view of  the
events.

=back

=head2 strftime Specifiers

The following specifiers are allowed in the format string given to the
C<strftime()> method:

=over 4

=item * %a

The abbreviated day of I<décade> name.

=item * %A

The full day of I<décade> name.

=item * %b

The abbreviated month name, or 'S-C' for additional days (abbreviation
of I<Sans-culottide>, another name for these days).

=item * %B

The full month name.

=item * %c

The date-time,  using the  default format, as  defined by  the current
locale.

=item * %C

The century number (year/100) as a 2-digit integer.

=item * %d

The day of the month as a decimal number (range 01 to 30).

=item * %D

Equivalent to  %m/%d/%y.  This  is not a  good standard format  if you
have want both Americans and  Europeans (and others) to understand the
date!

=item * %e

Like %d, the day of the month  as a decimal number, but a leading zero
is replaced by a space.

=item * %f

The month as a decimal number (1  to 13). Unlike %m, a leading zero is
replaced by a space.

=item * %F

Equivalent to %Y-%m-%d (the ISO 8601 date format)

=item * %g

Strictly similar to  %y, since I<décades> are always  aligned with the
beginning of the year in this calendar.

=item * %G

Strictly similar to  %Y, since I<décades> are always  aligned with the
beginning of the year in this calendar.

=item * %h

Equivalent to %b.

=item * %H

The hour as a decimal number using a 10-hour clock (range 0 to 9).
The result is a single-char string.

=item * %I

The hour  as a decimal number  using the numbers on  a clockface, that
is, range 1 to 10. The result is a single-char string, except for 10.

=item * %j

The day of the year as a decimal number (range 001 to 366).

=item * %Ej

The feast for  the day, in long format ("jour de  la pomme de terre").
Also available as %*.

=item * %EJ

The feast for  the day, in capitalised long format  ("Jour de la Pomme
de terre").

=item * %Oj

The feast for the day, in short format ("pomme de terre").

=item * %k

The  hour (10-hour  clock) as  a decimal  number (range  0 to  9); the
result is a 2-char string, the digit is preceded by a blank. (See also
%H.)

=item * %l

The hour  as read from a  clockface (range 1  to 10). The result  is a
2-char string, the digit is preceded  by a blank, except of course for
10. (See also %I.)

=item * %L

The year as  a decimal number including the  century. Strictly similar
to %Y and %G.

=item * %m

The month as a decimal number (range 01 to 13).

=item * %M

The minute as a decimal number (range 00 to 99).

=item * %n

A newline character.

=item * %p

Either  `AM'  or  `PM' according  to  the  given  time value,  or  the
corresponding strings for the current locale.  Noon is treated as `pm'
and midnight as `am'.

=item * %P

Like %p but in lowercase: `am' or `pm' or a corresponding string for
the current locale.

=item * %r

The decimal time in a.m.  or  p.m. notation.  In the POSIX locale this
is equivalent to `%I:%M:%S %p'.

=item * %R

The  decimal time  in 10-hour  notation  (%H:%M). (SU)  For a  version
including the seconds, see %T below.

=item * %s

The number of seconds since the epoch.

=item * %S

The second as a decimal number (range 00 to 99).

=item * %t

A tab character.

=item * %T

The decimal time in 10-hour notation (%H:%M:%S).

=item * %u

The day of the I<décade> as a  decimal, range 1 to 10, Primidi being 1
and Décadi being 10.  See also %w.

=item * %U

The I<décade> number of the current year as a decimal number, range 01
to 37.

=item * %V

The  I<décade>  number (French  Revolutionary  equivalent  to the  ISO
8601:1988 week number) of the current  year as a decimal number, range
01 to  37. Identical to C<%U>,  since I<décades> are aligned  with the
beginning of the year.

=item * %w

The day of the  I<décade> as a decimal, range 0 to  9, Décadi being 0.
See also %u.

=item * %W

The I<décade> number of the current year as a decimal number, range 00
to 37. Strictly similar to %U and %V.

=item * %y

The year as a decimal number without a century (range 00 to 99).

=item * %Y

The year as a decimal number including the century.

=item * %Ey

The year as a lowercase Roman number.

=item * %EY

The year as a uppercase Roman  number, which is the traditional way to
write years when using the French Revolutionary calendar.

=item * %z

The   time-zone  as   hour  offset   from  UTC.    Required   to  emit
RFC822-conformant dates (using "%a, %d %b %Y %H:%M:%S %z").  Since the
module does not  support time zones, this gives  silly results and you
cannot  be RFC822-conformant.  Anyway,  RFC822 requires  the Gregorian
calendar, doesn't it?

=item * %Z

The  time  zone  or  name  or abbreviation,  should  the  module  have
supported them.

=item * %*

The feast for the day, in long format ("jour de la pomme de terre").
Also available as %Ej.

=item * %%

A literal `%' character.

=back

=head1 PROBLEMS AND KNOWN BUGS

=head2 Time Zones

Only the I<floating> time zone  is supported.  Time zones were created
in  the  late  XIXth  century,  at  a  time  when  fast  communication
(railroads)  and instant  communication (electric  telegraph)  made it
necessary.  But at this time, the French Revolutionary calendar was no
longer in use.

=head2 Leap Seconds

They are not supported.

=head2 I18N

For  the  moment,  only  French,  English,  Spanish  and  Italian  are
available. For the  English translation, I have  used Thomas Carlyle's
book and Alan  Taylor's web site at kokogiak.com (see  below). Then, I
have checked  some translations  with Wikipedia and  Jonathan Badger's
French Revolutionary Calendar module written in Ruby.

Some feast names are not translated, other's translations are doubtful
(they are flagged with a question mark).  Remarks are welcome.

=head2 Feasts

The various  sources for  the feasts  are somewhat  contradictory. The
most obvious  example if  the 4th  additional day,  which is  "Jour de
l'opinion" (day of opinion) in some  documents and "Jour de la raison"
(day of reason) in others.

In addition, the sources have several slight differences between them.
All of  them obviously include some  typos. [Annexe] is chosen  as the
reference since it is the  definitive legislative text that officially
defines names of days in  the French revolutionary calendar. This text
introduces  amendments  to  the  original calendar  set  up  by  Fabre
d'Églantine in [Fabre], and gives  in annex the amended calendar. When
there is  a difference between  the amended calendar and  [Fabre] with
amendments  (yes it  can happen!),  [Fabre] version  prevails. Obvious
typos  in  [Annexe] (yes  it  can  happen!)  are preserved,  with  the
exception  of accented  letters  because they  are  fuzzy rendered  in
original prints, or  cannot be printed at all at  that time on letters
in uppercase.

The bracket  references refer  to entries in  the "SEE  ALSO" section,
"Internet" subsection below.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<https://lists.perl.org/> for more details.

Please   report  any   bugs   or  feature   requests   to  Github   at
L<https://github.com/jforget/DateTime-Calendar-FrenchRevolutionary>,
and create an issue or submit a pull request.

If you have no  feedback after a week or so, try to  reach me by email
at JFORGET  at cpan  dot org.  The notification  from Github  may have
failed to reach  me. In your message, please  mention the distribution
name in the subject, so my spam  filter and I will easily dispatch the
email to the proper folder.

On the other  hand, I may be  on vacation or away from  Internet for a
good  reason. Do  not be  upset if  I do  not answer  immediately. You
should write  me at a leisurely  rythm, about once per  month, until I
react.

If after about six  months or a year, there is  still no reaction from
me, you can worry and start the CPAN procedure for module adoption.
See L<https://groups.google.com/g/perl.module-authors/c/IPWjASwuLNs>
L<https://www.cpan.org/misc/cpan-faq.html#How_maintain_module>
and L<https://www.cpan.org/misc/cpan-faq.html#How_adopt_module>.


=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

based  on  Dave  Rolsky's  DateTime  module, Eugene  van  der  Pijll's
DateTime::Calendar::Pataphysical      module     and      my     prior
Date::Convert::French_Rev module.

The development of this module is hosted by I<Les Mongueurs de Perl>,
L<http://www.mongueurs.net/>.

=head2 THANKS

Many thanks to those who sent me a RT ticket or a pull request:

=over 4

=item * The late Iain Truskett,

=item * Philippe Bruhat (BooK)

=item * Slaven Rezić

=item * and  especially Gérald Sédrati-Dinet (GIBUS at  cpan dot org),
for  his thorough  documentation  research  and for  his  work on  the
Spanish and Italian locales.

=back

Also,  many thanks  to all  the  persons who  gave me  advices on  the
DateTime mailing list. I will not mention them, because I might forget
some of them.

=head1 SEE ALSO

=head2 Perl Software

date(1), strftime(3), perl(1)

L<DateTime>

L<DateTime::Calendar::Pataphysical>

L<Date::Convert::French_Rev> or L<https://github.com/jforget/Date-Convert-French_Rev>

L<Date::Converter>

=head2 Other Software

F<calendar/cal-french.el>  in emacs-21.2  or later  or xemacs  21.1.8,
forked in L<https://github.com/jforget/emacs-lisp-cal-french>

=head2 Books

Quid 2001, M and D Frémy, publ. Robert Laffont

Agenda Républicain 197 (1988/89), publ. Syros Alternatives

Any French schoolbook about the French Revolution

The French Revolution, Thomas Carlyle, Oxford University Press

Calendrier Militaire, anonymous

Histoire de l'heure en France, Jacques Gapaillard, publ. Vuibert -- ADAPT

=head2 Internet

L<https://github.com/houseabsolute/DateTime.pm/wiki>

L<http://www.faqs.org/faqs/calendars/faq/part3/>

L<https://zapatopi.net/metrictime/>

L<http://datetime.mongueurs.net/>

L<https://www.allhotelscalifornia.com/kokogiakcom/frc/default.asp>

L<https://github.com/jhbadger/FrenchRevCal-ruby>

L<https://en.wikipedia.org/wiki/French_Republican_Calendar>

L<https://fr.wikipedia.org/wiki/Calendrier_républicain>

L<https://archive.org/details/decretdelaconven00fran_40>

"Décret  du  4 frimaire,  an  II  (24  novembre  1793) sur  l'ère,  le
commencement et l'organisation de l'année et sur les noms des jours et
des mois"

L<https://archive.org/details/decretdelaconven00fran_41>

Same text, with a slightly different typography.

L<https://purl.stanford.edu/dx068ky1531>

"Archives parlementaires  de 1789 à  1860: recueil complet  des débats
législatifs & politiques  des Chambres françaises", J.  Madival and E.
Laurent, et. al.,  eds, Librairie administrative de  P. Dupont, Paris,
1912.

Starting with  page 6,  this document  includes the  same text  as the
previous links, with  a much improved typography.  Especially, all the
"long s"  letters have been replaced  by short s. Also  interesting is
the text  following the  decree, page 21  and following:  "Annuaire ou
calendrier pour la seconde année de la République française, annexe du
décret  du  4  frimaire,  an  II (24  novembre  1793)  sur  l'ère,  le
commencement et l'organisation de l'année et sur les noms des jours et
des mois". In the remarks above, it is refered as [Annexe].

L<https://gallica.bnf.fr/ark:/12148/bpt6k48746z>

[Fabre] "Rapport fait à la Convention nationale dans la séance du 3 du
second mois de la seconde année  de la République française, au nom de
la   Commission    chargée   de   la   confection    du   calendrier",
Philippe-François-Nazaire  Fabre  d'Églantine,  Imprimerie  nationale,
Paris, 1793

L<https://gallica.bnf.fr/ark:/12148/bpt6k49016b>

[Annuaire] "Annuaire  du cultivateur,  pour la  troisième année  de la
République  : présenté  le  30 pluviôse  de l'an  II  à la  Convention
nationale, qui en  a décrété l'impression et l'envoi,  pour servir aux
écoles  de la  République",  Gilbert Romme,  Imprimerie nationale  des
lois, Paris, 1794-1795

L<https://gallica.bnf.fr/ark:/12148/bpt6k43978x>

"Calendrier militaire,  ou tableau  sommaire des  victoires remportées
par les  Armées de  la République française,  depuis sa  fondation (22
septembre 1792),  jusqu'au 9  floréal an  7, époque  de la  rupture du
Congrès de Rastadt et de la reprise des hostilités" Moutardier, Paris,
An  VIII de  la République  française.  The source  of the  C<on_date>
method.

=head1 LICENSE STUFF

Copyright  (c) 2003,  2004, 2010,  2012, 2014,  2016, 2019,  2021 Jean
Forget. All  rights reserved. This  program is free software.  You can
distribute,    adapt,    modify,     and    otherwise    mangle    the
DateTime::Calendar::FrenchRevolutionary module under the same terms as
perl 5.16.3.

This program is  distributed under the same terms  as Perl 5.16.3: GNU
Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You should  have received  a copy  of the  GNU General  Public License
along with this program;  if not, see L<https://www.gnu.org/licenses/>
or contact the Free Software Foundation, Inc., L<https://www.fsf.org>.

=cut
