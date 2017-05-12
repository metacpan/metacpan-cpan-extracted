=head1 NAME

Date::Time2fmtstr - Functions to format Perl time integers to strings based on a "Picture" format string.

=head1 AUTHOR

Jim Turner

(c) 2015, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 SYNOPSIS

use Date::Time2fmtstr;

print time2str(time, 'mm-dd-yyyy hh:mi PM');

=head1 DESCRIPTION

Date::Time2fmtstr provides a single function B<time2str> that accepts a standard Perl (Unix) 
"time" value (a large integer equivalent to the number of seconds since 1980) and converts it 
to a string value based on a I<format-string> consisting of special substrings which represent 
the various parts of a date and time value.  It returns a string that is essentially the 
same as the original I<format-string> with each of these special substrings replaced with 
the corresponding date/time value.

=head1 METHODS

=over 4

=item <$string> = B<time2str>(I<time>, I<format-string>);

Returns a string corresponding to the specified I<format-string> with each special substring 
replaced with the corresponding date/time data field.  For example:

$s = B<time2str>(1452324044, 'mm-dd-yyyy hh:mi PM (Day) (Month)');

would set $s to '01-09-2016 01:20 AM (Sat) (January)'.

=item B<Special Formatting Substrings>

There are numerous choices of special format substrings which can be used in an infinite 
number of combinations to produce the desired results.  They are listed below:

=over 4

B<month> - The Full name of the month in all lower case, ie. "january".

B<Month> - The Full name of the month capitalized, ie. "January". 

B<MONTH> - The Full name of the month all capitalized, ie. "JANUARY". 

B<dayofweek> - Day of the week in all lower case, ie. "sunday". 

B<Dayofweek> - Day of the week capitalized, ie. "Sunday". 

B<DAYOFWEEK> - Day of the week all capitalized, ie. "SUNDAY". 

B<day> - Three letter abbreviation of the day of the week in all lower case, ie. "sun". 

B<Day> - Three letter abbreviation of the day of the week capitalized, ie. "Sun". 

B<DAY> - Three letter abbreviation of the day of the week all capitalized, ie. "SUN". 

B<ddd> - Num. of days since beginning of year.

B<dd> - Day of month (2 digits, left padded with a zero if needed), ie. "01".

B<d1> - Day of month (1 or 2 digits, as needed), ie. "1". 

B<d0>, B<d> - Numeric day of the week zero-based (Sunday=0, Monday=1, ... Saturday=6). 

B<d1> - Numeric day of the week one-based (Sunday=1, Monday=2, ... Saturday=7). 

B<yyyymmdd> - Numeric date in 8 digits, ie. "20150107" for January 7, 2015. 

B<yyyy>, B<rrrr> - Year in 4 digits.

B<yy>, B<rr> - Year in last 2 digits.

B<hh24> - Military time (hours and minutes: 24 hours, no colon).

B<hh> - Hour in common format, ie. 01-12.

B<h1> - Hour in common format, 1 or 2 digits, as needed, ie. 1-12. 

B<mi> - Minute, ie. 00-59. 

B<mm> - Number of month (2 digits, left padded with a zero if needed), ie. "01" for January. 

B<mon> - Three letter abbreviation of the month, in lower case, ie. "jan" for January. 

B<HH> - Hour in 24-hour format, 2 digits, left padded with a zero if needed, ie. 00-23. 

B<H1> - Hour in 24-hour format, 1 or 2 digits, as needed, ie. 0-23. 

B<Mon> - Three letter abbreviation of the month, capitalized, ie. "Jan" for January. 

B<MON> - Three letter abbreviation of the month all capitalized, ie. "JAN". 

B<m1> - Number of month (1 or 2 digits, as needed), ie. "1" for January. 

B<sssss> - Seconds since start of day. 

B<ss> - Seconds since start of last minute (2 digits), ie. 00-59. 

B<am>, B<pm> - display "am" if between Midnight and Noon, "pm" otherwise (both specifiers are identical). 

B<AM>, B<PM> - display "AM" if between Midnight and Noon, "PM" otherwise (both specifiers are identical). 

B<a>, B<p> - display "a" if between Midnight and Noon, "p" otherwise (both specifiers are identical). 

B<A>, B<P> - display "A" if between Midnight and Noon, "P" otherwise (both specifiers are identical). 

B<rm> - Roman numeral for the month (i-xii) in lower case. 

B<RM> - Roman numeral for the month (I-XII) in upper case. 

B<ww> - Number of week of the year (00-51). 

B<q> - Number of the quarter of the year - (1-4).

=back

=back

=head1 KEYWORDS

L<Date::Fmtstr2time>, L<String::PictureFormat>, formatting, picture_clause, strings

=cut

package Date::Time2fmtstr;

use strict;
#use warnings;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.02';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(time2str);

my @inputs = ();

sub time2str
{
	my $s = $_[0] || time;
	my $f = $_[1] || 'yyyymmdd';

	my @fmts = split(/\b/, $f);
	my @today = localtime(time);
	@inputs = localtime($s);
	my $resORerr = '';
	my $rtnTime = '';
	my $fn;

OUTER1:	for (my $i=0;$i<=$#fmts;$i++)
	{
		if ($fmts[$i] =~ /\W/o)
		{
			$resORerr .= $fmts[$i];
			next;
		}
MIDDLE1:		while ($fmts[$i] =~ /\w/o)
		{
			foreach my $f (qw(month Month MONTH dayofweek Dayofweek DAYOFWEEK day Day DAY
					ddd dd d1 d0 yyyymmdd yyyy yy hh24 hh HH H1 h1 mi mm mon 
					Mon MON m1 sssss ss am pm AM PM a p A P rm RM rr d ww q))
			{
				if ($fmts[$i] =~ s/^$f//)
				{
					$fn = '_toc_'.$f;
no strict 'refs';
					$resORerr .= &$fn();
					next MIDDLE1;
				}
			}
			if ($fmts[$i] =~ s/^(\w)(\w+)$/$2/)
			{
				$resORerr .= $1;
				next MIDDLE1;
			}
			$resORerr .= $fmts[$i];
			next OUTER1;
		}
	}

	return $resORerr;
}

sub _toc_month
{
	my @mthlist = (qw(january february march april may june july august september 
			october november december));

	return "Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
	return $mthlist[$inputs[4]];
}

sub _toc_Month
{
	my $mymonth = &_toc_month();
	return "\u\L$mymonth\E"
}

sub _toc_MONTH
{
	my $mymonth = &_toc_month();
	return "\U$mymonth\E";
}

sub _toc_mon
{
	my @mthlist = (qw(jan feb mar apr may jun jul aug sep oct nov dec));

	return "Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
	return $mthlist[$inputs[4]];
}

sub _toc_Mon
{
	my $mymonth = &_toc_mon();
	return "\u\L$mymonth\E";
}

sub _toc_MON
{
	my $mymonth = &_toc_mon();
	return "\U$mymonth\E";
}

sub _toc_rm   #ROMAN NUMBER MONTH - LOWER CASE
{
	my @mthlist = (qw(i ii iii iv v vi vii viii ix x xi xii));

	return "Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
	return $mthlist[$inputs[4]];
}

sub _toc_RM   #ROMAN NUMBER MONTH - UPPER CASE
{
	my $mymonth = &_toc_rm();
	return "\U$mymonth\E";
}

sub _toc_mm   #MONTH (01-12)
{
	my $mymth = $inputs[4] + 1;
	return "Invalid Month ($mymth)! "  unless ($mymth >= 1 && $mymth <= 12);
	return '0'.$mymth  if ($mymth < 10);
	return $mymth;
}

sub _toc_m1   #MONTH (1-12)
{
	my $mymth = $inputs[4] + 1;
	return "Invalid Month ($mymth)! "  unless ($mymth >= 1 && $mymth <= 12);
	return $mymth;
}

sub _toc_yyyymmdd
{
	return &_toc_yyyy() . &_toc_mm() . &_toc_dd();
}

sub _toc_yyyy   #4-DIGIT YEAR
{
	return $inputs[5] + 1900;
}

sub _toc_yy
{
	my $myyr = $inputs[5];
	return "Invalid Year ($myyr)! "  unless ($myyr =~ /^[0-9]+$/o);
	$myyr -= 100  while ($myyr >= 100);
	return  '0'.$myyr  if ($myyr < 10);
	return $myyr;
}

sub _toc_rr
{
	return &_toc_yy();
}

sub _toc_rrrr
{
	return &_toc_yyyy();
}

sub _toc_ddd    #DAY OF YEAR (1-365)
{
	return $inputs[7] + 1;
}

sub _toc_dd     #DAY OF MONTH (01-31)
{
	return '0'.$inputs[3]  if ($inputs[3] < 10);
	return $inputs[3];
}

sub _toc_d1     #DAY OF MONTH (1-31)
{
	return $inputs[3];
}

sub _toc_hh24   #24-HOUR MILITARY TIME (0000-2359):
{
	return sprintf('%4.4d', ($inputs[2] * 100) + $inputs[1]);
}

sub _toc_HH     #HOUR (00-23)
{
	return '0'.$inputs[2]  if ($inputs[2] < 10);
	return $inputs[2];
}

sub _toc_H1     #HOUR (0-23)
{
	return $inputs[2];
}

sub _toc_hh     #HOUR (01-12)
{
	my $hr = $inputs[2];
	return 12  unless ($hr);
	$hr -= 12  if ($hr > 12);
	return '0'.$hr  if ($hr < 10);
	return $hr;
}

sub _toc_h1     #HOUR (1-12)
{
	my $hr = $inputs[2];
	return 12  unless ($hr);
	$hr -= 12  if ($hr > 12);
	return $hr;
}

sub _toc_a
{
	return ($inputs[2] < 12) ? 'a' : 'p';
}

sub _toc_p
{
	return &_toc_a();
}

sub _toc_A
{
	return ($inputs[2] < 12) ? 'A' : 'P';
}

sub _toc_P
{
	return &_toc_A();
}

sub _toc_am
{
	return &_toc_a() . 'm';
}

sub _toc_pm
{
	return &_toc_a() . 'm';
}

sub _toc_AM
{
	return &_toc_A() . 'M';
}

sub _toc_PM
{
	return &_toc_A() . 'M';
}

sub _toc_mi       #MINUTES (00-59)
{
	return '0'.$inputs[1]  if ($inputs[1] < 10);
	return $inputs[1];
}

sub _toc_sssss    #SECONDS OF THE DAY (0-86399)
{
	return sprintf('%5.5d', (($inputs[2]*3600)+($inputs[1]*60)+$inputs[0]));
}

sub _toc_ss       #SECONDS
{
	return '0'.$inputs[0]  if ($inputs[0] < 10);
	return $inputs[0];
}

sub _toc_d        #DAY OF WEEK (SUN=1..SAT=7
{
	return $inputs[6] + 1;
}

sub _toc_d0       #DAY OF WEEK (SUN=0..SAT=6
{
	return $inputs[6];
}

sub _toc_day
{
	my @daylist = (qw(sun mon tue wed thu fri sat));

	return "Invalid Day ($inputs[6])! "  unless ($inputs[6] >= 0 && $inputs[6] < 7);
	return $daylist[$inputs[6]];
}

sub _toc_Day
{
	my $myday = &_toc_day();
	return "\u\L$myday\E";
}

sub _toc_DAY
{
	my $myday = &_toc_day();
	return "\U$myday\E";
}

sub _toc_dayofweek
{
	my @daylist = (qw(sunday monday tuesday wednesday thursday friday saturday));

	return "Invalid Day ($inputs[6])! "  unless ($inputs[6] >= 0 && $inputs[6] < 7);
	return $daylist[$inputs[6]];
}

sub _toc_Dayofweek
{
	my $myday = &_toc_dayofweek();
	return "\u\L$myday\E";
}

sub _toc_DAYOFWEEK
{
	my $myday = &_toc_dayofweek();
	return "\U$myday\E";
}

sub _toc_ww    #WEEK OF YEAR (0-51)
{
	return &_toc_ddd % 7;
}

sub _toc_q     #QUARTER (1-4):
{
	return int(&_toc_mm / 4) + 1;
}

1

__END__
