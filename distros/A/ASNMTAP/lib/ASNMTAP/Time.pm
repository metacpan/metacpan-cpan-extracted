# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Time
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Time;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Date::Calc qw(Add_Delta_Days Add_Delta_YMD Delta_Days Week_of_Year);
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Time::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Time::EXPORT_TAGS = (ALL       => [ qw(SEC MIN HOUR DAY WEEK
                                                   &get_timeslot
                                                   &get_yearMonthDay
                                                   &get_yyyymmddhhmmsswday
                                                   &get_datetimeSignal &get_datetime
                                                   &get_logfiledate &get_csvfiledate &get_csvfiletime
                                                   &get_epoch &get_week &get_wday &get_hour &get_min &get_seconds &get_day &get_month &get_year) ],

                                 EPOCHTIME => [ qw(SEC MIN HOUR DAY WEEK) ],

                                 LOCALTIME => [ qw(&get_timeslot
                                                   &get_yearMonthDay
                                                   &get_yyyymmddhhmmsswday
                                                   &get_datetimeSignal &get_datetime
                                                   &get_logfiledate &get_csvfiledate &get_csvfiletime
                                                   &get_epoch &get_week &get_wday &get_hour &get_min &get_seconds &get_day &get_month &get_year) ] );

  @ASNMTAP::Time::EXPORT_OK   = ( @{ $ASNMTAP::Time::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Time::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Constants = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

use constant SEC  => 1;
use constant MIN  => SEC * 60;
use constant HOUR => MIN * 60;
use constant DAY  => HOUR * 24;
use constant WEEK => DAY * 7;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Private subs  = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _checkReadOnly0 { if ( @_ > 0 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkReadOnly1 { if ( @_ > 1 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkReadOnly2 { if ( @_ > 2 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Epochtime:
#
# To get the current time, Perl has a built-in function called time().
# This simply returns the number of non-leap seconds that have elapsed 
# since 00:00:00 January 1, 1970 UTC.
#
# current epochtime equal to time()
#
# timelocal((localtime)[0,1,2,3,4,5]) = timelocal(localtime)

# List Element Description:
#
# localtime() converts the UTC time into the correct values for the local time zone. 
#
# localtime() uses the current time -> localtime(time()) equal to localtime(time)
#
# (localtime)[0]: sec Seconds after each minute (0 - 59)
# (localtime)[1]: min Minutes after each hour (0 - 59)
# (localtime)[2]: hour Hour since midnight (0 - 23)
# (localtime)[3]: monthday Numeric day of the month (1 - 31)
# (localtime)[4]: month Number of months since January (0 - 11)
# (localtime)[5]: year Number of years since 1900
# (localtime)[6]: weekday Number of days since Sunday (0 - 6)
# (localtime)[7]: yearday Number of days since January 1 (0 - 365)
# (localtime)[8]: isdaylight A flag for daylight savings time
#
# ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime( time() );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_timeslot {
  &_checkReadOnly1;

  my $timeslot;

  if (defined $_[0]) {
    $timeslot = timelocal ( 0, (localtime($_[0]))[1,2,3,4,5] );
  } else {
    $timeslot = timelocal ( 0, (localtime)[1,2,3,4,5] );
  }

  return ( $timeslot );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_yearMonthDay {
  &_checkReadOnly1;

  if (defined $_[0]) {
    return (sprintf ("%04d%02d%02d", (localtime($_[0]))[5]+1900, (localtime($_[0]))[4]+1, (localtime($_[0]))[3]));
  } else {
    return (sprintf ("%04d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]));
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_yyyymmddhhmmsswday { &_checkReadOnly0; return sprintf ("%04d:%02d:%02d:%02d:%02d:%02d:%d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0,6]); }

sub get_datetimeSignal     { &_checkReadOnly0; return sprintf ("%04d/%02d/%02d %02d:%02d:%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0]); }
sub get_datetime           { &_checkReadOnly0; return sprintf ("%02d%02d%02d%02d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0]); }

sub get_logfiledate        { &_checkReadOnly0; return sprintf ("%04d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]); }
sub get_csvfiledate        { &_checkReadOnly0; return sprintf ("%04d/%02d/%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]); }
sub get_csvfiletime        { &_checkReadOnly0; return sprintf ("%02d:%02d:%02d", (localtime)[2,1,0]); }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub get_epoch {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;
  my ($string, $time) = @_;

  my $delta = 0;
  my $tTime = ( defined $time ? $time : time() );
  my ($sign, $number, $type) = ( $string =~ /^\s*([+-])\s*(\d+)\s+(sec|min|hour|(?:day|week|month|year))s?\s*$/ );

  if ( defined $type ) {
    my $deltaDays = 0;
    my $multiplyer = ($sign eq '+' ? 1 : -1);
    my $signedNumber = $number * $multiplyer;
    my ($year, $month, $day) = ( (localtime($tTime))[5]+1900, (localtime($tTime))[4]+1, (localtime($tTime))[3] );

    for ($type) {
      /^sec$/         && do { $delta = $signedNumber * SEC;  last; };
      /^min$/         && do { $delta = $signedNumber * MIN;  last; };
      /^hour$/        && do { $delta = $signedNumber * HOUR; last; };
      /^day(?:s)?$/   && do { $delta = $signedNumber * DAY;  last; };
      /^week(?:s)?$/  && do { $delta = $signedNumber * WEEK; last; };
      /^month(?:s)?$/ && do { my $dYear  = int($number / 12) * $multiplyer;
                              my $dMonth = $number % 12 * $multiplyer;
                              $deltaDays = Delta_Days ( $year, $month, $day, Add_Delta_YMD ( $year, $month, $day, $dYear, $dMonth, 0 ) ); 
                              $delta = $deltaDays * DAY; last; };
      /^year(?:s)?$/  && do { $deltaDays = Delta_Days ($year, $month, $day, ( $year + $signedNumber ), $month, $day); 
                              $delta = $deltaDays * DAY; last; };
    }
  } elsif ( ($type) = ( $string =~ /^\s*(today|now|tomorrow|yesterday)\s*$/ ) ) {
    for ($type) {
      /^today|now$/   && do { $delta = 0;  last; };
      /^tomorrow$/    && do { $delta += DAY;  last; };
      /^yesterday$/   && do { $delta -= DAY;  last; };
    }
  } else {
    return ( undef );
  }

  return ( $tTime + $delta );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_week {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;

  my $time = get_epoch($_[0], $_[1]);
  my ($week, $year) = Week_of_Year ( (localtime($time))[5]+1900, (localtime($time))[4]+1, (localtime($time))[3] );
  $week = sprintf ("%02d", $week);
  $year = sprintf ("%04d", $year);
  return ( $week, $year );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_wday {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;

  return ( (localtime(get_epoch($_[0], $_[1])))[6] );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_hour {
  &_checkReadOnly1; 

  if ( defined $_[0] ) {
    return sprintf ("%02d", (localtime($_[0]))[2]);
  } else {
    return sprintf ("%02d", (localtime)[2]);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_min {
  &_checkReadOnly1; 

  if ( defined $_[0] ) {
    return sprintf ("%02d", (localtime($_[0]))[1]);
  } else {
    return sprintf ("%02d", (localtime)[1]);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_seconds { 
  &_checkReadOnly1; 

  if ( defined $_[0] ) {
    return sprintf ("%02d", (localtime($_[0]))[0]);
  } else {
    return sprintf ("%02d", (localtime)[0]);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_day {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;

  return ( sprintf ("%02d", (localtime(get_epoch($_[0], $_[1])))[3]) );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_month {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;

  return ( sprintf ("%02d", (localtime(get_epoch($_[0], $_[1])))[4] +1) );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_year {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly2;

  return ( sprintf ("%04d", (localtime(get_epoch($_[0], $_[1])))[5] +1900) );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Time is a Perl module that provides date and time functions used by ASNMTAP and ASNMTAP-based applications and plugins.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut