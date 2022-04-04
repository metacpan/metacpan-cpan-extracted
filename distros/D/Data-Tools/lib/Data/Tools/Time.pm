##############################################################################
#
#  Data::Tools perl module
#  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::Time;
use strict;
use Exporter;
use Carp;
use Data::Tools;
use Date::Calc qw(:all);
use Time::JulianDay;

our $VERSION = '1.28';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                unix_time_diff_in_words
                unix_time_diff_in_words_relative
    
                julian_date_diff_in_words
                julian_date_diff_in_words_relative

                get_local_time_only
                get_local_julian_day
                get_local_year
                get_year_month_days

                julian_date_from_utime
                julian_date_add_ymd
                julian_date_to_ymd
                julian_date_from_ymd

                julian_date_goto_first_dom
                julian_date_goto_last_dom
                julian_date_get_dow
                julian_date_month_days_ym
                julian_date_month_days
                julian_date_get_dow

                utime_from_julian_date
                utime_from_ymdhms
                utime_to_ymdhms
                
                utime_split_to_jdt
                utime_split_to_utt
                utime_join_jdt
                utime_join_utt

                utime_add_ymdhms
                utime_add_ymd
                utime_add_hms

                utime_month_days

                utime_goto_midnight
                utime_goto_first_dom
                utime_goto_last_dom
                utime_goto_first_doy
                utime_goto_last_doy
                utime_get_dow
                utime_get_moy
                
                );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );

##############################################################################

sub unix_time_diff_in_words
{
  my $utd = abs( int( shift() ) ); # absolute difference in seconds

  if( $utd < 1 )
    {
    return "now";
    }
  if( $utd < 60   ) # less than 1 minute
    {
    my $ss = str_countable( $utd, "second", "seconds" );
    return "$utd $ss";
    };
  if( $utd < 60*60 ) # less than 1 hour
    {
    my $m  = int( $utd / 60 );
    my $ms = str_countable( $m, "minute", "minutes" );
    return "$m $ms";
    };
  if( $utd < 2*24*60*60 ) # less than 2 days (48 hours)
    {
    my $h = int( $utd / ( 60 * 60 ) );
    my $m = int( $utd % ( 60 * 60 ) / 60 );
    my $hs = str_countable( $h, "hour",   "hours"   );
    my $ms = str_countable( $m, "minute", "minutes" );
    return "$h $hs, $m $ms";
    };
  if( $utd < 7*24*60*60 ) # less than 1 week (168 hours)
    {
    my $d  = int( $utd / ( 24 * 60 * 60 ) );
    my $h  = int( $utd % ( 24 * 60 * 60 ) / ( 60 * 60 ) );
    my $ds = str_countable( $d, "day",    "days"    );
    my $hs = str_countable( $h, "hour",   "hours"   );
    return "$d $ds, $h $hs";
    };
  if( $utd < 60*24*60*60 ) # less than 2 months
    {
    my $d  = int( $utd / ( 24 * 60 * 60 ) );
    my $ds = str_countable( $d, "day",    "days"    );
    return "$d $ds";
    };
  if( 42 ) # more than 2 months
    {
    my $m  = int( $utd / ( 30*24*60*60 ) ); # "month" is approximated to 30 days
    my $ms = str_countable( $m, "month", "months" );
    return "$m $ms";
    }
}

sub unix_time_diff_in_words_relative
{
  my $utd = int( shift() ); # relative difference in seconds

  my $uts = unix_time_diff_in_words( $utd );

  if( $utd < 0 )
    {
    return "after $uts";
    }
  elsif( $utd > 0 )
    {
    return "before $uts";
    }
  else
    {
    return $uts;
    }
}

##############################################################################

sub julian_date_diff_in_words
{
  my $jdd  = abs( int( shift() ) ); # absolute difference in days

  if( $jdd < 90 )
    {
    my $d  = int( $jdd );
    my $ds = str_countable( $d, "day", "days" );
    return "$d $ds";
    }
  if( 42 )
    {
    my $m  = int( $jdd / 30 );
    my $ms = str_countable( $m, "month", "months" );
    return "$m $ms";
    };
}

sub julian_date_diff_in_words_relative
{
  my $jdd = int( shift() ); # relative difference in days

  if( $jdd == 0 )
    {
    return "today";
    }
  if( $jdd == -1 )
    {
    return "tomorrow";
    }
  if( $jdd == +1 )
    {
    return "yesterday";
    }

  my $jds = julian_date_diff_in_words( $jdd );
  if( $jdd < 0 )
    {
    return "in $jds";
    }
  elsif( $jdd > 0 )
    {
    return "before $jds";
    }
  else
    {
    return $jds;
    }
}

##############################################################################

# returns time of the day (in the current day only)
sub get_local_time_only
{
  my ( $s, $m, $h ) = localtime( shift() || time() );
  return $h*60*60 + $m*60 + $s;
}

sub get_local_julian_day
{
  return local_julian_day( time() );
}

sub get_local_year
{
   my ( $y ) = inverse_julian_day( local_date() );
   return $y;
}

sub get_year_month_days
{
  return Days_in_Month( @_ );
}

# return julian date, moved with positive or negative deltas ( y, m, d ) 
sub julian_date_add_ymd
{
  my $wd = shift; # original/work date
  my $dy = shift; # add delta year
  my $dm = shift; # add delta month
  my $dd = shift; # add delta day

  my ( $y, $m, $d ) = inverse_julian_day( $wd );

  ( $y, $m, $d ) = Add_Delta_YMD( $y, $m, $d, $dy, $dm, $dd );

  $wd = julian_day( $y, $m, $d );

  return $wd;

}

# return ( year, month, day ) from julian date
sub julian_date_to_ymd
{
  my $wd = shift; # original/work date

  my ( $y, $m, $d ) = inverse_julian_day( $wd );
  return ( $y, $m, $d );
}

# return julian date from ( year, month, day )
sub julian_date_from_ymd
{
  my $y = shift; # set year
  my $m = shift; # set month
  my $d = shift; # set day

  my $wd = julian_day( $y, $m, $d );
  return $wd;
}

# return julian date, moved to the first day of its month
sub julian_date_goto_first_dom
{
  my $wd = shift; # original/work date

  my ( $y, $m, $d ) = julian_date_to_ymd( $wd );
  return julian_date_from_ymd( $y, $m, 1 );
}

# return julian date, moved to the last day of its month
sub julian_date_goto_last_dom
{
  my $wd = shift; # original/work date

  my ( $y, $m, $d ) = julian_date_to_ymd( $wd );
  return julian_date_from_ymd( $y, $m, Days_in_Month( $y, $m ) );
}

# return day of the week, for julian date -- 0 Sun .. 6 Sat
sub julian_date_get_dow
{
  my $d = shift; # original date

  return day_of_week( $d );
}

# return month days count for given ( year, month ) (not strictly julian_ namespace)
sub julian_date_month_days_ym
{
  my $y = shift; # set year
  my $m = shift; # set month

  return Days_in_Month( $y, $m );
}

# return month days count for given julian date
sub julian_date_month_days
{
  my $d = shift;

  return Days_in_Month( ( julian_date_to_ymd( $d ) )[0,1] );
}

##############################################################################

sub utime_from_julian_date
{
  my ( $year, $month, $day ) = inverse_julian_day( shift() );
  return Mktime( $year, $month, $day, 0, 0, 0 );
}

sub utime_from_ymdhms
{
  my @args = ( @_, 0, 0, 0, );
  return Mktime( @args[ 0 .. 5 ] );
}

sub utime_to_ymdhms
{
  return Localtime(shift());
}

# returns local julian day and time from unix time
sub utime_split_to_jdt
{
  my ($year,$month,$day,  $hour,$min,$sec,  $doy,$dow,$dst) = Localtime(shift());
  my $jd = julian_day( $year, $month, $day );
  my $tt = $hour * 60 * 60 + $min * 60 + $sec;
  return ( $jd, $tt );
}

# returns unix time of the 00:00 of the day given as utime and time from unix time
sub utime_split_to_utt
{
  my ($year,$month,$day,  $hour,$min,$sec,  $doy,$dow,$dst) = Localtime(shift());
  
  my $ut = Mktime( $year, $month, $day, 0, 0, 0 );
  my $tt = $hour * 60 * 60 + $min * 60 + $sec;
  return ( $ut, $tt );
}

# joins julian date and day time only into unix time
sub utime_join_jdt
{
  my $jd = shift;
  my $tt = shift;
  
  return utime_from_julian_date( $jd ) + $tt;
}

# joins unix time of the day midnight and day time only into unix time
# mostly redundant but exists for completeness
sub utime_join_utt
{
  return shift() + shift();
}

sub utime_add_ymdhms
{
  my $tt = shift;
  my ( $dy, $do, $dd, $dh, $dm, $ds ) = @_;
  
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  
  ( $year, $month, $day, $hour, $min, $sec ) =
      Add_Delta_YMDHMS( $year, $month, $day, $hour, $min, $sec,
                        $dy,   $do,    $dd,  $dh,   $dm,  $ds  );

  return Mktime( $year, $month, $day, $hour, $min, $sec );
}

sub utime_add_ymd
{
  my $tt = shift;
  my ( $dy, $do, $dd ) = @_;
  return utime_add_ymdhms( $tt, $dy, $do, $dd, 0, 0, 0 );
}

sub utime_add_hms
{
  my $tt = shift;
  my ( $dh, $dm, $ds ) = @_;
  return utime_add_ymdhms( $tt, 0, 0, 0, $dh, $dm, $ds );
}

sub utime_month_days
{
  return get_year_month_days( ( utime_to_ymdhms( shift() ) )[ 0, 1 ] );
}

sub utime_goto_midnight
{
  return ( utime_split_to_utt( shift() ) )[0];
}

sub utime_goto_first_dom
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return Mktime( $year, $month, 1, 0, 0, 0 );
}

sub utime_goto_last_dom
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return Mktime( $year, $month, Days_in_Month( $year, $month ), 0, 0, 0 );
}

sub utime_goto_first_doy
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return Mktime( $year, 1, 1, 0, 0, 0 );
}

sub utime_goto_last_doy
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return Mktime( $year, 12, 31, 0, 0, 0 );
}

sub utime_get_dow
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return Day_of_Week( $year, $month, $day );
}

sub utime_get_moy
{
  my $tt = shift;
  my ( $year, $month, $day, $hour, $min, $sec ) = Localtime( $tt );
  return $month;
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Time provides set of basic functions for time processing.

=head1 SYNOPSIS

  use Data::Tools::Time qw( :all );  # import all functions
  use Data::Tools::Time;             # the same as :all :) 
  use Data::Tools::Time qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  my $time_diff_str     = unix_time_diff_in_words( $time1 - $time2 );
  my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );

  # --------------------------------------------------------------------------
    
  my $date_diff_str     = julian_date_diff_in_words( $date1 - $date2 );
  my $date_diff_str_rel = julian_date_diff_in_words_relative( $date1 - $date2 );

  # --------------------------------------------------------------------------

  # return seconds after last midnight, i.e. current day time
  my $seconds_in_the_current_day = get_local_time_only()
  
  # returns current julian day
  my $jd = get_local_julian_day()
  
  # returns current year
  my $year = get_local_year()
  
  # gets current julian date, needs Time::JulianDay
  my $jd = local_julian_day( time() );
  # or
  my $jd = get_local_julian_day();

  # move current julian date to year ago, one month ahead and 2 days ahead
  $jd = julian_date_add_ymd( $jd, -1, 1, 2 );

  # get year, month and day from julian date
  my ( $y, $m, $d ) = julian_date_to_ymd( $jd );

  # get julian date from year, month and day
  $jd = julian_date_from_ymd( $y, $m, $d );

  # move julian date ($jd) to the first day of its current month
  $jd = julian_date_goto_first_dom( $jd );

  # move julian date ($jd) to the last day of its current month
  $jd = julian_date_goto_last_dom( $jd );

  # get day of week for given julian date ( 0 => Mon .. 6 => Sun )
  my $dow = julian_date_get_dow( $jd );
  print( ( qw( Mon Tue Wed Thu Fri Sat Sun ) )[ $dow ] . "\n" );

  # get month days count for the given julian date's month
  my $mdays = julian_date_month_days( $jd );

  # get month days count for the given year and month
  my $mdays = julian_date_month_days_ym( $y, $m );

=head1 FUNCTIONS

=head2 unix_time_diff_in_words( $unix_time_diff )

Returns human-friendly text for the given time difference (in seconds).
This function returns absolute difference text, for relative 
(before/after/ago/in) see unix_time_diff_in_words_relative().

=head2 unix_time_diff_in_words_relative( $unix_time_diff )

Same as unix_time_diff_in_words() but returns relative text
(i.e. with before/after/ago/in)

=head2 julian_date_diff_in_words( $julian_date_diff );

Returns human-friendly text for the given date difference (in days).
This function returns absolute difference text, for relative 
(before/after/ago/in) see julian_day_diff_in_words_relative().

=head2 julian_date_diff_in_words_relative( $julian_date_diff );

Same as julian_date_diff_in_words() but returns relative text
(i.e. with before/after/ago/in)

=head1 TODO

  * support for language-dependent wording (before/ago)
  * support for user-defined thresholds (48 hours, 2 months, etc.)

=head1 REQUIRED MODULES

Data::Tools::Time uses:

  * Data::Tools (from the same package)
  * Date::Calc
  * Time::JulianDay

=head1 TEXT TRANSLATION NOTES

time/date difference wording functions does not have translation functions
and return only english text. This is intentional since the goal is to keep
the translation mess away but still allow simple (yet bit strange) 
way to translate the result strings with regexp and language hash:
  
  my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );
  
  my %TRANS = (
              'now'       => 'sega',
              'today'     => 'dnes',
              'tomorrow'  => 'utre',
              'yesterday' => 'vchera',
              'in'        => 'sled',
              'before'    => 'predi',
              'year'      => 'godina',
              'years'     => 'godini',
              'month'     => 'mesec',
              'months'    => 'meseca',
              'day'       => 'den',
              'days'      => 'dni',
              'hour'      => 'chas',
              'hours'     => 'chasa',
              'minute'    => 'minuta',
              'minutes'   => 'minuti',
              'second'    => 'sekunda',
              'seconds'   => 'sekundi',
              );
              
  $time_diff_str_rel =~ s/([a-z]+)/$TRANS{ lc $1 } || $1/ge;

I know this is no good for longer sentences but works fine in this case.

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  


=cut

##############################################################################
1;
