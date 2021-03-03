package Date::Manip::Base;
# Copyright (c) 1995-2021 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################
# Any routine that starts with an underscore (_) is NOT intended for
# public use.  They are for internal use in the the Date::Manip
# modules and are subject to change without warning or notice.
#
# ABSOLUTELY NO USER SUPPORT IS OFFERED FOR THESE ROUTINES!
###############################################################################

require 5.010000;
use strict;
use warnings;
use integer;
use utf8;
#use re 'debug';

use Date::Manip::Obj;
use Date::Manip::TZ_Base;
our @ISA = qw(Date::Manip::Obj Date::Manip::TZ_Base);

use Encode qw(encode_utf8 from_to find_encoding decode _utf8_off _utf8_on is_utf8);
require Date::Manip::Lang::index;

our $VERSION;
$VERSION='6.85';
END { undef $VERSION; }

###############################################################################
# BASE METHODS
###############################################################################

sub _init {
   my($self) = @_;

   $self->_init_cache();
   $self->_init_language();
   $self->_init_config();
   $self->_init_events();
   $self->_init_holidays();
   $self->_init_now();

   return;
}

# The base object has some config-independant information which is
# always reused, and only needs to be initialized once.
sub _init_cache {
   my($self) = @_;
   return  if (exists $$self{'cache'}{'init'});
   $$self{'cache'}{'init'}    = 1;

   # ly          => {Y}    = 0/1  1 if it is a leap year
   # ds1_mon     => {Y}{M} = N    days since 1BC for Y/M/1
   # dow_mon     => {Y}{M} = DOW  day of week of Y/M/1

   $$self{'cache'}{'ly'}      = {};
   $$self{'cache'}{'ds1_mon'} = {};
   $$self{'cache'}{'dow_mon'} = {};

   return;
}

# Config dependent data. Needs to be reset every time the config is reset.
sub _init_data {
   my($self,$force) = @_;
   return  if (exists $$self{'data'}{'calc'}  &&  ! $force);

   $$self{'data'}{'calc'}     = {};     # Calculated values

   return;
}

# Initializes config dependent data
sub _init_config {
   my($self,$force) = @_;
   return  if (exists $$self{'data'}{'sections'}{'conf'}  &&  ! $force);
   $self->_init_data();

   #
   # Set config defaults
   #

   $$self{'data'}{'sections'}{'conf'} =
     {
      # Reset config, holiday lists, or events lists

      'defaults'         => '',
      'eraseholidays'    => '',
      'eraseevents'      => '',

      # Which language to use when parsing dates.

      'language'         => '',

      # 12/10 = Dec 10 (US) or Oct 12 (anything else)

      'dateformat'       => '',

      # Define the work week (1=monday, 7=sunday)
      #
      # These have to be predefined to avoid a bootstrap issue, but
      # the true defaults are defined below.

      'workweekbeg'      => 1,
      'workweekend'      => 5,

      # If non-nil, a work day is treated as 24 hours long
      # (WorkDayBeg/WorkDayEnd ignored)

      'workday24hr'      => '',

      # Start and end time of the work day (any time format allowed,
      # seconds ignored). If the defaults change, be sure to change
      # the starting value of bdlength above.

      'workdaybeg'       => '',
      'workdayend'       => '',

      # 2 digit years fall into the 100 year period given by [ CURR-N,
      # CURR+(99-N) ] where N is 0-99.  Default behavior is 89, but
      # other useful numbers might be 0 (forced to be this year or
      # later) and 99 (forced to be this year or earlier).  It can
      # also be set to 'c' (current century) or 'cNN' (i.e.  c18
      # forces the year to bet 1800-1899).  Also accepts the form
      # cNNNN to give the 100 year period NNNN to NNNN+99.

      'yytoyyyy'         => '',

      # First day of the week (1=monday, 7=sunday).  ISO 8601 says
      # monday.

      'firstday'         => '',

      # If this is 0, use the ISO 8601 standard that Jan 4 is in week
      # 1.  If 1, make week 1 contain Jan 1.

      'jan1week1'        => '',

      # Date::Manip printable format
      #   0 = YYYYMMDDHH:MN:SS
      #   1 = YYYYHHMMDDHHMNSS
      #   2 = YYYY-MM-DD-HH:MN:SS

      'printable'        => '',

      # If 'today' is a holiday, we look either to 'tomorrow' or
      # 'yesterday' for the nearest business day.  By default, we'll
      # always look 'tomorrow' first.

      'tomorrowfirst'    => 1,

      # Used to set the current date/time/timezone.

      'forcedate'        => 0,
      'setdate'          => 0,

      # Use this to set the default range of the recurrence.

      'recurrange'       => '',
      'maxrecurattempts' => 100,

      # Use this to set the default time.

      'defaulttime'      => 'midnight',

      # Whether or not to use a period as a time separator.

      'periodtimesep'    => 0,

      # How to parse mmm#### strings

      'format_mmmyyyy'   => '',

      # *** DEPRECATED 7.0 ***

      'tz'               => '',
     };

   #
   # Calculate delta field lengths
   #

   # non-business
   $$self{'data'}{'len'}{'standard'} =
     { 'yl'   => 31556952,  # 365.2425 * 24 * 3600
       'ml'   => 2629746,   # yl / 12
       'wl'   => 604800,    # 6 * 24 * 3600
       'dl'   => 86400,     # 24 * 3600
     };
   $self->_calc_workweek();

   #
   # Initialize some config variables that do some additional work.
   #

   $self->_config_var('workday24hr',  1);
   $self->_config_var('workdaybeg',   '08:00:00');
   $self->_config_var('workdayend',   '17:00:00');
   $self->_config_var('workday24hr',  0);

   $self->_config_var('dateformat',   'US');
   $self->_config_var('yytoyyyy',     89);
   $self->_config_var('jan1week1',    0);
   $self->_config_var('printable',    0);
   $self->_config_var('firstday',     1);
   $self->_config_var('workweekbeg',  1);
   $self->_config_var('workweekend',  5);
   $self->_config_var('language',     'english');
   $self->_config_var('recurrange',   'none');
   $self->_config_var('maxrecurattempts', 100);
   $self->_config_var('defaulttime',  'midnight');

   # Set OS specific defaults

   my $os = $self->_os();

   return;
}

sub _calc_workweek {
   my($self,$beg,$end) = @_;

   $beg = $self->_config('workweekbeg')  if (! $beg);
   $end = $self->_config('workweekend')  if (! $end);

   $$self{'data'}{'len'}{'workweek'} = $end - $beg + 1;

   return;
}

sub _calc_bdlength {
   my($self) = @_;

   my @beg = @{ $$self{'data'}{'calc'}{'workdaybeg'} };
   my @end = @{ $$self{'data'}{'calc'}{'workdayend'} };

   $$self{'data'}{'len'}{'bdlength'} =
     ($end[0]-$beg[0])*3600 + ($end[1]-$beg[1])*60 + ($end[2]-$beg[2]);

   return;
}

sub _init_business_length {
   my($self) = @_;

   no integer;
   my $x      = $$self{'data'}{'len'}{'workweek'};
   my $y_to_d = $x/7 * 365.2425;
   my $d_to_s = $$self{'data'}{'len'}{'bdlength'};
   my $w_to_d = $x;

   $$self{'data'}{'len'}{'business'} = { 'yl' => $y_to_d * $d_to_s,
                                         'ml' => $y_to_d * $d_to_s / 12,
                                         'wl' => $w_to_d * $d_to_s,
                                         'dl' => $d_to_s,
                                       };

   return;
}

# Events and holidays are reset only when they are read in.
sub _init_events {
   my($self,$force) = @_;
   return  if (exists $$self{'data'}{'events'}  &&  ! $force);

   # {data}{sections}{events} = [ STRING, EVENT_NAME, ... ]
   #
   # {data}{events}{I}{type}  = TYPE
   #                  {name}  = NAME
   #    TYPE: specified         An event with a start/end date (only parsed once)
   #                  {beg}   = DATE_OBJECT
   #                  {end}   = DATE_OBJECT
   #    TYPE: ym
   #                  {beg}   = YM_STRING
   #                  {end}   = YM_STRING (only for YM;YM)
   #                  {YEAR}  = [ DATE_OBJECT, DATE_OBJECT ]
   #    TYPE: date              An event specified by a date string and delta
   #                  {beg}   = DATE_STRING
   #                  {end}   = DATE_STRING  (only for Date;Date)
   #                  {delta} = DELTA_OBJECT (only for Date;Delta)
   #                  {YEAR}  = [ DATE_OBJECT, DATE_OBJECT ]
   #    TYPE: recur
   #                  {recur} = RECUR_OBJECT
   #                  {delta} = DELTA_OBJECT
   #
   # {data}{eventyears}{YEAR} = 0/1
   # {data}{eventobjs}        = 0/1

   $$self{'data'}{'events'}             = {};
   $$self{'data'}{'sections'}{'events'} = [];
   $$self{'data'}{'eventyears'}         = {};
   $$self{'data'}{'eventobjs'}          = 0;

   return;
}

sub _init_holidays {
   my($self,$force) = @_;
   return  if (exists $$self{'data'}{'holidays'}  &&  ! $force);

   # {data}{sections}{holidays} = [ STRING, HOLIDAY_NAME, ... ]
   #
   # {data}{holidays}{init}     = 1  if holidays have been initialized
   #                 {ydone}    = { Y => 1 }
   #                 {yhols}    = { Y => NAME => [Y,M,D] }
   #                 {hols}     = { NAME => Y => [Y,M,D] }
   #                 {dates}    = { Y => M => D => NAME }
   #                 {defs}     = [ NAME DEF NAME DEF ... ]
   #                                 NAME is the name of a holiday (it will
   #                                 be 'DMunnamed I' for the Ith unnamed
   #                                 holiday)
   #                                 DEF is a string or a Recur
   # {data}{init_holidays}      = 1  if currently initializing holidays

   $$self{'data'}{'holidays'}             = {};
   $$self{'data'}{'sections'}{'holidays'} = [];
   $$self{'data'}{'init_holidays'}        = 0;

   return;
}

sub _init_now {
   my($self) = @_;

   #  {'data'}{'now'} = {
   #                     date     => [Y,M,D,H,MN,S]  now
   #                     isdst    => ISDST
   #                     offset   => [H,MN,S]
   #                     abb      => ABBREV
   #
   #                     force    => 0/1             SetDate/ForceDate information
   #                     set      => 0/1
   #                     setsecs  => SECS            time (secs since epoch) when
   #                                                 SetDate was called
   #                     setdate  => [Y,M,D,H,MN,S]  date (IN GMT) we're calling
   #                                                 now when SetDate was called
   #
   #                     tz       => ZONE            timezone we're working in
   #                     systz    => ZONE            timezone of the system
   #                    }
   #

   $$self{'data'}{'now'}          = {};
   $$self{'data'}{'now'}{'force'} = 0;
   $$self{'data'}{'now'}{'set'}   = 0;
   $$self{'data'}{'tmpnow'}       = [];

   return;
}

# Language information only needs to be initialized if the language changes.
sub _init_language {
   my($self,$force) = @_;
   return  if (exists $$self{'data'}{'lang'}  &&  ! $force);

   $$self{'data'}{'lang'}      = {};     # Current language info
   $$self{'data'}{'rx'}        = {};     # Regexps generated from language
   $$self{'data'}{'words'}     = {};     # Types of words in the language
   $$self{'data'}{'wordval'}   = {};     # Value of words in the language

   return;
}

###############################################################################
# MAIN METHODS
###############################################################################

# Use an algorithm from Calendar FAQ (except that I subtract 305 to get
# Jan 1, 0001 = day #1).
#
sub days_since_1BC {
   my($self,$arg) = @_;

   if (ref($arg)) {
      my($y,$m,$d) = @$arg;
      $m = ($m + 9) % 12;
      $y = $y - $m/10;
      return 365*$y + $y/4 - $y/100 + $y/400 + ($m*306 + 5)/10 + ($d - 1) - 305;
   } else {
      my $g   = $arg + 305;
      no integer;
      my $y   = int((10000*$g + 14780)/3652425);
      use integer;
      my $ddd = $g - (365*$y + $y/4 - $y/100 + $y/400);
      if ($ddd < 0) {
         $y   = $y - 1;
         $ddd = $g - (365*$y + $y/4 - $y/100 + $y/400);
      }
      my $mi  = (100*$ddd + 52)/3060;
      my $mm  = ($mi + 2) % 12 + 1;
      $y      = $y + ($mi + 2)/12;
      my $dd  = $ddd - ($mi*306 + 5)/10 + 1;
      return [$y, $mm, $dd];
   }
}

# Algorithm from the Calendar FAQ
#
sub day_of_week {
   my($self,$date) = @_;
   my($y,$m,$d)    = @$date;

   my $a   = (14-$m)/12;
   $y      = $y-$a;
   $m      = $m + 12*$a - 2;
   my $dow = ($d + $y + $y/4 - $y/100 + $y/400 + (31*$m)/12) % 7;
   $dow    = 7  if ($dow==0);
   return $dow;
}

sub leapyear {
   my($self,$y) = @_;
   return 1  if ( ( ($y % 4 == 0) and ($y % 100 != 0) ) or
                  $y % 400 == 0 );
   return 0;
}

sub days_in_year {
   my($self,$y) = @_;
   return ($self->leapyear($y) ? 366 : 365);
}

# Uses algorithm from:
# http://www.dispersiondesign.com/articles/time/number_of_days_in_a_month
#
sub days_in_month {
   my($self,$y,$m) = @_;
   if (! $m) {
      return (31,29,31,30, 31,30,31,31, 30,31,30,31)  if ($self->leapyear($y));
      return (31,28,31,30, 31,30,31,31, 30,31,30,31);

   } elsif ($m == 2) {
      return 28 + $self->leapyear($y);

   } else {
      return 31 - ($m-1) % 7 % 2;
   }
}

{
   # DinM        =      (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
   my(@doy_days) = ( [0, 31, 59, 90,120,151,181,212,243,273,304,334,365],
                     [0, 31, 60, 91,121,152,182,213,244,274,305,335,366],
                   );


   sub day_of_year {
      my($self,@args) = @_;
      no integer;
      my($n,$ly,$tmp,$remain,$day,$y,$m,$d,$h,$mn,$s,$time);

      if (@args == 2) {
         # $date = day_of_year($y,$day);

         ($y,$tmp) = @args;

         $ly     = $self->leapyear($y);
         $time   = 1  if ($tmp =~ /\./);
         $n      = int($tmp);
         $remain = $tmp - $n;

         # Calculate the month and the day
         for ($m=1; $m<=12; $m++) {
            last  if ($n<=($doy_days[$ly][$m]));
         }
         $d = $n-($doy_days[$ly][$m-1]);
         return [$y,$m,$d]  if (! $time);

         # Calculate the hours, minutes, and seconds into the day.

         $s       = $remain * 86400;
         $mn      = int($s/60);
         $s       = $s - ($mn*60);
         $s       = sprintf('%0.2f',$s)  if ("$s" ne int($s));
         $h       = int($mn/60);
         $mn      = $mn % 60;

         return [$y,$m,$d,$h,$mn,$s];

      } else {
         ($y,$m,$d,$h,$mn,$s) = @{ $args[0] };

         $ly      = ($m > 2 ? $self->leapyear($y) : 0);
         $day     = ($doy_days[$ly][$m-1]+$d);

         return $day  if (! defined $h);

         $day    += ($h*3600 + $mn*60 + $s)/86400;
         return $day;
      }
   }
}

# Can be the nth DoW of year or month (if $m given).  Returns undef if
# the date doesn't exists (i.e. 5th Sunday in a month with only 4).
#
sub nth_day_of_week {
   my($self,$y,$n,$dow,$m) = @_;
   $y += 0;
   $m  = ($m ? $m+0 : 0);

   # $d    is the current DoM (if $m) or DoY
   # $max  is the max value allowed for $d
   # $ddow is the DoW of $d

   my($d,$max,$ddow);

   if ($m) {
      $max = $self->days_in_month($y,$m);
      $d   = ($n<0 ? $max : 1);
      $ddow = $self->day_of_week([$y,$m,$d]);
   } else {
      $max = $self->days_in_year($y);
      $d   = ($n<0 ? $max : 1);
      if ($n<0) {
         $d = $max;
         $ddow = $self->day_of_week([$y,12,31]);
      } else {
         $d = 1;
         $ddow = $self->day_of_week([$y,1,1]);
      }
   }

   # Find the first occurrence of $dow on or after $d (if $n>0)
   # or the last occurrence of $dow on or before $d (if ($n<0);

   if ($dow < $ddow) {
      $d += 7 - ($ddow-$dow);
   } else {
      $d += ($dow-$ddow);
   }
   $d -= 7  if ($d > $max);

   # Find the nth occurrence of $dow

   if ($n > 1) {
      $d += 7*($n-1);
      return undef  if ($d > $max);
   } elsif ($n < -1) {
      $d -= 7*(-1*$n-1);
      return undef  if ($d < 1);
   }

   # Return the date

   if ($m) {
      return [$y,$m,$d];
   }
   return $self->day_of_year($y,$d);
}

{
   # Integer arithmetic doesn't work due to the size of the numbers.
   no integer;
   # my $sec_70 =($self->days_since_1BC([1970,1,1])-1)*24*3600;
   my $sec_70 = 62135596800;

   # Using 'global' variables saves 4%
   my($y,$m,$d,$h,$mn,$s,$sec,$sec_0,$tmp);
   sub secs_since_1970 {
      my($self,$arg) = @_;

      if (ref($arg)) {
         ($y,$m,$d,$h,$mn,$s) = @$arg;
         $sec_0 = ($self->days_since_1BC([$y,$m,$d])-1)*24*3600 + $h*3600 +
           $mn*60 + $s;
         $sec = $sec_0 - $sec_70;
         return $sec;

      } else {
         ($sec)     = $arg;
         $sec_0     = $sec_70 + $sec;
         $tmp       = int($sec_0/24/3600)+1;
         my $ymd    = $self->days_since_1BC($tmp);
         ($y,$m,$d) = @$ymd;
         $sec_0    -= ($tmp-1)*24*3600;
         $h         = int($sec_0/3600);
         $sec_0    -= $h*3600;
         $mn        = int($sec_0/60);
         $s         = $sec_0 - $mn*60;
         return [$y,$m,$d,$h,$mn,$s];
      }
   }
}

sub check {
   my($self,$date) = @_;
   my($y,$m,$d,$h,$mn,$s) = @$date;

   return 0  if (! $self->check_time([$h,$mn,$s])  ||
                 $y<1  ||  $y>9999  ||
                 $m<1  ||  $m>12);

   my $days = $self->days_in_month($y,$m);

   return 0  if ($d<1  ||  $d>$days);
   return 1;
}

sub check_time {
   my($self,$hms) = @_;
   my($h,$mn,$s) = @$hms;

   return 0  if ("$h:$mn:$s" !~ /^\d\d?:\d\d?:\d\d?$/o  ||
                 $h > 24  ||  $mn > 59  ||  $s > 59  ||
                 ($h == 24  &&  ($mn  ||  $s)));
   return 1;
}

sub week1_day1 {
   my($self,$year)  = @_;
   my $firstday  = $self->_config('firstday');
   return $self->_week1_day1($firstday,$year);
}

sub _week1_day1 {
   my($self,$firstday,$year) = @_;
   my $jan1week1 = $self->_config('jan1week1');
   return $$self{'cache'}{'week1day1'}{$firstday}{$jan1week1}{$year}
     if (exists $$self{'cache'}{'week1day1'}{$firstday}{$jan1week1}{$year});

   # First week contains either Jan 4 (default) or Jan 1

   my($y,$m,$d) = ($year,1,4);
   $d           = 1       if ($jan1week1);

   # Go back to the previous (counting today) $firstday

   my $dow = $self->day_of_week([$y,$m,$d]);
   if ($dow != $firstday) {
      $firstday = 0  if ($firstday == 7);
      $d -= ($dow-$firstday);
      if ($d<1) {
         $y--;
         $m = 12;
         $d += 31;
      }
   }

   $$self{'cache'}{'week1day1'}{$firstday}{$jan1week1}{$year} = [ $y,$m,$d ];
   return [$y,$m,$d];
}

sub weeks_in_year {
   my($self,$y)  = @_;
   my $firstday  = $self->_config('firstday');
   return $self->_weeks_in_year($firstday,$y);
}

sub _weeks_in_year {
   my($self,$firstday,$y) = @_;
   my $jan1week1 = $self->_config('jan1week1');
   return $$self{'cache'}{'wiy'}{$firstday}{$jan1week1}{$y}
     if (exists $$self{'cache'}{'wiy'}{$firstday}{$jan1week1}{$y});

   # Get the week1 day1 dates for this year and the next one.
   my ($y1,$m1,$d1) = @{ $self->_week1_day1($firstday,$y) };
   my ($y2,$m2,$d2) = @{ $self->_week1_day1($firstday,$y+1) };

   # Calculate the number of days between them.
   my $diy          = $self->days_in_year($y);
   if ($y1 < $y) {
      $diy += (32-$d1);
   } else {
      $diy -= ($d1-1);
   }
   if ($y2 < $y+1) {
      $diy -= (32-$d2);
   } else {
      $diy += ($d2-1);
   }

   $diy = $diy/7;
   $$self{'cache'}{'wiy'}{$firstday}{$jan1week1}{$y} = $diy;
   return $diy;
}

sub week_of_year {
   my($self,@args) = @_;
   my $firstday    = $self->_config('firstday');
   return $self->_week_of_year($firstday,@args);
}

sub _week_of_year {
   my($self,$firstday,@args) = @_;
   my $jan1week1   = $self->_config('jan1week1');

   if ($#args == 1) {
      # (y,m,d) = week_of_year(y,w)
      my($year,$w) = @args;

      return $$self{'cache'}{'woy1'}{$firstday}{$jan1week1}{$year}{$w}
        if (exists $$self{'cache'}{'woy1'}{$firstday}{$jan1week1}{$year}{$w});

      my $ymd = $self->_week1_day1($firstday,$year);
      $ymd = $self->calc_date_days($ymd,($w-1)*7)  if ($w > 1);

      $$self{'cache'}{'woy1'}{$firstday}{$jan1week1}{$year}{$w} = $ymd;
      return $ymd;
   }

   # (y,w) = week_of_year([y,m,d])
   my($y,$m,$d) = @{ $args[0] };

   # Get the first day of the first week. If the date is before that,
   # it's the last week of last year.

   my($y0,$m0,$d0) = @{ $self->_week1_day1($firstday,$y) };
   if ($y0==$y  &&  $m==1  &&  $d<$d0) {
      return($y-1,$self->_weeks_in_year($firstday,$y-1));
   }

   # Otherwise, we'll figure out how many days are between the two and
   # divide by 7 to figure out how many weeks in it is.

   my $n = $self->day_of_year([$y,$m,$d]);
   if ($y0<$y) {
      $n += (32-$d0);
   } else {
      $n -= ($d0-1);
   }
   my $w = 1+int(($n-1)/7);

   # Make sure we're not into the first week of next year.

   if ($w>$self->_weeks_in_year($firstday,$y)) {
      return($y+1,1);
   }
   return($y,$w);
}

###############################################################################
# CALC METHODS
###############################################################################

sub calc_date_date {
   my($self,$date0,$date1) = @_;

   # Order them so date0 < date1
   # If $minus = 1, then the delta is negative

   my $minus   = 0;
   my $cmp     = $self->cmp($date0,$date1);

   if ($cmp == 0) {
      return [0,0,0];

   } elsif ($cmp == 1) {
      $minus  = 1;
      my $tmp = $date1;
      $date1  = $date0;
      $date0  = $tmp;
   }

   my($y0,$m0,$d0,$h0,$mn0,$s0) = @$date0;
   my($y1,$m1,$d1,$h1,$mn1,$s1) = @$date1;

   my $sameday = ($y0 == $y1  &&  $m0 == $m1  &&  $d0 == $d1  ? 1 : 0);

   # Handle the various cases.

   my($dh,$dm,$ds);
   if ($sameday) {
      ($dh,$dm,$ds) = @{ $self->_calc_hms_hms([$h0,$mn0,$s0],[$h1,$mn1,$s1]) };

   } else {
      # y0-m0-d0 h0:mn0:s0 -> y0-m0-d0 24:00:00
      # y1-m1-d1 h1:mn1:s1 -> y1-m1-d1 00:00:00

      my $t1 = $self->_calc_hms_hms([$h0,$mn0,$s0],[24,0,0]);
      my $t2 = $self->_calc_hms_hms([0,0,0],[$h1,$mn1,$s1]);
      ($dh,$dm,$ds) = @{ $self->calc_time_time($t1,$t2) };

      my $dd0 = $self->days_since_1BC([$y0,$m0,$d0]);
      $dd0++;
      my $dd1 = $self->days_since_1BC([$y1,$m1,$d1]);
      $dh    += ($dd1-$dd0)*24;
   }

   if ($minus) {
      $dh *= -1;
      $dm *= -1;
      $ds *= -1;
   }
   return [$dh,$dm,$ds];
}

sub calc_date_days {
   my($self,$date,$n,$subtract) = @_;
   my($y,$m,$d,$h,$mn,$s)       = @$date;
   my($ymdonly)                 = (defined $h ? 0 : 1);

   $n        *= -1  if ($subtract);
   my $d1bc   = $self->days_since_1BC([$y,$m,$d]);
   $d1bc     += $n;
   my $ymd    = $self->days_since_1BC($d1bc);

   if ($ymdonly) {
      return $ymd;
   } else {
      return [@$ymd,$h*1,$mn*1,$s*1];
   }
}

sub calc_date_delta {
   my($self,$date,$delta,$subtract) = @_;
   my($y,$m,$d,$h,$mn,$s)           = @$date;
   my($dy,$dm,$dw,$dd,$dh,$dmn,$ds) = @$delta;

   ($y,$m,$d) =
     @{ $self->_calc_date_ymwd([$y,$m,$d], [$dy,$dm,$dw,$dd], $subtract) };

   return $self->calc_date_time([$y,$m,$d,$h,$mn,$s],[$dh,$dmn,$ds],$subtract);
}

sub calc_date_time {
   my($self,$date,$time,$subtract) = @_;
   my($y,$m,$d,$h,$mn,$s)          = @$date;
   my($dh,$dmn,$ds)                = @$time;

   if ($ds > 59  ||  $ds < -59) {
      $dmn += int($ds/60);
      $ds   = $ds % 60;
   }
   if ($dmn > 59  ||  $dmn < -59) {
      $dh  += int($dmn/60);
      $dmn  = $dmn % 60;
   }
   my $dd = 0;
   if ($dh > 23  ||  $dh < -23) {
      $dd  = int($dh/24);
      $dh  = $dh % 24;
   }

   # Handle subtraction
   if ($subtract) {
      $dh  *= -1;
      $dmn *= -1;
      $ds  *= -1;
      $dd  *= -1;
   }

   if ($dd == 0) {
      $y *= 1;
      $m *= 1;
      $d *= 1;
   } else {
      ($y,$m,$d) = @{ $self->calc_date_days([$y,$m,$d],$dd) };
   }

   $self->_mod_add(60,$ds,\$s,\$mn);
   $self->_mod_add(60,$dmn,\$mn,\$h);
   $self->_mod_add(24,$dh,\$h,\$d);

   if ($d<1) {
      $m--;
      $y--, $m=12  if ($m<1);
      my $day_in_mon = $self->days_in_month($y,$m);
      $d += $day_in_mon;
   } else {
      my $day_in_mon = $self->days_in_month($y,$m);
      if ($d>$day_in_mon) {
         $d -= $day_in_mon;
         $m++;
         $y++, $m=1  if ($m>12);
      }
   }

   return [$y,$m,$d,$h,$mn,$s];
}

sub _calc_date_time_strings {
   my($self,$date,$time,$subtract) = @_;
   my @date = @{ $self->split('date',$date) };
   return ''  if (! @date);
   my @time = @{ $self->split('time',$time) };

   my @date2 = @{ $self->calc_date_time(\@date,\@time,$subtract) };

   return $self->join('date',\@date2);
}

sub _calc_date_ymwd {
   my($self,$date,$ymwd,$subtract) = @_;
   my($y,$m,$d,$h,$mn,$s)          = @$date;
   my($dy,$dm,$dw,$dd)             = @$ymwd;
   my($ymdonly)                    = (defined $h ? 0 : 1);

   $dd += $dw*7;

   if ($subtract) {
      $y -= $dy;
      $self->_mod_add(-12,-1*$dm,\$m,\$y);
      $dd *= -1;

   } else {
      $y += $dy;
      $self->_mod_add(-12,$dm,\$m,\$y);
   }

   my $dim = $self->days_in_month($y,$m);
   $d      = $dim  if ($d > $dim);

   my $ymd;
   if ($dd == 0) {
      $ymd = [$y,$m,$d];
   } else {
      $ymd = $self->calc_date_days([$y,$m,$d],$dd);
   }

   if ($ymdonly) {
      return $ymd;
   } else {
      return [@$ymd,$h,$mn,$s];
   }
}

sub _calc_hms_hms {
   my($self,$hms0,$hms1) = @_;
   my($h0,$m0,$s0,$h1,$m1,$s1) = (@$hms0,@$hms1);

   my($s) = ($h1-$h0)*3600 + ($m1-$m0)*60  +  $s1-$s0;
   my($m) = int($s/60);
   $s    -= $m*60;
   my($h) = int($m/60);
   $m    -= $h*60;
   return [$h,$m,$s];
}

sub calc_time_time {
   my($self,$time0,$time1,$subtract) = @_;
   my($h0,$m0,$s0,$h1,$m1,$s1)       = (@$time0,@$time1);

   if ($subtract) {
      $h1 *= -1;
      $m1 *= -1;
      $s1 *= -1;
   }
   my($s) = (($h0+$h1)*60 + ($m0+$m1))*60 + $s0+$s1;
   my($m) = int($s/60);
   $s    -= $m*60;
   my($h) = int($m/60);
   $m    -= $h*60;

   return [$h,$m,$s];
}

###############################################################################

# Returns -1 if date0 is before date1, 0 if date0 is the same as date1, and
# 1 if date0 is after date1.
#
sub cmp {
   my($self,$date0,$date1) = @_;
   return ($$date0[0]  <=> $$date1[0]  ||
           $$date0[1]  <=> $$date1[1]  ||
           $$date0[2]  <=> $$date1[2]  ||
           $$date0[3]  <=> $$date1[3]  ||
           $$date0[4]  <=> $$date1[4]  ||
           $$date0[5]  <=> $$date1[5]);
}

###############################################################################
# This determines the OS.

sub _os {
   my($self) = @_;

   my $os = '';

   if ($^O =~ /MSWin32/io    ||
       $^O =~ /Windows_95/io ||
       $^O =~ /Windows_NT/io
      ) {
      $os = 'Windows';

   } elsif ($^O =~ /MacOS/io  ||
            $^O =~ /MPE/io    ||
            $^O =~ /OS2/io    ||
            $^O =~ /NetWare/io
           ) {
      $os = 'Other';

   } elsif ($^O =~ /VMS/io) {
      $os = 'VMS';

   } else {
      $os = 'Unix';
   }

   return $os;
}

###############################################################################
# Config variable functions

# $self->config(SECT);
#    Creates a new section (if it doesn't already exist).
#
# $self->config(SECT,'_vars');
#    Returns a list of (VAR VAL VAR VAL ...)
#
# $self->config(SECT,VAR,VAL);
#    Adds (VAR,VAL) to the list.
#
sub _section {
   my($self,$sect,$var,$val) = @_;
   $sect = lc($sect);

   #
   # $self->_section(SECT)    creates a new section
   #

   if (! defined $var  &&
       ! exists $$self{'data'}{'sections'}{$sect}) {
      if ($sect eq 'conf') {
         $$self{'data'}{'sections'}{$sect} = {};
      } else {
         $$self{'data'}{'sections'}{$sect} = [];
      }
      return '';
   }

   if ($var eq '_vars') {
      return @{ $$self{'data'}{'sections'}{$sect} };
   }

   push @{ $$self{'data'}{'sections'}{$sect} },($var,$val);
   return;
}

# This sets a config variable. It also performs all side effects from
# setting that variable.
#
sub _config_var_base {
   my($self,$var,$val) = @_;

   if ($var eq 'defaults') {
      # Reset the configuration if desired.
      $self->_init_config(1);
      return;

   } elsif ($var eq 'eraseholidays') {
      $self->_init_holidays(1);
      return;

   } elsif ($var eq 'eraseevents') {
      $self->_init_events(1);
      return;

   } elsif ($var eq 'configfile') {
      $self->_config_file($val);
      return;

   } elsif ($var eq 'encoding') {
      my $err = $self->_config_var_encoding($val);
      return if ($err);

   } elsif ($var eq 'language') {
      my $err = $self->_language($val);
      return  if ($err);
      $err    = $self->_config_var_encoding();
      return  if ($err);

   } elsif ($var eq 'yytoyyyy') {
      $val = lc($val);
      if ($val ne 'c'  &&
          $val !~ /^c\d\d$/o  &&
          $val !~ /^c\d\d\d\d$/o  &&
          $val !~ /^\d+$/o) {
         warn "ERROR: [config_var] invalid: YYtoYYYY: $val\n";
         return;
      }

   } elsif ($var eq 'workweekbeg') {
      my $err = $self->_config_var_workweekbeg($val);
      return  if ($err);

   } elsif ($var eq 'workweekend') {
      my $err = $self->_config_var_workweekend($val);
      return  if ($err);

   } elsif ($var eq 'workday24hr') {
      my $err = $self->_config_var_workday24hr($val);
      return  if ($err);

   } elsif ($var eq 'workdaybeg') {
      my $err = $self->_config_var_workdaybegend(\$val,'WorkDayBeg');
      return  if ($err);

   } elsif ($var eq 'workdayend') {
      my $err = $self->_config_var_workdaybegend(\$val,'WorkDayEnd');
      return  if ($err);

   } elsif ($var eq 'firstday') {
      my $err = $self->_config_var_firstday($val);
      return  if ($err);

   } elsif ($var eq 'tz'  ||
            $var eq 'forcedate'  ||
            $var eq 'setdate') {
      # These can only be used if the Date::Manip::TZ module has been loaded
      warn "ERROR: [config_var] $var config variable requires TZ module\n";
      return;

   } elsif ($var eq 'recurrange') {
      my $err = $self->_config_var_recurrange($val);
      return  if ($err);

   } elsif ($var eq 'defaulttime') {
      my $err = $self->_config_var_defaulttime($val);
      return  if ($err);

   } elsif ($var eq 'periodtimesep') {
      # We have to redo the time regexp
      delete $$self{'data'}{'rx'}{'time'};

   } elsif ($var eq 'format_mmmyyyy') {
      my $err = $self->_config_var_format_mmmyyyy($val);
      return  if ($err);

   } elsif ($var eq 'dateformat'    ||
            $var eq 'jan1week1'     ||
            $var eq 'printable'     ||
            $var eq 'maxrecurattempts' ||
            $var eq 'tomorrowfirst') {
      # do nothing

   } else {
      warn "ERROR: [config_var] invalid config variable: $var\n";
      return '';
   }

   $$self{'data'}{'sections'}{'conf'}{$var} = $val;
   return;
}

###############################################################################
# Specific config variable functions

sub _config_var_encoding {
   my($self,$val) = @_;

   if (! $val) {
      $$self{'data'}{'calc'}{'enc_in'}  = [ @{ $$self{'data'}{'enc'} } ];
      $$self{'data'}{'calc'}{'enc_out'} = 'UTF-8';

   } elsif ($val =~ /^(.*),(.*)$/o) {
      my($in,$out) = ($1,$2);
      if ($in) {
         my $o = find_encoding($in);
         if (! $o) {
            warn "ERROR: [config_var] invalid: Encoding: $in\n";
            return 1;
         }
      }
      if ($out) {
         my $o = find_encoding($out);
         if (! $o) {
            warn "ERROR: [config_var] invalid: Encoding: $out\n";
            return 1;
         }
      }

      if ($in  &&  $out) {
         $$self{'data'}{'calc'}{'enc_in'}  = [ $in ];
         $$self{'data'}{'calc'}{'enc_out'} = $out;

      } elsif ($in) {
         $$self{'data'}{'calc'}{'enc_in'}  = [ $in ];
         $$self{'data'}{'calc'}{'enc_out'} = 'UTF-8';

      } elsif ($out) {
         $$self{'data'}{'calc'}{'enc_in'}  = [ @{ $$self{'data'}{'enc'} } ];
         $$self{'data'}{'calc'}{'enc_out'} = $out;

      } else {
         $$self{'data'}{'calc'}{'enc_in'}  = [ @{ $$self{'data'}{'enc'} } ];
         $$self{'data'}{'calc'}{'enc_out'} = 'UTF-8';
      }

   } else {
      my $o = find_encoding($val);
      if (! $o) {
         warn "ERROR: [config_var] invalid: Encoding: $val\n";
         return 1;
      }
      $$self{'data'}{'calc'}{'enc_in'}  = [ $val ];
      $$self{'data'}{'calc'}{'enc_out'} = $val;
   }

   if (! @{ $$self{'data'}{'calc'}{'enc_in'} }) {
      $$self{'data'}{'calc'}{'enc_in'}  = [ qw(utf-8 perl) ];
   }

   return 0;
}

sub _config_var_recurrange {
   my($self,$val) = @_;

   $val = lc($val);
   if ($val =~ /^(none|year|month|week|day|all)$/o) {
      return 0;
   }

   warn "ERROR: [config_var] invalid: RecurRange: $val\n";
   return 1;
}

sub _config_var_workweekbeg {
   my($self,$val) = @_;

   if (! $self->_is_int($val,1,7)) {
      warn "ERROR: [config_var] invalid: WorkWeekBeg: $val\n";
      return 1;
   }
   if ($val >= $self->_config('workweekend')) {
      warn "ERROR: [config_var] WorkWeekBeg must be before WorkWeekEnd\n";
      return 1;
   }

   $self->_calc_workweek($val,'');
   $self->_init_business_length();
   return 0;
}

sub _config_var_workweekend {
   my($self,$val) = @_;

   if (! $self->_is_int($val,1,7)) {
      warn "ERROR: [config_var] invalid: WorkWeekBeg: $val\n";
      return 1;
   }
   if ($val <= $self->_config('workweekbeg')) {
      warn "ERROR: [config_var] WorkWeekEnd must be after WorkWeekBeg\n";
      return 1;
   }

   $self->_calc_workweek('',$val);
   $self->_init_business_length();
   return 0;
}

sub _config_var_workday24hr {
   my($self,$val) = @_;

   if ($val) {
      $$self{'data'}{'sections'}{'conf'}{'workdaybeg'} = '00:00:00';
      $$self{'data'}{'sections'}{'conf'}{'workdayend'} = '24:00:00';
      $$self{'data'}{'calc'}{'workdaybeg'}             = [0,0,0];
      $$self{'data'}{'calc'}{'workdayend'}             = [24,0,0];

      $self->_calc_bdlength();
      $self->_init_business_length();
   }

   return 0;
}

sub _config_var_workdaybegend {
   my($self,$val,$conf) = @_;

   # Must be a valid time.  Entered as H, H:M, or H:M:S

   my $tmp = $self->split('hms',$$val);
   if (! defined $tmp) {
      warn "ERROR: [config_var] invalid: $conf: $$val\n";
      return 1;
   }
   $$self{'data'}{'calc'}{lc($conf)} = $tmp;
   $$val = $self->join('hms',$tmp);

   # workdaybeg < workdayend

   my @beg = @{ $$self{'data'}{'calc'}{'workdaybeg'} };
   my @end = @{ $$self{'data'}{'calc'}{'workdayend'} };
   my $beg = $beg[0]*3600 + $beg[1]*60 + $beg[2];
   my $end = $end[0]*3600 + $end[1]*60 + $end[2];

   if ($beg > $end) {
      warn "ERROR: [config_var] WorkDayBeg not before WorkDayEnd\n";
      return 1;
   }

   # Calculate bdlength

   $$self{'data'}{'sections'}{'conf'}{'workday24hr'} = 0;

   $self->_calc_bdlength();
   $self->_init_business_length();

   return 0;
}

sub _config_var_firstday {
   my($self,$val) = @_;

   if (! $self->_is_int($val,1,7)) {
      warn "ERROR: [config_var] invalid: FirstDay: $val\n";
      return 1;
   }

   return 0;
}

sub _config_var_defaulttime {
   my($self,$val) = @_;

   if (lc($val) eq 'midnight'  ||
       lc($val) eq 'curr') {
      return 0;
   }
   warn "ERROR: [config_var] invalid: DefaultTime: $val\n";
   return 1;
}

sub _config_var_format_mmmyyyy {
   my($self,$val) = @_;

   if (lc($val) eq 'first'  ||
       lc($val) eq 'last'   ||
       lc($val) eq '') {
      return 0;
   }
   warn "ERROR: [config_var] invalid: Format_MMMYYYY: $val\n";
   return 1;
}

###############################################################################
# Language functions

# This reads in a langauge module and sets regular expressions
# and word lists based on it.
#
no strict 'refs';
sub _language {
   my($self,$lang) = @_;
   $lang = lc($lang);

   if (! exists $Date::Manip::Lang::index::Lang{$lang}) {
      warn "ERROR: [language] invalid: $lang\n";
      return 1;
   }

   return 0  if (exists $$self{'data'}{'sections'}{'conf'}  &&
                 $$self{'data'}{'sections'}{'conf'} eq $lang);
   $self->_init_language(1);

   my $mod = $Date::Manip::Lang::index::Lang{$lang};
   eval "require Date::Manip::Lang::${mod}";
   if ($@) {
      die "ERROR: failed to load Date::Manip::Lang::${mod}: $@\n";
   }

   no warnings 'once';
   $$self{'data'}{'lang'} = ${ "Date::Manip::Lang::${mod}::Language" };
   $$self{'data'}{'enc'}  = [ @{ "Date::Manip::Lang::${mod}::Encodings" } ];

   # Common words
   $self->_rx_wordlist('at');
   $self->_rx_wordlist('each');
   $self->_rx_wordlist('last');
   $self->_rx_wordlist('of');
   $self->_rx_wordlist('on');
   $self->_rx_wordlists('when');

   # Next/prev
   $self->_rx_wordlists('nextprev');

   # Field names (years, year, yr, ...)
   $self->_rx_wordlists('fields');

   # Numbers (first, 1st)
   $self->_rx_wordlists('nth');
   $self->_rx_wordlists('nth','nth_dom',31);  # 1-31
   $self->_rx_wordlists('nth','nth_wom',5);   # 1-5

   # Calendar names (Mon, Tue  and  Jan, Feb)
   $self->_rx_wordlists('day_abb');
   $self->_rx_wordlists('day_char');
   $self->_rx_wordlists('day_name');
   $self->_rx_wordlists('month_abb');
   $self->_rx_wordlists('month_name');

   # H:M:S separators
   $self->_rx_simple('sephm');
   $self->_rx_simple('sepms');
   $self->_rx_simple('sepfr');

   # Time replacement strings
   $self->_rx_replace('times');

   # Some offset strings
   $self->_rx_replace('offset_date');
   $self->_rx_replace('offset_time');

   # AM/PM strings
   $self->_rx_wordlists('ampm');

   # Business/non-business mode
   $self->_rx_wordlists('mode');

   return 0;
}
use strict 'refs';

# This takes a string or strings from the language file which is a
# regular expression and copies it to the regular expression cache.
#
# If the language file contains a list of strings, a list of strings
# is stored in the regexp cache.
#
sub _rx_simple {
   my($self,$ele) = @_;

   if (exists $$self{'data'}{'lang'}{$ele}) {
      if (ref($$self{'data'}{'lang'}{$ele})) {
         @{ $$self{'data'}{'rx'}{$ele} } = @{ $$self{'data'}{'lang'}{$ele} };
      } else {
         $$self{'data'}{'rx'}{$ele} = $$self{'data'}{'lang'}{$ele};
      }
   } else {
      $$self{'data'}{'rx'}{$ele} = undef;
   }

   return;
}

# We need to quote strings that will be used in regexps, but we don't
# want to quote UTF-8 characters.
#
sub _qe_quote {
   my($string) = @_;
   $string     =~ s/([-.+*?])/\\$1/g;
   return $string;
}

# This takes a list of words and creates a simple regexp which matches
# any of them.
#
# The first word in the list is the default way to express the word using
# a normal ASCII character set.
#
# The second word in the list is the default way to express the word using
# a locale character set. If it isn't defined, it defaults to the first word.
#
sub _rx_wordlist {
   my($self,$ele) = @_;

   if (exists $$self{'data'}{'lang'}{$ele}) {
      my @tmp = @{ $$self{'data'}{'lang'}{$ele} };

      $$self{'data'}{'wordlist'}{$ele} = $tmp[0];

      my @tmp2;
      foreach my $tmp (@tmp) {
         push(@tmp2,_qe_quote($tmp))  if ($tmp);
      }
      @tmp2  = sort _sortByLength(@tmp2);

      $$self{'data'}{'rx'}{$ele} = join('|',@tmp2);

   } else {
      $$self{'data'}{'rx'}{$ele} = undef;
   }

   return;
}

no strict 'vars';
sub _sortByLength {
   return (length $b <=> length $a);
}
use strict 'vars';

# This takes a hash of the form:
#    word => string
# and creates a regular expression to match word (which must be surrounded
# by word boundaries).
#
sub _rx_replace {
   my($self,$ele) = @_;

   if (! exists $$self{'data'}{'lang'}{$ele}) {
      $$self{'data'}{'rx'}{$ele} = [];
      return;
   }

   my(@key) = keys %{ $$self{'data'}{'lang'}{$ele} };
   my $i    = 1;
   foreach my $key (sort(@key)) {
      my $val = $$self{'data'}{'lang'}{$ele}{$key};
      my $k   = _qe_quote($key);
      $$self{'data'}{'rx'}{$ele}[$i++] = qr/(?:^|\b)($k)(?:\b|$)/i;
      $$self{'data'}{'wordmatch'}{$ele}{lc($key)} = $val;
   }

   @key   = sort _sortByLength(@key);
   @key   = map { _qe_quote($_) } @key;
   my $rx = join('|',@key);

   $$self{'data'}{'rx'}{$ele}[0] = qr/(?:^|\b)(?:$rx)(?:\b|$)/i;

   return;
}

# This takes a list of values, each of which can be expressed in multiple
# ways, and gets a regular expression which matches any of them, a default
# way to express each value, and a hash which matches a matched string to
# a value (the value is 1..N where N is the number of values).
#
sub _rx_wordlists {
   my($self,$ele,$subset,$max) = @_;
   $subset = $ele  if (! $subset);

   if (exists $$self{'data'}{'lang'}{$ele}) {
      my @vallist = @{ $$self{'data'}{'lang'}{$ele} };
      $max        = $#vallist+1  if (! $max  ||  $max > $#vallist+1);
      my (@all);

      for (my $i=1; $i<=$max; $i++) {
         my @tmp = @{ $$self{'data'}{'lang'}{$ele}[$i-1] };
         $$self{'data'}{'wordlist'}{$subset}[$i-1] = $tmp[0];

         my @str;
         foreach my $str (@tmp) {
            next  if (! $str);
            $$self{'data'}{'wordmatch'}{$subset}{lc($str)} = $i;
            push(@str,_qe_quote($str));
         }
         push(@all,@str);

         @str  = sort _sortByLength(@str);
         $$self{'data'}{'rx'}{$subset}[$i] = join('|',@str);
      }

      @all  = sort _sortByLength(@all);
      $$self{'data'}{'rx'}{$subset}[0] = join('|',@all);

   } else {
      $$self{'data'}{'rx'}{$subset} = undef;
   }

   return;
}

###############################################################################
# Year functions
#
# $self->_method(METHOD)      use METHOD as the method for YY->YYYY
#                             conversions
#
# YEAR = _fix_year(YR)        converts a 2-digit to 4-digit year
#                             _fix_year is in TZ_Base

sub _method {
   my($self,$method) = @_;
   $self->_config('yytoyyyy',$method);

   return;
}

###############################################################################
# $self->_mod_add($N,$add,\$val,\$rem);
#   This calculates $val=$val+$add and forces $val to be in a certain
#   range.  This is useful for adding numbers for which only a certain
#   range is allowed (for example, minutes can be between 0 and 59 or
#   months can be between 1 and 12).  The absolute value of $N determines
#   the range and the sign of $N determines whether the range is 0 to N-1
#   (if N>0) or 1 to N (N<0).  $rem is adjusted to force $val into the
#   appropriate range.
#   Example:
#     To add 2 hours together (with the excess returned in days) use:
#       $self->_mod_add(-24,$h1,\$h,\$day);
#     To add 2 minutes together (with the excess returned in hours):
#       $self->_mod_add(60,$mn1,\$mn,\$hr);
sub _mod_add {
   my($self,$N,$add,$val,$rem)=@_;
   return  if ($N==0);
   $$val+=$add;
   if ($N<0) {
      # 1 to N
      $N = -$N;
      if ($$val>$N) {
         $$rem+= int(($$val-1)/$N);
         $$val = ($$val-1)%$N +1;
      } elsif ($$val<1) {
         $$rem-= int(-$$val/$N)+1;
         $$val = $N-(-$$val % $N);
      }

   } else {
      # 0 to N-1
      if ($$val>($N-1)) {
         $$rem+= int($$val/$N);
         $$val = $$val%$N;
      } elsif ($$val<0) {
         $$rem-= int(-($$val+1)/$N)+1;
         $$val = ($N-1)-(-($$val+1)%$N);
      }
   }

   return;
}

# $flag = $self->_is_int($string [,$low, $high]);
#    Returns 1 if $string is a valid integer, 0 otherwise.  If $low is
#    entered, $string must be >= $low.  If $high is entered, $string must
#    be <= $high.  It is valid to check only one of the bounds.
sub _is_int {
   my($self,$N,$low,$high)=@_;
   return 0  if (! defined $N  or
                 $N !~ /^\s*[-+]?\d+\s*$/o  or
                 defined $low   &&  $N<$low  or
                 defined $high  &&  $N>$high);
   return 1;
}

# $flag = $self->_is_num($string [,$low, $high]);
#    Returns 1 if $string is a valid number (integer or real), 0 otherwise.
#    If $low is entered, $string must be >= $low.  If $high is entered,
#    $string must be <= $high.  It is valid to check only one of the bounds.
sub _is_num {
   my($self,$N,$low,$high)=@_;
   return 0  if (! defined $N  or
                 ($N !~ /^\s*[-+]?\d+(\.\d*)?\s*$/o  &&
                  $N !~ /^\s*[-+]?\.\d+\s*$/o)  or
                 defined $low   &&  $N<$low  or
                 defined $high  &&  $N>$high);
   return 1;
}

###############################################################################
# Split/Join functions

sub split {
   my($self,$op,$string,$arg) = @_;

   my %opts;
   if (ref($arg) eq 'HASH') {
      %opts = %{ $arg };
   } elsif ($arg) {
      # ***DEPRECATED 7.0***
      %opts = ('nonorm' => 1);
   }

   # ***DEPRECATED 7.0***
   if ($op eq 'delta') {
      $opts{'mode'} = 'standard';
   } elsif ($op eq 'business') {
      $opts{'mode'} = 'business';
      $op = 'delta';
   }

   if ($op eq 'date') {

      if ($string =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d):(\d\d):(\d\d)$/o  ||
          $string =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)\-(\d\d):(\d\d):(\d\d)$/o  ||
          $string =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/o) {
         my($y,$m,$d,$h,$mn,$s) = ($1+0,$2+0,$3+0,$4+0,$5+0,$6+0);
         return [$y,$m,$d,$h,$mn,$s];
      } else {
         return undef;
      }

   } elsif ($op eq 'hms') {
      if ($string =~ /^(\d\d)(\d\d)(\d\d)$/o     ||
          $string =~ /^(\d\d)(\d\d)()$/o         ||
          $string =~ /^(\d\d?):(\d\d):(\d\d)$/o  ||
          $string =~ /^(\d\d?):(\d\d)()$/o       ||
          $string =~ /^(\d\d?)()()$/o) {
         my($err,$h,$mn,$s) = $self->_hms_fields( { 'out' => 'list' },[$1,$2,$3]);
         return undef  if ($err);
         return [$h,$mn,$s];
      } else {
         return undef;
      }

   } elsif ($op eq 'offset') {
      if ($string =~ /^([-+]?\d\d)(\d\d)(\d\d)$/o       ||
          $string =~ /^([-+]?\d\d)(\d\d)()$/o           ||
          $string =~ /^([-+]?\d\d?):(\d\d?):(\d\d?)$/o  ||
          $string =~ /^([-+]?\d\d?):(\d\d?)()$/o        ||
          $string =~ /^([-+]?\d\d?)()()$/o) {
         my($err,$h,$mn,$s) = $self->_offset_fields( { 'source' => 'string',
                                                       'out'    => 'list'},
                                                     [$1,$2,$3]);
         return undef  if ($err);
         return [$h,$mn,$s];
      } else {
         return undef;
      }

   } elsif ($op eq 'time') {
      if ($string =~ /^[-+]?\d+(:[-+]?\d+){0,2}$/o) {
         my($err,$dh,$dmn,$ds) =
           $self->_time_fields( { 'nonorm'   =>
                                  (exists($opts{'nonorm'}) ? $opts{'nonorm'} : 0),
                                  'source'   => 'string',
                                  'sign'     => -1,
                                }, [split(/:/,$string)]);
         return undef  if ($err);
         return [$dh,$dmn,$ds];
      } else {
         return undef;
      }

   } elsif ($op eq 'delta') {
      my($err,@delta) = $self->_split_delta($string);
      return undef  if ($err);

      ($err,@delta) =
        $self->_delta_fields( { 'mode'     => $opts{'mode'},
                                'nonorm'   => (exists($opts{'nonorm'}) ?
                                               $opts{'nonorm'} : 0),
                                'source'   => 'string',
                                'sign'     => -1,
                              }, [@delta]);

      return undef  if ($err);
      return [@delta];
   }
}

sub join{
   my($self,$op,$data,$arg) = @_;

   my %opts;
   if (ref($arg) eq 'HASH') {
      %opts = %{ $arg };
   } elsif ($arg) {
      # ***DEPRECATED 7.0***
      %opts = ('nonorm' => 1);
   }

   # ***DEPRECATED 7.0***
   if ($op eq 'delta') {
      $opts{'mode'} = 'standard';
   } elsif ($op eq 'business') {
      $opts{'mode'} = 'business';
      $op = 'delta';
   }

   my @data = @$data;

   if ($op eq 'date') {

      my($err,$y,$m,$d,$h,$mn,$s) = $self->_date_fields(@data);
      return undef  if ($err);
      my $form = $self->_config('printable');
      if ($form == 1) {
         return "$y$m$d$h$mn$s";
      } elsif ($form == 2) {
         return "$y-$m-$d-$h:$mn:$s";
      } else {
         return "$y$m$d$h:$mn:$s";
      }

   } elsif ($op eq 'offset') {
      my($err,$h,$mn,$s) = $self->_offset_fields( { 'source' => 'list',
                                                    'out'    => 'string'},
                                                  [@data]);
      return undef  if ($err);
      return "$h:$mn:$s";

   } elsif ($op eq 'hms') {
      my($err,$h,$mn,$s) = $self->_hms_fields( { 'out' => 'string' },[@data]);
      return undef  if ($err);
      return "$h:$mn:$s";

   } elsif ($op eq 'time') {
      my($err,$dh,$dmn,$ds) =
        $self->_time_fields( { 'nonorm'   =>
                               (exists($opts{'nonorm'}) ? $opts{'nonorm'} : 0),
                               'source'   => 'list',
                               'sign'     => 0,
                             }, [@data]);
      return undef  if ($err);
      return "$dh:$dmn:$ds";

   } elsif ($op eq 'delta') {
      my ($err,@delta) =
        $self->_delta_fields( { 'mode'     => $opts{'mode'},
                                'nonorm'   => (exists($opts{'nonorm'}) ?
                                               $opts{'nonorm'} : 0),
                                'source'   => 'list',
                                'sign'     => 0,
                              }, [@data]);
      return undef  if ($err);
      return join(':',@delta);
   }
}

sub _split_delta {
   my($self,$string) = @_;

   my $sign    = '[-+]?';
   my $num     = '(?:\d+(?:\.\d*)?|\.\d+)';
   my $f       = "(?:$sign$num)?";

   if ($string =~ /^$f(:$f){0,6}$/o) {
      $string =~ s/::/:0:/go;
      $string =~ s/^:/0:/o;
      $string =~ s/:$/:0/o;
      my(@delta) = split(/:/,$string);
      return(0,@delta);
   } else {
      return(1);
   }
}

# Check that type is not inconsistent with @delta.
#
# An exact delta cannot have semi-exact or approximate fields set.
# A semi-exact delta cannot have approximate fields set.
# An exact, semi-exact, or approximate delta cannot have non-integer values.
#
# If the type was not explicitly specified, guess what it is.
#
# Returns ($err,$type,$type_from)
#
sub _check_delta_type {
   my($self,$mode,$type,$type_from,@delta) = @_;

   my $est    = 0;
   foreach my $f (@delta) {
      if (! $self->_is_int($f)) {
         $est = 1;
         last;
      }
   }

   my $approx = 0;
   if (! $est) {
      $approx = 1  if ($delta[0]  ||  $delta[1]);
   }

   my $semi   = 0;
   if (! $est  &&  ! $approx) {
      if ($mode eq 'business') {
         $semi = 1  if ($delta[2]);
      } else {
         $semi = 1  if ($delta[2]  ||  $delta[3]);
      }
   }

   if ($est) {
      # If some of the fields are non-integer, then type must be estimated.

      if ($type ne 'estimated') {
         if ($type_from eq 'opt') {
            return ("Type must be estimated for non-integers");
         }
         $type = 'estimated';
         $type_from = 'det';
      }

   } elsif ($approx) {
      # If some of the approximate fields are set, then type must be
      # approx or estimated.

      if ($type ne 'approx'  &&  $type ne 'estimated') {
         if ($type_from eq 'opt') {
            return("Type must be approx/estimated");
         }
         $type = 'approx';
         $type_from = 'det';
      }

   } elsif ($semi) {
      # If some of the semi-exact fields are set, then type must be
      # semi, approx, or estimated

      if ($type ne 'semi'  &&  $type ne 'approx'  &&  $type ne 'estimated') {
         if ($type_from eq 'opt') {
            return("Type must be semi/approx/estimated");
         }
         $type = 'semi';
         $type_from = 'det';
      }

   } else {

      if (! $type) {
         $type = 'exact';
         $type_from = 'det';
      }
   }

   return ('',$type,$type_from);
}

# This function returns the fields in a delta in the desired format.
#
# $opts = { mode     => standard/business
#           type     => exact/semi/approx/estimated
#           nonorm   => 0/1,
#           source   => string, list, delta
#           sign     => 0/1/-1
#         }
# $fields = [Y,M,W,D,H,Mn,S]
#
# If the business option is 1, treat it as a business delta.
#
# If the nonorm option is 1, fields are NOT normalized.  By default,
# they are normalized.
#
# If source is 'string', then the source of the fields is a string
# that has been split, so we need to handle carrying the signs.  If
# the option is 'list', then the source is a valid delta, so each
# field is correctly signed already.  In both cases, the type of
# delta will need to be determined.  If the source is 'delta', then
# it comes from a Date::Manip::Delta object.  In this case the type
# must be specified.  If type is not passed in, it will be set.
#
# If the sign option is 1, a sign is added to every field.  If the
# sign option is -1, all negative fields are signed.  If the sign
# option is 0, the minimum number of signs (for fields who's sign is
# different from the next higher field) will be added.
#
# It returns ($err,@fields)
#
sub _delta_fields {
   my($self,$opts,$fields) = @_;
   my @fields = @$fields;
   no integer;

   #
   # Make sure that all fields are defined, numerical, and that there
   # are 7 of them.
   #

   foreach my $f (@fields) {
      $f=0  if (! defined($f));
      return ("Non-numerical field")  if (! $self->_is_num($f));
   }
   return ("Delta may contain only 7 fields")  if (@fields > 7);
   while (@fields < 7) {
      unshift(@fields,0);
   }

   #
   # Make sure each field is the correct sign so that the math will
   # work correctly.  Get rid of all positive signs and leading 0's.
   #

   my $mode   = $$opts{'mode'};
   my $source = $$opts{'source'};
   @fields    = $self->_sign_source($source,@fields);

   #
   # Figure out the type of delta.  When called from Date::Manip::Base, it'll
   # be determined from the data.  When called from Date::Manip::Delta, it'll
   # be specified.
   #

   my ($type,$type_from);
   if (defined $source  &&  $source eq 'delta') {
      if (! exists $$opts{'type'}) {
         return ("Type must be specified");
      }
      $type = $$opts{'type'};

   } else {
      my $err;
      ($err,$type,$type_from) = $self->_check_delta_type($mode,'','init',@fields);
      $$opts{'type'}      = $type;
      $$opts{'type_from'} = $type_from;
      return($err)  if ($err);
   }

   #
   # Normalize values, if desired.
   #

   my $norm = 1-$$opts{'nonorm'};
   if ($norm) {
      if ($mode eq 'business') {

         if ($type eq 'estimated') {
            @fields = $self->_normalize_bus_est(@fields);

         } elsif ($type eq 'approx'  ||
                  $type eq 'semi') {
            @fields = $self->_normalize_bus_approx(@fields);

         } else {
            @fields = $self->_normalize_bus_exact(@fields);
         }

      } else {

         if ($type eq 'estimated') {
            @fields = $self->_normalize_est(@fields);

         } elsif ($type eq 'approx'  ||
                  $type eq 'semi') {
            @fields = $self->_normalize_approx(@fields);

         } else {
            @fields = $self->_normalize_exact(@fields);
         }

      }
   }

   #
   # Now make sure that the signs are included as appropriate.
   #

   @fields = $self->_sign_fields($$opts{'sign'},@fields);

   return (0,@fields);
}

# If a set of fields came from splitting a string, not all of the fields
# are signed.  If it comes from a list, we just want to remove extra '+'
# signs.
#
sub _sign_source {
   my($self,$source,@fields) = @_;

   # Needed to handle fractional fields
   no integer;
   if ($source eq 'string') {

      # if the source is splitting a delta, not all fields are signed,
      # so we need to carry the negative signs.

      my $sign = '+';
      foreach my $f (@fields) {
         if ($f =~ /^([-+])/o) {
            $sign = $1;
         } else {
            $f = "$sign$f";
         }
         $f *= 1;
      }

   } else {
      foreach my $f (@fields) {
         $f *= 1;
      }
   }

   return @fields;
}

# This applies the correct sign to each field based on the $sign option:
#
#    1 : all fields signed
#   -1 : all negative fields signed
#    0 : minimum number of signs for a joined set of fields
#
sub _sign_fields {
   my($self,$sign,@fields) = @_;
   $sign = 0  if (! defined $sign);

   if      ($sign == 1) {
      # All fields signed
      foreach my $f (@fields) {
         $f = "+$f"  if ($f > 0);
      }

   } elsif ($sign == 0) {
      # Minimum number of signs
      my $s = ($fields[0] < 0 ? '-' : '+');
      foreach my $f (@fields[1..$#fields]) {
         if ($f > 0  &&  $s eq '-') {
            $f   = "+$f";
            $s   = '+';
         } elsif ($f < 0) {
            if ($s eq '-') {
               $f *= -1;
            } else {
               $s  = '-';
            }
         }
      }
   }

   return @fields;
}

# $opts = { nonorm   => 0/1,
#           source   => string, list
#           sign     => 0/1/-1
#         }
# $fields = [H,M,S]
#
# This function formats the fields in an amount of time measured in
# hours, minutes, and seconds.
#
# It is similar to how _delta_fields (above) works.
#
sub _time_fields {
   my($self,$opts,$fields) = @_;
   my @fields = @$fields;

   #
   # Make sure that all fields are defined, numerical, and that there
   # are 3 of them.
   #

   foreach my $f (@fields) {
      $f=0  if (! defined($f));
      return (1)  if (! $self->_is_int($f));
   }
   return (1)  if (@fields > 3);
   while (@fields < 3) {
      unshift(@fields,0);
   }

   #
   # Make sure each field is the correct sign so that the math will
   # work correctly.  Get rid of all positive signs and leading 0's.
   #

   my $source = $$opts{'source'};
   @fields    = $self->_sign_source($source,@fields);

   #
   # Normalize them.  Values will be signed only if they are
   # negative.
   #

   my $norm = 1-$$opts{'nonorm'};
   if ($norm) {
      my($h,$mn,$s) = @fields;
      $s  += $h*3600 + $mn*60;
      @fields = __normalize_hms($h,$mn,$s);
   }

   #
   # Now make sure that the signs are included as appropriate.
   #

   @fields = $self->_sign_fields($$opts{'sign'},@fields);

   return (0,@fields);
}

# $opts = { out   => string, list
#         }
# $fields = [H,M,S]
#
# This function formats the fields in an HMS.
#
# If the out options is string, it prepares the fields to be joined (i.e.
# they are all 2 digits long).  Otherwise, they are just numerical values
# (not necessarily 2 digits long).
#
# HH:MN:SS is always between 00:00:00 and 24:00:00.
#
# It returns ($err,@fields)
#
sub _hms_fields {
   my($self,$opts,$fields) = @_;
   my @fields = @$fields;

   #
   # Make sure that all fields are defined, numerical (with no sign),
   # and that there are 3 of them.
   #

   foreach my $f (@fields) {
      $f=0  if (! $f);
      return (1)  if (! $self->_is_int($f,0));
   }
   return (1)  if (@fields > 3);
   while (@fields < 3) {
      push(@fields,0);
   }

   #
   # Check validity.
   #

   my ($h,$m,$s) = @fields;
   return (1)  if ($h > 24  ||  $m > 59  ||  $s > 59  ||
                   ($h==24  &&  ($m > 0 ||  $s > 0)));

   #
   # Format
   #

   if ($$opts{'out'} eq 'list') {
      foreach my $f ($h,$m,$s) {
         $f *= 1;
      }

   } else {
      foreach my $f ($h,$m,$s) {
         $f = "0$f"  if (length($f)<2);
      }
   }

   return (0,$h,$m,$s);
}

# $opts = { source     => string, list
#           out        => string, list
#         }
# $fields = [H,M,S]
#
# This function formats the fields in a timezone offset measured in
# hours, minutes, and seconds.
#
# All offsets must be -23:59:59 <= offset <= 23:59:59 .
#
# The data comes from an offset in string or list format, and is
# formatted so that it can be used to create a string or list format
# output.
#
sub _offset_fields {
   my($self,$opts,$fields) = @_;
   my @fields = @$fields;

   #
   # Make sure that all fields are defined, numerical, and that there
   # are 3 of them.
   #

   foreach my $f (@fields) {
      $f=0  if (! defined $f  ||  $f eq '');
      return (1)  if (! $self->_is_int($f));
   }
   return (1)  if (@fields > 3);
   while (@fields < 3) {
      push(@fields,0);
   }

   #
   # Check validity.
   #

   my ($h,$m,$s) = @fields;
   if ($$opts{'source'} eq 'string') {
      # Values = -23 59 59 to +23 59 59
      return (1)  if ($h < -23  ||  $h > 23  ||
                      $m < 0    ||  $m > 59  ||
                      $s < 0    ||  $s > 59);
   } else {
      # Values (-23,-59,-59) to (23,59,59)
      # Non-zero values must have the same sign
      if ($h >0) {
         return (1)  if (              $h > 23  ||
                         $m < 0    ||  $m > 59  ||
                         $s < 0    ||  $s > 59);
      } elsif ($h < 0) {
         return (1)  if ($h < -23  ||
                         $m < -59  ||  $m > 0   ||
                         $s < -59  ||  $s > 0);
      } elsif ($m > 0) {
         return (1)  if (              $m > 59  ||
                         $s < 0    ||  $s > 59);
      } elsif ($m < 0) {
         return (1)  if ($m < -59  ||
                         $s < -59  ||  $s > 0);
      } else {
         return (1)  if ($s < -59  ||  $s > 59);
      }
   }

   #
   # Make sure each field is the correct sign so that the math will
   # work correctly.  Get rid of all positive signs and leading 0's.
   #

   if ($$opts{'source'} eq 'string') {

      # In a string offset, only the first field is signed, so we need
      # to carry negative signs.

      if ($h =~ /^\-/) {
         $h *= 1;
         $m *= -1;
         $s *= -1;
      } elsif ($m =~ /^\-/) {
         $h *= 1;
         $m *= 1;
         $s *= -1;
      } else {
         $h *= 1;
         $m *= 1;
         $s *= 1;
      }

   } else {
      foreach my $f (@fields) {
         $f *= 1;
      }
   }

   #
   # Format them.  They're already done for 'list' output.
   #

   if ($$opts{'out'} eq 'string') {
      my $sign;
      if ($h<0 || $m<0 || $s<0) {
         $h = abs($h);
         $m = abs($m);
         $s = abs($s);
         $sign = '-';
      } else {
         $sign = '+';
      }

      $h = "0$h"  if (length($h) < 2);
      $m = "0$m"  if (length($m) < 2);
      $s = "0$s"  if (length($s) < 2);
      $h = "$sign$h";
   }

   return (0,$h,$m,$s);
}

# ($err,$y,$m,$d,$h,$mn,$s) = $self->_date_fields($y,$m,$d,$h,$mn,$s);
#
# Makes sure the fields are the right length.
#
sub _date_fields {
   my($self,@fields) = @_;
   return (1)  if (@fields != 6);

   my($y,$m,$d,$h,$mn,$s) = @fields;

   $y = "0$y"     while (length($y) < 4);
   $m  = "0$m"    if (length($m)==1);
   $d  = "0$d"    if (length($d)==1);
   $h  = "0$h"    if (length($h)==1);
   $mn = "0$mn"   if (length($mn)==1);
   $s  = "0$s"    if (length($s)==1);

   if (wantarray) {
      return (0,$y,$m,$d,$h,$mn,$s);
   } else {
      return "$y$m$d$h:$mn:$s";
   }
}

# $self->_delta_convert(FORMAT,DELTA)
#    This converts delta into the given format. Returns '' if invalid.
#
sub _delta_convert {
   my($self,$format,$delta)=@_;
   my $fields = $self->split($format,$delta);
   return undef  if (! defined $fields);
   return $self->join($format,$fields);
}

###############################################################################
# Normalize the different types of deltas

sub __normalize_ym {
   my($y,$m,$s,$mon) = @_;
   no integer;

   if (defined($s)) {
      $m      = int($s/$mon);
      $s     -= int(sprintf('%f',$m*$mon));
      $y      = int($m/12);
      $m     -= $y*12;

      return($y,$m,$s);
   } else {
      $m     += $y*12;
      $y      = int($m/12);
      $m     -= $y*12;

      return($y,$m);
   }
}
sub __normalize_wd {
   my($w,$d,$s,$wk,$day) = @_;
   no integer;

   $d      = int($s/$day);
   $s     -= int($d*$day);
   $w      = int($d/$wk);
   $d     -= $w*$wk;

   return($w,$d,$s);
}
sub __normalize_hms {
   my($h,$mn,$s) = @_;
   no integer;

   $h      = int($s/3600);
   $s     -= $h*3600;
   $mn     = int($s/60);
   $s     -= $mn*60;
   $s      = int($s);

   return($h,$mn,$s);
}

sub _normalize_est {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   # Figure out how many seconds there are in the estimated delta
   #
   # 365.2425/12 days/month * 24 hours/day * 3600 sec/hour = 2629746 sec/month

   my $mon = 2629746;
   my $day = 86400;
   my $wk  = 7;
   $s     += ($y*12+$m)*$mon + ($w*$wk + $d)*$day +
             $h*3600 + $mn*60;

   ($y,$m,$s)  = __normalize_ym($y,$m,$s,$mon);
   ($w,$d,$s)  = __normalize_wd($w,$d,$s,$wk,$day);
   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}
sub _normalize_bus_est {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   # Figure out how many seconds there are in the estimated delta
   #
   # 365.2425/12 * wk_len/7 days/month * day sec/day = X sec/month

   my $day = $$self{'data'}{'len'}{'bdlength'};
   my $wk  = $$self{'data'}{'len'}{'workweek'};
   my $mon = 365.2425/12 * $wk/7 * $day;

   $s     += ($y*12+$m)*$mon + ($w*$wk + $d)*$day +
             $h*3600 + $mn*60;

   ($y,$m,$s)  = __normalize_ym($y,$m,$s,$mon);
   ($w,$d,$s)  = __normalize_wd($w,$d,$s,$wk,$day);
   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}

sub _normalize_approx {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   my $wk  = 7;
   my $day = 86400;
   $s     += ($w*$wk + $d)*$day + $h*3600 + $mn*60;

   ($y,$m)     = __normalize_ym($y,$m);
   ($w,$d,$s)  = __normalize_wd($w,$d,$s,$wk,$day);
   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}
sub _normalize_bus_approx {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   my $wk  = $$self{'data'}{'len'}{'workweek'};
   my $day = $$self{'data'}{'len'}{'bdlength'};
   $s     += ($w*$wk + $d)*$day + $h*3600 + $mn*60;

   ($y,$m)     = __normalize_ym($y,$m);
   ($w,$d,$s)  = __normalize_wd($w,$d,$s,$wk,$day);
   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}

sub _normalize_exact {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   $s     += $h*3600 + $mn*60;

   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}
sub _normalize_bus_exact {
   my($self,$y,$m,$w,$d,$h,$mn,$s) = @_;
   no integer;

   my $day = $$self{'data'}{'len'}{'bdlength'};

   $s     += $d*$day + $h*3600 + $mn*60;

   # Calculate d

   $d      = int($s/$day);
   $s     -= $d*$day;

   ($h,$mn,$s) = __normalize_hms($h,$mn,$s);

   return ($y,$m,$w,$d,$h,$mn,$s);
}

###############################################################################
# Timezone critical dates

# NOTE: Although I would prefer to stick this routine in the
# Date::Manip::TZ module where it would be more appropriate, it must
# appear here as it will be used to generate the data that will be
# used by the Date::Manip::TZ module.
#
# This calculates a critical date based on timezone information. The
# critical date is the date (usually in the current time) at which
# the current timezone period ENDS.
#
# Input is:
#    $year,$mon,$flag,$num,$dow
#       This is information from the appropriate Rule line from the
#       zoneinfo files. These are used to determine the date (Y/M/D)
#       when the timezone period will end.
#    $isdst
#       Whether or not the next timezone period is a Daylight Saving
#       Time period.
#    $time,$timetype
#       The time of day when the change occurs. The timetype can be
#       'w' (wallclock time in the current period), 's' (standard
#       time which will match wallclock time in a non-DST period, or
#       be off an hour in a DST period), and 'u' (universal time).
#
# Output is:
#    $endUT, $endLT, $begUT, $begLT
#       endUT is the actual last second of the current timezone
#       period.  endLT is the same time expressed in local time.
#       begUT is the start (in UT) of the next time period. Note that
#       the begUT date is the one which actually corresponds to the
#       date/time specified in the input. begLT is the time in the new
#       local time. The endUT/endLT are the time one second earlier.
#
sub _critical_date {
   my($self,$year,$mon,$flag,$num,$dow,
      $isdst,$time,$timetype,$stdoff,$dstoff) = @_;

   #
   # Get the predicted Y/M/D
   #

   my($y,$m,$d) = ($year+0,$mon+0,1);

   if ($flag eq 'dom') {
      $d = $num;

   } elsif ($flag eq 'last') {
      my $ymd = $self->nth_day_of_week($year,-1,$dow,$mon);
      $d = $$ymd[2];

   } elsif ($flag eq 'ge') {
      my $ymd = $self->nth_day_of_week($year,1,$dow,$mon);
      $d = $$ymd[2];
      while ($d < $num) {
         $d += 7;
      }

   } elsif ($flag eq 'le') {
      my $ymd = $self->nth_day_of_week($year,-1,$dow,$mon);
      $d = $$ymd[2];
      while ($d > $num) {
         $d -= 7;
      }
   }

   #
   # Get the predicted time and the date (not yet taking into
   # account time type).
   #

   my($h,$mn,$s) = @{ $self->split('hms',$time) };
   my $date      = [ $y,$m,$d,$h,$mn,$s ];

   #
   # Calculate all the relevant dates.
   #

   my($endUT,$endLT,$begUT,$begLT,$offset);
   $stdoff = $self->split('offset',$stdoff);
   $dstoff = $self->split('offset',$dstoff);

   if ($timetype eq 'w') {
      $begUT = $self->calc_date_time($date,($isdst ? $stdoff : $dstoff), 1);
   } elsif ($timetype eq 'u') {
      $begUT = $date;
   } else {
      $begUT = $self->calc_date_time($date,$stdoff, 1);
   }

   $endUT    = $self->calc_date_time($begUT,[0,0,-1]);
   $endLT    = $self->calc_date_time($endUT,($isdst ? $stdoff : $dstoff));
   $begLT    = $self->calc_date_time($begUT,($isdst ? $dstoff : $stdoff));

   return ($endUT,$endLT,$begUT,$begLT);
}

###############################################################################
# Get a list of strings to try to parse.

sub _encoding {
   my($self,$string) = @_;
   my @ret;

   foreach my $enc (@{ $$self{'data'}{'calc'}{'enc_in'} }) {
      if (lc($enc) eq 'utf-8') {
         _utf8_on($string);
         push(@ret,$string) if is_utf8($string, 1);
      } elsif (lc($enc) eq 'perl') {
         push(@ret,encode_utf8($string));
      } else {
         my $tmp = $string;
         _utf8_off($tmp);
         $tmp = encode_utf8(decode($enc, $tmp));
         _utf8_on($tmp);
         push(@ret,$tmp) if is_utf8($tmp, 1);;
      }
   }

   return @ret;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
