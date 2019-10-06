=head1 NAME

Date::Time2fmtstr - Functions to format Perl time integers to strings based on a "Picture" format string.

=head1 AUTHOR

Jim Turner

(c) 2015-2019, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 SYNOPSIS

	use Date::Time2fmtstr;

	my $timestring = time2str(time, 'mm-dd-yyyy hh:mi PM');

	die $timestring  if ($timestring =~ /^e\:/);

	print "Current date/time (formatted):  $timestring.\n";

=head1 DESCRIPTION

Date::Time2fmtstr provides a single function B<time2str> that accepts a standard Perl (Unix) 
"time" value (a large integer equivalent to the number of seconds since 1980) and converts it 
to a string value based on a I<format-string> consisting of special substrings which represent 
the various parts of a date and time value.  It returns a string that is essentially the 
same as the original I<format-string> with each of these special substrings replaced with 
the corresponding date/time value.

=head1 METHODS

=over 4

=item $string = B<time2str>(I<time>, I<format-string>);

Returns a string corresponding to the specified I<format-string> with each special substring 
replaced with the corresponding date/time data field.

For example:

	$s = &time2str(1452324044, 'mm-dd-yyyy hh:mi PM (Day) (Month)');

would set $s to '01-09-2016 01:20 AM (Sat) (January)'.

=item B<Special Formatting Substrings>

There are numerous choices of special format substrings which can be used in an infinite 
number of combinations to produce the desired results.  They are listed below:

=over 4

B<a>, B<p> - display "a" if between Midnight and Noon, "p" otherwise (both specifiers are identical). 

B<A>, B<P> - display "A" if between Midnight and Noon, "P" otherwise (both specifiers are identical). 

B<am>, B<pm> - display "am" if between Midnight and Noon, "pm" otherwise (both specifiers are identical). 

B<AM>, B<PM> - display "AM" if between Midnight and Noon, "PM" otherwise (both specifiers are identical). 

B<day> - Three letter abbreviation of the day of the week in all lower case, ie. "sun". 

B<Day> - Three letter abbreviation of the day of the week capitalized, ie. "Sun". 

B<DAY> - Three letter abbreviation of the day of the week all capitalized, ie. "SUN". 

B<dayofweek> - Day of the week in all lower case, ie. "sunday". 

B<Dayofweek> - Day of the week capitalized, ie. "Sunday". 

B<DAYOFWEEK> - Day of the week all capitalized, ie. "SUNDAY". 

B<ddd> - Num. of days since beginning of year.  NOTE:  This is calculated by adding 
the number of SECONDS (86400 per day) to midnight, 1/1/current-year, so if spanning a 
daylight-savings time boundary may result in +1 hour difference, which the underlying 
Perl localtime/timelocal functions will take into account!  For example, if the current 
time was "1570286966" (2019/10/05 09:49:26), the following code:

print &time2str(&str2time(&time2str(1570286966, 'ddd, hh:mi:ss'), 'ddd, hh:mi:ss'), 'yyyy/mm/dd hh:mi:ss') . "\n";

would print "2019/10/05 10:49:26" due to the fact that 1 hour (3600 seconds) was 
automatically skipped over when DST was imposed between 1 January and 5 October.  This 
"feature" only applies when calculating the date/time based on days since beginning 
of the year ("ddd").

B<dd> - Day of month (2 digits, left padded with a zero if needed), ie. "03" for March.

B<d0>, B<d> - Numeric day of the week zero-based (Sunday=0, Monday=1, ... Saturday=6). 

B<d1> - Day of month (1 or 2 digits, as needed), ie. "3" for March. 

B<hh> - Hour in common format (left padded with a zero if needed for 2 digits), ie. 01-12.

B<hhmi> - Hours and minutes in 12-hour time (hours and minutes no colon, left padded 
with a zero if needed for 4 digits).

B<hhmiss> - Hours, minutes and seconds in 12-hour time (no colon, left padded 
with a zero if needed for 6 digits).

B<hh24>, B<HHmi> - Military time (hours and minutes: 24 hours, no colon), left padded 
with a zero if needed for 4 digits).

B<h1> - Hour in common format, 1 or 2 digits, as needed, ie. 1-12. (see B<AM> and B<PM> 
specifiers).

B<h1mi> - Hours and minutes in 12-hour time (hours and minutes no colon).  Returns 3 or 
4 digits as needed.

B<HH> - Hour in 24-hour format, 2 digits, left padded with a zero if needed, ie. 00-23. 

B<H1> - Hour in 24-hour format, 1 or 2 digits, as needed, ie. 0-23. 

B<HHmiss> - Hours, minutes and seconds in 24-hour (military) time (no colon, left padded 
with a zeros if needed for 6 digits).

B<mi> - Minute, (2 digits, left padded with a zero if needed), ie. 00-59.

B<mm> - Number of month (2 digits, left padded with a zero if needed), ie. "01" for January. 

B<mmdd> - Numeric date in 4 digits, ie. "0107" for January, 7, (current year). 

B<mmddyy> - Numeric date in 6 digits, ie. "010715" for January 7, 2015. 

B<mmddyyyy> - Numeric date in 8 digits, ie. "01072015" for January 7, 2015. 

B<mmmm> - Minutes since start of day (0000-3599).

B<mmm0> - Minutes since start of day (0-3599).

B<mmyy> - Numeric date in 4 digits, ie. "0115" for January, 2015. 

B<mmyyyy> - Numeric date in 6 digits, ie. "012015" for January, 2015. 

B<mon> - Three letter abbreviation of the month, in lower case, ie. "jan" for January. 

B<Mon> - Three letter abbreviation of the month, capitalized, ie. "Jan" for January. 

B<MON> - Three letter abbreviation of the month all capitalized, ie. "JAN" for January. 

B<month> - The Full name of the month in all lower case, ie. "january".

B<Month> - The Full name of the month capitalized, ie. "January". 

B<MONTH> - The Full name of the month all capitalized, ie. "JANUARY". 

B<m1> - Number of month (1 or 2 digits, as needed), ie. "1" for January. 

B<q> - Number of the quarter of the year - (1-4).

B<rm> - Roman numeral for the month (i-xii) in lower case. 

B<RM> - Roman numeral for the month (I-XII) in upper case. 

B<ss> - Seconds since start of last minute (2 digits), ie. 00-59. 

B<sssss> - Seconds since start of day (00000-86399). 

B<ssss0> - Seconds since start of day (0-86399). 

B<w> - Number of week (one-based) of the month (1-5). 

B<ww> - Number of week (one-based) of the year (1-52). 

B<yy>, B<rr> - Year in last 2 digits.

B<yymm> - Numeric date in 4 digits, ie. "1501" for January, 2015. 

B<yymmdd> - Numeric date in 6 digits, ie. "150107" for January 7, 2015. 

B<yyyy>, B<rrrr> - Year in 4 digits.

B<yyyymm> - Numeric date in 6 digits, ie. "201501" for January, 2015. 

B<yyyymmdd> - Numeric date in 8 digits, ie. "20150107" for January 7, 2015. 

B<yyyymmddhhmi> - Numeric date/time in 12 digits, ie. "201501071345" for January 7, 2015 1:45pm. 

B<yyyymmddhhmiss> - Numeric date/time in 14 digits, ie. "20150107134512" for January 7, 2015 1:45:12pm. 

=back

=back

=head1 DEPENDENCIES

Perl 5

=head1 RECCOMENDS

L<Date::Fmtstr2time>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Date-Time2fmtstr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Time2fmtstr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Time2fmtstr

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Time2fmtstr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Time2fmtstr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Time2fmtstr>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Time2fmtstr/>

=back

=head1 SEE ALSO

L<Date::Fmtstr2time>

=head1 KEYWORDS

Date::Time2fmtstr, Date::Fmtstr2time, formatting, picture_clause, strings

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015-2019 Jim Turner

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

package Date::Time2fmtstr;

use strict;
#use warnings;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.11';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(time2str);

my @inputs = ();

sub time2str
{
	my $s = $_[0] || time;
	return "e:Invalid Time ($s) not numeric!"  if ($s =~ /\D/);

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
			foreach my $f (qw(month Month MONTH dayofweek Dayofweek DAYOFWEEK day Day DAY	ddd
					dd d1 d0 mmddyyyy yyyymmddhhmiss yyyymmddhhmi yyyymmdd yyyymm yymmdd mmyyyy 
					mmddyy yyyy yymm mmyy yy mmdd hh24 HHmiss hhmiss HHmi h1mi hhmi hh HH H1 h1 mi 
					mmm0 mmmm mm mon Mon MON m1 ssss0 sssss ss am pm AM PM a p A P rm RM rr d 
					ww w q))
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

	return "e:Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
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

	return "e:Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
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

	return "e:Invalid Month ($inputs[4])! "  unless ($inputs[4] >= 0 && $inputs[4] < 12);
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
	return "e:Invalid Month ($mymth)! "  unless ($mymth >= 1 && $mymth <= 12);
	return '0'.$mymth  if ($mymth < 10);
	return $mymth;
}

sub _toc_m1   #MONTH (1-12)
{
	my $mymth = $inputs[4] + 1;
	return "e:Invalid Month ($mymth)! "  unless ($mymth >= 1 && $mymth <= 12);
	return $mymth;
}

sub _toc_yy
{
	my $myyr = $inputs[5];
	return "e:Invalid Year ($myyr)! "  unless ($myyr =~ /^[0-9]+$/o);
	$myyr -= 100  while ($myyr >= 100);
	return  '0'.$myyr  if ($myyr < 10);
	return $myyr;
}

sub _toc_mmddyyyy
{
	return &_toc_mm() . &_toc_dd() . &_toc_yyyy();
}

sub _toc_yyyymmdd
{
	return &_toc_yyyy() . &_toc_mm() . &_toc_dd();
}

sub _toc_yyyymmddhhmiss
{
	return &_toc_yyyy() . &_toc_mm() . &_toc_dd() . &_toc_HH() . &_toc_mi() . &_toc_ss();
}

sub _toc_yyyymmddhhmi
{
	return &_toc_yyyy() . &_toc_mm() . &_toc_dd() . &_toc_HH() . &_toc_mi();
}

sub _toc_yyyymm
{
	return &_toc_yyyy() . &_toc_mm();
}

sub _toc_yymmdd
{
	return &_toc_yy() . &_toc_mm() . &_toc_dd();
}

sub _toc_mmyyyy
{
	return &_toc_mm() . &_toc_yyyy();
}

sub _toc_mmddyy
{
	return &_toc_mm() . &_toc_dd() . &_toc_yy();
}

sub _toc_yymm
{
	return &_toc_yy() . &_toc_mm();
}

sub _toc_yyyy   #4-DIGIT YEAR
{
	return $inputs[5] + 1900;
}

sub _toc_mmyy
{
	return &_toc_mm() . &_toc_yy();
}

sub _toc_mmdd
{
	return &_toc_mm() . &_toc_dd();
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

sub HHmi {
	return &_toc_HH24();
}

sub hhmi {
	return &_toc_hh() . &_toc_mi();
}

sub h1mi {
	return &_toc_h1() . &_toc_mi();
}

sub HHmiss {
	return &_toc_HH() . &_toc_mi() . &_toc_ss();
}

sub hhmiss {
	return &_toc_hh() . &_toc_mi() . &_toc_ss();
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

sub _toc_ssss0    #SECONDS OF THE DAY (0-86399)
{
	return ($inputs[2]*3600)+($inputs[1]*60)+$inputs[0];
}

sub _toc_sssss    #SECONDS OF THE DAY (0-86399)
{
	return sprintf('%5.5d', &_toc_ssss0);
}

sub _toc_mmm0    #MINUTES OF THE DAY (0-3599)
{
	return ($inputs[2]*60)+$inputs[1];
}

sub _toc_mmmm    #MINUTES OF THE DAY (0-3599)
{
	return sprintf('%4.4d', &_toc_mmm0);
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

	return "e:Invalid Day ($inputs[6])! "  unless ($inputs[6] >= 0 && $inputs[6] < 7);
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

	return "e:Invalid Day ($inputs[6])! "  unless ($inputs[6] >= 0 && $inputs[6] < 7);
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

sub _toc_w    #WEEK OF MONTH (1-5)
{
	return int(&_toc_dd / 7) + 1;
}

sub _toc_ww    #WEEK OF YEAR (1-52)
{
	return int(&_toc_ddd / 7) + 1;
}

sub _toc_q     #QUARTER (1-4):
{
	return int(&_toc_mm / 4) + 1;
}

1

__END__
