#
#  WeekOfYear.pm
#
#  Synopsis: see POD at end of file
#
package Date::WeekOfYear;

use strict;
use warnings;
use Time::Local;
use parent 'Exporter';
use integer;    # Integer math, so we don't need floor

our $VERSION = '1.06';

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
    'mode' => [ qw( WeekOfYear WOY_OLD_MODE WOY_ISO_MODE ) ],
    'all'  => [ qw( WeekOfYear WOY_OLD_MODE WOY_ISO_MODE is_leap_year day_of_year jan1week_day WeekOfYear week_day week_number ) ],
    );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw( WeekOfYear );

# Weekday constants
use constant {
    SUNDAY    => 0,
    MONDAY    => 1,
    TUESDAY   => 2,
    WEDNESDAY => 3,
    THURSDAY  => 4,
    FRIDAY    => 5,
    SATURDAY  => 6,
    };

# Pseudo constants
sub WOY_OLD_MODE { 1 }
sub WOY_ISO_MODE { 2 }


sub is_leap_year
{

    my $year = shift;  # eg 2014

    # See POD for details of the algorithm.
    my $is_ly = ((($year % 4 == 0) && ($year % 100 != 0)) || ($year % 400 == 0)) ? 1 : 0;
    #print STDERR "is_ly=$is_ly $year\n";

    return $is_ly;
}

sub day_of_year
{
    # Return the day of the year, 1 being the first day (unlike localtime()) based on day of month and month
    my ($year, $month, $day) = @_;   # year is YYYY (eg 2014), month is 1-12, Jan=1, day is day of month

    # Days to mth start         Jan Feb Mar Apr May  Jun  Jul  Aug  Sep  Oct  Nov  Dec
    my @days_in_month = (undef, 0,  31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);

    my $doy = $day + $days_in_month[$month];

    # Need to adjust for leap year if after Feb
    $doy++ if ($month > 2 && is_leap_year($year));

    return $doy;
}

sub jan1week_day
{
    my ($year) = @_;   # year is YYYY (eg 2014)

    # Here weekday 1=Mon, 2=Tue, 7=Sun (not 0 as localtime())
    my $yy     = ($year - 1) % 100;
    my $jan1wd = 1 + (((($year -1 - $yy) / 100 ) % 4) * 5 + $yy + $yy/4) % 7;

    return $jan1wd;
}

sub week_day
{
    # Here weekday 1=Mon, 2=Tue, 3=Wed, 4=Thu,...7=Sun (not 0 as localtime())
    my ($year, $month, $day) = @_;   # year is YYYY (eg 2014), month is 1-12, Jan=1, day is day of month

    my $doy    = day_of_year($year, $month, $day);
    my $jan1wd = jan1week_day($year, $month, $day);

    my $wd = 1 + (($doy + $jan1wd - 2) % 7);

    return $wd;
}

sub week_number
{
    my ($year, $month, $day) = @_;   # year is YYYY (eg 2014), month is 1-12, Jan=1, day is day of month

    my $year_number = $year;
    my $week_number;


    my $is_leap_y      = is_leap_year($year);
    my $is_leap_prev_y = is_leap_year($year - 1);
    my $doy            = day_of_year($year, $month, $day);
    my $jan1wd         = jan1week_day($year, $month, $day);
    my $wd             = week_day($year, $month, $day);

    #print STDERR "year=$year, month=$month, day=$day, is_leap_y=$is_leap_y, is_leap_prev_y=$is_leap_prev_y, doy=$doy, jan1wd=$jan1wd, wd=$wd\n";

    # Does YYYYMMDD fall in year YYYY-1, weeknumber 52 or 53
    if ($doy <= (8 - $jan1wd) && $jan1wd > 4)
    {
        $year_number--;
        if ($jan1wd == 5 || ($jan1wd == 6 && $is_leap_prev_y))
        {
            $week_number = 53;
        }
        else
        {
            $week_number = 52;
        }
    }

    # Does YYYYMMDD fall in YYYY+1, weeknumber 1
    if ($year_number == $year)
    {
        my $days_in_year = $is_leap_y ? 366 : 365;

        if (($days_in_year - $doy) < (4 - $wd))
        {
            $year_number++;
            $week_number = 1;
        }
    }

    # Does YYYYMMDD fall in YYYY weeknumber 1 -> 53
    if ($year_number == $year)
    {
        $week_number = ($doy + 6 - $wd + $jan1wd)/7;
        $week_number-- if ($jan1wd > 4);
    }

    return ($week_number, $year_number);
}

sub WeekOfYear
{
    my ($time, $mode) = @_;

    # Make sure we have a mode
    $mode = 0 unless defined $mode;

    my ($tm_day, $tm_mth, $tm_year, $wkday, $yrday);

    # Post version 1.4 can be passed a hash ref for the time
    # The hash ref must have a year, month and day
    # This allows working past or before dates that can be handled by localtime
    if (($mode == 0 || $mode == WOY_ISO_MODE) && ref($time) eq 'HASH')
    {
        $tm_day  = $time->{day};
        $tm_mth  = $time->{month} - 1;
        $tm_year = $time->{year} - 1900;
    }
    else
    {
        # Set to the current time if nothing provided
        $time = time unless (defined($time) && $time =~ /^\s*\d+\s*$/);

        # wkday is the day of the week, 0=Sunday, 1=Monday.. 4=Thursday
        ($tm_day, $tm_mth, $tm_year, $wkday, $yrday) = (localtime($time))[3..7];
    }

    my $wkNo;

    if ($mode == WOY_OLD_MODE)
    {
        # Pre version 1.4 functionality

        # What is the week day for 1 Jan of the year in question
        my ($soywkday) = jan1week_day($tm_year + 1900);

        $wkNo = int($yrday / 7) + 1 + (($wkday < $soywkday)? 1:0);

        return wantarray ? ($wkNo, $tm_year + 1900) : $wkNo;
    }
    else
    {
        my ($w, $y) = week_number($tm_year + 1900, $tm_mth + 1, $tm_day);

        if ($mode == WOY_ISO_MODE)
        {
            # YYYY-WXX where YYYY is the year, W denotes the week, and XX is the week number, eg 1970-W53
            return sprintf('%d-W%02d', $y, $w);
        }
        else
        {
            # The new default output
            return wantarray ? ($w, $y) : $w;
        }
    }
}


1;
__END__

=head1 NAME

Date::WeekOfYear - Simple routine to return the ISO 8601 week of the year (as well as the ISO week year)

=head1 SYNOPSIS

  use Date::WeekOfYear;

  # Get the week number (and year for the end/start of year transitions)
  my ($wkNo, $year) = WeekOfYear();

  # Get the week number for the time passed in time_stamp
  my ($wkNo, $year) = WeekOfYear($time_stamp);

  # Use the data for someThing ...
  my $logFile = "/someDir/$year/someApp_$wkNo.log"

  # Only want the week number, don't care which year in the week around
  # the end/start of the year !
  my $weekNo = WeekOfYear();

  # Handle years outside of perls localtime functions - 04/01/2090
  my ($wkNo, $year) = WeekOfYear({ year => 2090, month => 1, day => 4});

  # or in ISO-8601 format YYYY-Wnn
  my $iso_8601_wkno = WeekOfYear({ year => 2090, month => 1, day => 4}, WOY_ISO_MODE);

  # Week number as per pre V1.5
  my ($wkNo, $year) = WeekOfYear($time_stamp, WOY_OLD_MODE);


=head1 DESCRIPTION

Date::WeekOfYear is small and efficient.  The only purpose is to return the
week of the year.  This can be called in either a scalar or list context.

In a scalar context, just the week number is returned (the year starts at week 1).

In a list context, both the week number and the year (YYYY) are returned.  This
ensures that you know which year the week number relates too.  This is only an
issue in the week where the year changes (ie depending on the day you can be in
either week 52, week 53 or week 1.

B<NOTE> The year returned is not always the same as the Gregorian year for that day
for further details see ISO 8601.

To obtain the old functionality, a mode is also passed, WOY_OLD_MODE.  Note you
need to use the ':mode' or ':all' tags to use to gain access to WOY_OLD_MODE.

If mode WOY_ISO_MODE is used the output will be in the ISO 8601 format YYYY-Wxx
where YYYY is the year and xx is the two digit week number and 'W' denotes week.

=head1 MODES

If a second argument, the mode, is provided then either the pre version 1.5 mode
is activated or the output is format as per ISO 8601 as YYYY-Wxx

The modes are B<WOY_OLD_MODE> and B<WOY_ISO_MODE>

=head2 WOY_OLD_MODE

Used to select the old mode, eg


 ($wkNo, $year) = WeekOfYear($time_stamp, WOY_OLD_MODE);

=head2 WOY_ISO_MODE

Use to select the output formatted as YYYY-Wxx, eg

 $iso_8601_wkno = WeekOfYear({ year => 2090, month => 1, day => 4}, WOY_ISO_MODE);

=head1 DEFAULT EXPORT

=head2 WeekOfYear

The function, see SYNOPSIS above

=head1 OTHER FUNCTIONS

These other functions are available if the use tag ':all' is used, eg:

 use Date::WeekOfYear ':all';

=head2 day_of_year

Returns the day of the year, 1 being the first day.  The last day is either 365 or 366,
the latter if the year is a leap year.  Expected arguments are the year, month and day
as numeric values.  The year is expected as yyyy, the month as 1 to 12 for Jan to Dec
and the day of the month.

=head2 is_leap_year

Returns true (1) if the year is a leap year, otherwise false (0).  The expected argument
is the year as a numeric value of format yyyy, eg 2014.

In general terms the algorithm for calculating a leap year is as follows...

A year will be a leap year if it is divisible by 4 but not by 100. If a
year is divisible by 4 and by 100, it is not a leap year unless it is
also divisible by 400.  Thus years such as 1996, 1992, 1988 and so on
are leap years because they are divisible by 4 but not by 100.
For century years, the 400 rule is important. Thus, century years 1900,
1800 and 1700 while all still divisible by 4 are also exactly divisible
by 100. As they are not further divisible by 400, they are not leap years.


=head2 jan1week_day

Returns the week_day of the 1st of January for the year in question.
The week_day is a numeric value indicating the day and differs from
that returned by the core function localtime() in that Sunday is 7
rather than 0.

The returned values are:

 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat and 7=Sun

The expected argument is the year in yyyy format, eg 2014.

=head2 week_day

week_day takes the year (yyyy eg 2014), month (1 to 12) and month_day as arguments and returns the week day.

The week day returned is an integer representing the day of the week where:

 1 = Monday
 2 = Tuesday
 3 = Wednesday
 4 = Thursday
 5 = Friday
 6 = Saturday
 7 = Sunday.

B<Note> this is similar to that returned by localtime except that Sunday is 7 rather than 0

=head2 week_number

week_number takes the year (yyyy eg 2014), month (1 to 12) and month_day as arguments and returns
the week number as defined by ISO-8061.  That is week 1 starts on a Monday and contains the first
Thursday in the year.  As a result week 1 can start in the previous year and a year can have either
52 or 53 weeks.

=head1 CHANGES

As of version 1.5 the ISO 8601 week number is calculated.  For backwards compatibility
a flag can be passed after the time to give the previous functionality.

For example:

  my $weekNo = WeekOfYear(undef, 1);  # Week number now in pre ISO 8601 mode
  or
  my $weekNo = WeekOfYear($the_time, 1);  # Week number for $the_time in pre ISO 8601 mode


=head1 ISO 8601

Weeks in a Gregorian calendar year can be numbered for each year. This style of
numbering is commonly used (for example, by schools and businesses) in some European
and Asian countries, but rare elsewhere.

ISO 8601 includes the ISO week date system, a numbering system for weeks - each week
begins on a Monday and is associated with the year that contains that week's Thursday
(so that if a year starts in a long weekend Friday-Sunday, week number one of the year
will start after that). For example, week 1 of 2004 (2004W01) ran from Monday 29
December 2003 to Sunday, 4 January 2004, because its Thursday was 1 January 2004,
whereas week 1 of 2005 (2005W01) ran from Monday 3 January 2005 to Sunday 9 January
2005, because its Thursday was 6 January 2005 and so the first Thursday of 2005. The
highest week number in a year is either 52 or 53 (it was 53 in the year 2004).

An ISO week-numbering year (also called ISO year informally) has 52 or 53 full weeks.
That is 364 or 371 days instead of the usual 365 or 366 days.  The extra week is
referred to here as a leap week, although ISO 8601 does not use this term.  Weeks start
with Monday. The first week of a year is the week that contains the first Thursday
(and, hence, 4 January) of the year. ISO week year numbering therefore slightly
deviates from the Gregorian for some days close to 1 January.

=head2 Calculations

=head3 Ordinal Day

If the ordinal date is not known, it can be computed by any of several methods.
perhaps the most direct is a table such as the following:

 To the day of:  Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
 Add:            0   31  59  90  120 151 181 212 243 273 304 334
 For leap years: 0   31  60  91  121 152 182 213 244 274 305 335

=head3 Week Number

Calculating the week number of a given date

The week number of any date can be calculated, given its ordinal date (i.e. position
within the year) and its day of the week.

B<Method:> Using ISO weekday numbers (running from 1 for Monday to 7 for Sunday),
subtract the weekday from the ordinal date, then add 10. Divide the result by 7.
Ignore the remainder; the quotient equals the week number. If the week number
thus obtained equals 0, it means that the given date belongs to the preceding
(week-based) year. If a week number of 53 is obtained, one must check that the
date is not actually in week 1 of the following year.

    week(date) = int((ordinal(date) - weekday(date) + 10)/7)

Example: Friday 26 September 2008

    Ordinal day: 244 + 26 = 270
    Weekday: Friday = 5
    270 - 5 + 10 = 275
    275 / 7 = 39.28
    Result: Week 39

=head3 53 Week Years

The long years, with 53 weeks in them, can be described by any of the following equivalent definitions:

 - any year starting on Thursday and any leap year starting on Wednesday
 - any year ending on Thursday and any leap year ending on Friday
 - years in which 1 January and 31 December (in common years) or either (in leap years) are Thursdays


=head3 Day of Week

The tabular forerunner to Tondering's algorithm is embodied in the following
ANSI C function. With minor changes, it is adaptable to other high level
programming languages such as APL2. (A 6502 assembly language version
exists as well.)  Devised by Tomohiko Sakamoto in 1993, it is accurate
for any Gregorian date:

   int dow(int y, int m, int d)
   {
       static int t[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
       y -= m < 3;
       return (y + y/4 - y/100 + y/400 + t[m-1] + d) % 7;
   }

The function returns 0 = Sunday, 1 = Monday, etc.


=head1 KNOWN ISSUES

B<Versions prior to 1.5 did not follow ISO 8601.>

None, however please contact the author at gng@cpan.org should you
find any problems and I will endevour to resolve then as soon as
possible.

=head1 AUTHOR

 Greg George, IT Technology Solutions P/L, Australia
 Mobile: +61-404-892-159, Email: gng@cpan.org

=head1 SEE ALSO

Date::Parse or check CPAN http://search.cpan.org/search?query=Date&mode=all

=head1 ACKNOWLEDGEMENTS

Thanks to Alexandr Ciornii for the V1.3 updates
Thanks to Niel Bowers for [rt.cpan.org #93599] Not clear what type of week number is returned

=head1 Log

Revision 1.6  2014/04/09 Greg
 - Allow extended date coverage - past dates handled by localtime - using hash ref argument year, month, day
 - Added mode for ISO 8601 output YYYY-Wxx

Revision 1.5  2014/03/16 Greg
 - Updated to conform to ISO 8601
 - Added compatability flag to allow backwards usage

Revision 1.4  2009/06/21 07:29:05  Greg
- Added ACKNOWLEDGEMENTS

Revision 1.3  2009/06/20 09:31:39  Greg
- Real tests with Test::More
- Tests moved to t/
- Better Makefile.PL
- Now WeekOfYear can take an argument (unixtime)

Revision 1.2  2006/06/11 02:28:55  Greg
- Correction to name of function

Revision 1.1.1.1  2004/08/09 11:07:15  Greg
- Initial release to CPAN


=head2 CVS ID

$Id: WeekOfYear.pm,v 1.4 2009/06/21 07:29:05 Greg Exp $

=cut
