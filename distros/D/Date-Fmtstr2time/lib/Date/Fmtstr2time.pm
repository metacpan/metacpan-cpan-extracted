=head1 NAME

Date::Fmtstr2time - Functions to format date/time strings into a Perl Time based on a "Picture" format string.

=head1 AUTHOR

Jim Turner

(c) 2015-2019, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 SYNOPSIS

	use Date::Fmtstr2time;

	my $timevalue = str2time('12-25-2015 07:15 AM', 'mm-dd-yyyy hh:mi PM');

	die $timevalue  if ($timevalue =~ /\D/);

	print "Perl time (seconds since epoc):  $timevalue.\n";

=head1 DESCRIPTION

Date::Fmtstr2time provides a single function B<str2time> that accepts a date or date / time 
as a string (I<data-string>), and a I<format-string> consisting of special substrings which represent 
the format of various parts of a date and time value.  It returns a standard Perl (Unix) "time" 
value (a large integer equivalent to the number of seconds since 1980) or an error string.

=head1 METHODS

=over 4

=item $integer = B<str2time>(I<data-string>, I<format-string>);

Returns a standard Perl (Unix) "time" value (a large integer) on success, or an error message 
string on failure.  One can easily check for failure by checking the result for any non-integer 
characters (=~ /\D/).  The I<format-string> tells 
the software what format to expect the date / time value in the I<data-string> to be in.

For example:

	$s = &str2time('01-09-2016 01:20 AM (Sat) (January)', 'mm-dd-yyyy hh:mi PM (Day) (Month)');

would set $s to 1452324000, (the Unix time equivalent).

=item B<Special Formatting Substrings>

There are numerous choices of special format substrings which can be used in an infinite 
number of combinations to produce the desired results.  They are listed below:

=over 4

B<a>, B<A>, B<am>, or B<AM> - Assume hour is AM (if 1-11), and convert 12 to midnight 
(0 in 24-hour time).  (all specifiers are identical and case insensitive).  See also:  
B<p>, B<P>, B<pm>, or B<PM> below.

B<day>, B<Day>, or B<DAY> - Three letter abbreviation of the day of the week 
(case insensitive), ie. "sun".  Reason for the three versions is to match up with 
L<Date::Time2fmtstr>, which has three separate versions for I<outputting> the desired case, 
but here (I<inputting>), case doesn't matter.  This applies also to Month, etc. and 
similiarly to functions that pad or don't pad with leading zeros!

B<dayofweek>, B<Dayofweek>, or B<DAYOFWEEK> - Day of the week (case insensitive).

B<ddd> - Number of days since beginning of year.  NOTE:  This is calculated by adding 
the number of SECONDS (86400 per day) to midnight, 1/1/current-year, so if spanning a 
daylight-savings time boundary may result in +1 hour difference, which the underlying 
Perl localtime/timelocal functions will take into account!  For example, if the current 
time was "1570286966" (2019/10/05 09:49:26), the following code:

print &time2str(&str2time(&time2str(1570286966, 'ddd, hh:mi:ss'), 'ddd, hh:mi:ss'), 'yyyy/mm/dd hh:mi:ss') . "\n";

would print "2019/10/05 10:49:26" due to the fact that 1 hour (3600 seconds) was 
automatically skipped over when DST was imposed between 1 January and 5 October.  This 
"feature" only applies when calculating the date/time based on days since beginning 
of the year ("ddd").

B<dd>, B<d1> - Day of month (1 or 2 digits, left padded with a zero if needed), ie. 
"3" or "03" for March.

B<d0>, B<d> - Numeric day of the week zero-based (Sunday=0, Monday=1, ... Saturday=6). 

B<hh>, B<h1> - Hour in common format, ie. 1-12 (1 or 2 digits, as needed). 
(see B<AM> and B<PM> specifiers).

B<hhmi>, B<h1mi> - Hours and minutes in 12-hour time (hours and minutes no colon).

B<hhmiss> - Hours, minutes and seconds in 12-hour time (no colons).  Must be six 
digits.

B<hh24>, B<HHmi> - Hours and minutes in 24-hour (military) time (no colon).

B<HH>, B<H1> - Hour in 24-hour format, ie. 00-23 (1 or 2 digits, as needed). 

B<HHmiss> - Hours, minutes and seconds in 24-hour (military) time (no colons).  
Must be six digits.

B<mi> - Minute, ie. 0-59 (1 or 2 digits, as needed).

B<mm>, B<m1> - Number of month (1 or 2 digits, as needed), ie. "1" or "01" for January. 

B<mmdd> - Numeric date in 4 digits, ie. "0107" for January, 7, (current year). 

B<mmddyy> - Numeric date in 6 digits, ie. "010715" for January 7, 2015. 

B<mmddyyyy> - Numeric date in 8 digits, ie. "01072015" for January 7, 2015. 

B<mmmm>, B<mmm0> - Minutes since start of day (0-3599). 

B<mmyy> - Numeric date in 4 digits, ie. "0115" for January, 2015. 

B<mmyyyy> - Numeric date in 6 digits, ie. "012015" for January, 2015. 

B<mon>, B<Mon>, or B<MON> - Three letter abbreviation of the month (case insensitive), 
ie. "jan" for January. 

B<month>, B<Month>, or B<MONTH> - The Full name of the month (case insensitive), 
ie. "january".

B<p>, B<P>, B<pm>, or B<PM> - Assume hour is noon if 12, otherwise, convert (add 12 to) 
1-11 to convert to PM (13-23 in 24 hour time).  (all specifiers are identical). 

B<q> - Number of the quarter of the year - (1-4).

B<rm> - Roman numeral for the month (i-xii) in lower case. 

B<RM> - Roman numeral for the month (I-XII) in upper case. 

B<ss> - Seconds since start of last minute (1 or 2 digits as needed), ie. 0-59. 

B<sssss>, B<ssss0> - Seconds since start of day (0-86399) 1-5 digits as needed 
(leading zeros ignored). 

B<w> - Number of week (one-based) of the month (1-5). 

B<ww> - Number of week (one-based) of the year (1-52) (1 or 2 digits as needed). 

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

L<Time::Local>

=head1 RECCOMENDS

L<Date::Time2fmtstr>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Date-Fmtstr2time at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Fmtstr2time>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Fmtstr2time

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Fmtstr2time>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Fmtstr2time>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Fmtstr2time>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Fmtstr2time/>

=back

=head1 SEE ALSO

L<Date::Time2fmtstr>

=head1 KEYWORDS

Date::Fmtstr2time, Date::Time2fmtstr, formatting, picture_clause, strings

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

package Date::Fmtstr2time;

use strict;
#use warnings;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.11';

use Time::Local;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(str2time);

my @inputs = ();
my @today = ();;
my $rtnTime = '';
my @tl = ();
my $begofyear;
my %mthhash = (
	'january' => '0',
	'february' => 1,
	'march' => 2,
	'april' => 3,
	'may' => 4,
	'june' => 5,
	'july' => 6,
	'august' => 7,
	'september' => 8,
	'october' => 9,
	'november' => 10,
	'december' => 11
);

sub str2time
{
	my ($s) = $_[0];
	my ($f) = $_[1];

	my @fmts = split(/\b/o, $f);
	@inputs = split(/\b/o, $s);
	@today = localtime(time);
#print STDERR "-to_date:  inputs=".join('|',@inputs)."=\n";
#print STDERR "-to_date:  formats=".join('|',@fmts)."=\n";
	my $err = '';
	$rtnTime = '';  #USED IF "ddd" (Days since beg. of year) AND AN OTHERWISE INCOMPLETE mm/dd/yy DATE GIVEN.
	@tl = ();
	$begofyear = timelocal(0,0,0,1,0,$today[5]);

	my $fn;
	for (my $i=0;$i<=$#fmts;$i++)
	{
		next  unless ($fmts[$i] =~ /\w/o);
		foreach my $f (qw(month Month MONTH dayofweek Dayofweek DAYOFWEEK day Day DAY ddd 
			dd d1 d0 mmddyyyy yyyymmddhhmiss yyyymmddhhmi yyyymmdd yyyymm yymmdd mmyyyy 
			mmddyy yyyy yymm mmyy yy mmdd hh24 HHmiss hhmiss HHmi h1mi hhmi hh HH h1 H1 mi 
			mmm0 mmmm mm mon Mon MON m1 ssss0 sssss ss am pm AM PM a p A P rm RM rr d ww w q))
		{
			if ($fmts[$i] =~ /^$f/)
			{
				$fn = '_tod_'.$f;
no strict 'refs';
				$err .= &$fn($i);
#print "-to_date:  called($fn($i)), input=$inputs[$i]= res=$err= tl=".join('|',@tl)."= RT=$rtnTime=\n";
				last;
			}
		}
	}

	return $err  if ($err =~ /\w/);

#print "***** rtnTime =$rtnTime= tl=".join('|',@tl)." ($#tl)\n";
	if ($rtnTime >= $begofyear) {
		return $rtnTime  if ($#tl < 5);
	} else {
		for (my $i=3;$i<=5;$i++) {  #FILL IN ANY MISSING MTH,DAY,YEAR WITH TODAY (DEFAULT IF NO ERRORS):
			$tl[$i] = $today[$i]  unless (defined $tl[$i]);
		}
	}
	$tl[3] = '1'  unless ($tl[3]);  #MAKE SURE DAY IS ONE-BASED!
	#NOW DOUBLE-CHECK WHAT WE'RE FEEDING TO timelocal():
	$err .= "e:Invalid second ($tl[0]) - must be 0-59! "  if ($tl[0] > 59);
	$err .= "e:Invalid minute ($tl[1]) - must be 0-59! "  if ($tl[1] > 59);
	$err .= "e:Invalid hour ($tl[2]) - must be 0-23! "  if ($tl[2] > 23);
	$err .= "e:Invalid day ($tl[3]) - must be 1-31! "  if ($tl[3] > 31);
	$err .= "e:Invalid month ($tl[4]) - must be 0-11! "  if ($tl[4] > 11);
	#WE'RE NOT CURRENTLY CHECKING YEAR, SINCE THERE ARE TOO MANY VALID VALUES.
	return $err  if ($err =~ /\w/);

	my $rt = timelocal(@tl);

#print "***** tl=".join('|',@tl)." ($#tl) = rt=$rt=\n";
	return $rt;
}

sub _tod_month
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	$input =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$input};
	return "e:Invalid Month ($input)! "  unless (length($tl[4]));
	return '';
}

sub _tod_Month
{
	return &_tod_month(@_);
}

sub _tod_MONTH
{
	return &_tod_month(@_);
}

sub _tod_mon
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	my %mthhash = (
		'jan' => '0',
		'feb' => 1,
		'mar' => 2,
		'apr' => 3,
		'may' => 4,
		'jun' => 5,
		'jul' => 6,
		'aug' => 7,
		'sep' => 8,
		'oct' => 9,
		'nov' => 10,
		'dec' => 11
	);

	$input =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{substr($input,0,3)};
	return "e:Invalid Mth ($input)! "  unless (length($tl[4]));
	return '';
}

sub _tod_Mon
{
	return &_tod_mon(@_);
}

sub _tod_MON
{
	return &_tod_mon(@_);
}

sub _tod_rm
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	my %mthhash = (
		'i' => '0',
		'ii' => 1,
		'iii' => 2,
		'iv' => 3,
		'v' => 4,
		'vi' => 5,
		'vii' => 6,
		'viii' => 7,
		'ix' => 8,
		'x' => 9,
		'xi' => 10,
		'xii' => 11
	);

	$input =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$input};
	return "e:Invalid Roman Month. ($input)! "  unless (length($tl[4]));
	return '';
}

sub _tod_RM
{
	return &_tod_rm(@_);
}

sub _tod_mm
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	$input =~ s/^0//;
	return "e:Invalid month ($input)! "  
			unless ($input > 0 && $input <= 12);

	$tl[4] = $input - 1;
	return '';
}

sub _tod_m1
{
	return &_tod_mm(@_);
}

sub _tod_yyyymmdd
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	&_tod_yyyy($indx, substr($input,0,4));
	&_tod_mm($indx, substr($input,4,2));
	return &_tod_dd($indx, substr($input,6,2));
}

sub _tod_yyyymmddhhmi
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid yyyymmddhhmi ($input) - must be 12-digit number! "  unless ($input =~ /^\d{12}$/);

	&_tod_yyyy($indx, substr($input,0,4));
	&_tod_mm($indx, substr($input,4,2));
	&_tod_dd($indx, substr($input,6,2));
	return &_tod_hh24($indx, substr($input,8,4));
}

sub _tod_yyyymmddhhmiss
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid yyyymmddhhmiss ($input) - must be 14-digit number! "  unless ($input =~ /^\d{14}$/);

	&_tod_yyyy($indx, substr($input,0,4));
	&_tod_mm($indx, substr($input,4,2));
	&_tod_dd($indx, substr($input,6,2));
	&_tod_hh24($indx, substr($input,8,4));
	return &_tod_ss($indx, substr($input,12,2));
}

sub _tod_yyyymm
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid yyyymm ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_yyyy($indx, substr($input,0,4));
	return &_tod_mm($indx, substr($input,4,2));
}

sub _tod_yymmdd
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid yymmdd ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_rr($indx, substr($input,0,2));
	&_tod_mm($indx, substr($input,2,2));
	return &_tod_dd($indx, substr($input,4,2));
}

sub _tod_yymm
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid yymm ($input) - must be 4-digit number! "  unless ($input =~ /^\d{4}$/);

	&_tod_rr($indx, substr($input,0,2));
	return &_tod_mm($indx, substr($input,2,2));
}

sub _tod_mmyyyy
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid mmyyyy ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_mm($indx, substr($input,0,2));
	return &_tod_yyyy($indx, substr($input,2,4));
}

sub _tod_mmyy
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid mmyy ($input) - must be 4-digit number! "  unless ($input =~ /^\d{4}$/);

	&_tod_mm($indx, substr($input,0,2));
	return &_tod_rr($indx, substr($input,2,2));
}

sub _tod_mmddyyyy
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid _tod_mmddyyyy ($input) - must be 8-digit number! "  unless ($input =~ /^\d{8}$/);

	&_tod_mm($indx, substr($input,0,2));
	&_tod_dd($indx, substr($input,2,2));
	return &_tod_yyyy($indx, substr($input,4,4));
}

sub _tod_mmddyy
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid mmddyy ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_mm($indx, substr($input,0,2));
	&_tod_dd($indx, substr($input,2,2));
	return &_tod_rr($indx, substr($input,4,2));
}

sub _tod_mmdd
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid mmyy ($input) - must be 4-digit number! "  unless ($input =~ /^\d{4}$/);

	&_tod_mm($indx, substr($input,0,2));
	return &_tod_dd($indx, substr($input,2,2));
}

sub _tod_yyyy
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid year ($input)! "  
			unless ($input =~ /^\d\d\d\d$/);

	$tl[5] = $input - 1900;
	return '';
}

sub _tod_yy
{
	return &_tod_rr(@_);
}

sub _tod_rr
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid year ($input)! "  
			unless ($input =~ /^\d\d$/);

	if (($today[5] % 100) > 50)
	{
		$input += 100  if ($input < 50);
	}
	else
	{
		#$input -= 100  if ($input > 50);
		$input += 100  if ($input < 50);
	}
	$tl[5] = $input;
	return '';
}

sub _tod_rrrr
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return &_tod_rr($indx)  if ($input =~ /^\d\d?$/);
	return "e:Invalid year ($input)! "  
			unless ($input =~ /^\d\d\d\d?$/);

	if (($today[5] % 100) > 50)
	{
		$input += 100  if (($input % 100) < 50);
	}
	else
	{
		#$input -= 100  if (($input % 100) > 50);
		$input += 100  if ($input < 50);
	}
	$tl[5] = $input - 1900;
	return '';
}

sub _tod_ddd
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	$input =~ s/^0+//;
	return "e:Invalid year-day ($input)! "  
			unless ($input > 0 and $input <= 366);

	$rtnTime += $begofyear + (($input*86400) - 86400)  unless ($rtnTime > 86400);
	return '';
}

sub _tod_dd
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid day ($input)! "  
			unless ($input > 0 and $input <= 31);

	$tl[3] = $input;
	return '';
}

sub _tod_d1
{
	return &_tod_dd(@_);
}

sub _tod_hh
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid hour ($input)! "  
			unless ($input > 0 and $input <= 12);

	unless ($tl[2] =~ /\d/) {
		$tl[2] = $input;
		$rtnTime += ($input * 3600)  if ($rtnTime);
	}
	return '';
}

sub _tod_h1
{
	return &_tod_hh(@_);
}

sub _tod_HH
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid hour ($input)! "  
			unless ($input >= 0 and $input < 24);

	unless ($tl[2] =~ /\d/) {
		$tl[2] = $input;
		$rtnTime += ($input * 3600)  if ($rtnTime);
	}
	return '';
}

sub _tod_H1
{
	return &_tod_HH(@_);
}

sub _tod_hh24
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid 24-hr time ($input)! "  
			unless ($input >= 0 and $input < 2400 
			&& ($input % 100) < 60);

	unless ($tl[1] =~ /\d/ || $tl[2] =~ /\d/) {
		$tl[1] = ($input % 100);
		$input = int($input / 100);
		$tl[2] = $input;
		$rtnTime += ($tl[2] * 3600) + ($tl[1] * 60)  if ($rtnTime);
	}
	return '';
}

sub _tod_HHmi
{
	return &_tod_hh24(@_)
}

sub _tod_hhmi
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid time ($input)! "
			if ($input < 100 || $input > 1259);

	unless ($tl[1] =~ /\d/ || $tl[2] =~ /\d/) {
		$tl[1] = ($input % 100);
		$input = int($input / 100);
		$tl[2] = $input;
		$rtnTime += ($tl[2] * 3600) + ($tl[1] * 60)  if ($rtnTime);
	}
}

sub _tod_hhmiss
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid hhmiss ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_hh($indx, substr($input,0,2));
	&_tod_mi($indx, substr($input,2,2));
	return &_tod_ss($indx, substr($input,4,2));
}

sub _tod_HHmiss
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid HHmiss ($input) - must be 6-digit number! "  unless ($input =~ /^\d{6}$/);

	&_tod_hh24($indx, substr($input,0,4));
	return &_tod_ss($indx, substr($input,4,2));
}

sub _tod_a
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	if ($tl[2] < 12)
	{
		if ($input =~ /p/io) {
			$tl[2] += 12;
			$rtnTime += 43200  if ($rtnTime);
		}
	}
	else
	{
		if ($input =~ /a/io) {
			$tl[2] -= 12;
			$rtnTime -= 43200  if ($rtnTime);
		}
	}
	return '';
}

sub _tod_p
{
	return &_tod_a;
}

sub _tod_A
{
	return &_tod_a;
}

sub _tod_P
{
	return &_tod_a;
}

sub _tod_am
{
	return &_tod_a;
}

sub _tod_pm
{
	return &_tod_a;
}

sub _tod_AM
{
	return &_tod_a;
}

sub _tod_PM
{
	return &_tod_a;
}

sub _tod_mi
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid minutes ($input)! "  
			unless ($input >= 0 and $input <= 59);

	unless ($tl[1] =~ /\d/) {
		$tl[1] = $input;
		$rtnTime += ($input * 60)  if ($rtnTime);
	}
	return '';
}

sub _tod_sssss  #SECONDS SINCE MIDNIGHT OF CURRENT DAY:
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid seconds ($input)! "  
			unless ($input >= 0 and $input < 86400);

	unless ($tl[0] =~ /\d/ || $tl[1] =~ /\d/ || $tl[2] =~ /\d/) {
		$tl[2] = int($input / 3600);
		$tl[0] = $input % 60;
		$tl[1] = int($input / 60) % 60;
		$rtnTime += $input  if ($rtnTime);
	}
	return '';
}

sub _tod_ssss0  #SECONDS SINCE MIDNIGHT OF CURRENT DAY:
{
	return &_tod_sssss(@_);
}

sub _tod_mmmm   #MINUTES SINCE MIDNIGHT OF CURRENT DAY:
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid minutes ($input)! "  
			unless ($input >= 0 and $input < 1440);

	unless ($tl[1] =~ /\d/ || $tl[2] =~ /\d/) {
		$tl[2] = int($input / 60);
		$tl[1] = int($input % 60);
		$rtnTime += ($input / 60)  if ($rtnTime);
	}
	return '';
}

sub _tod_mmm0  #MINUTES SINCE MIDNIGHT OF CURRENT DAY:
{
	return &_tod_mmmm(@_);
}

sub _tod_ss
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid seconds ($input)! "  
			unless ($input >= 0 and $input <= 59);

	unless ($tl[0] =~ /\d/) {
		$tl[0] = $input;
		$rtnTime += $input  if ($rtnTime);
	}
	return '';
}

sub _tod_d
{
	return '';
}

sub _tod_d0
{
	return '';
}

sub _tod_day
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	my %dayhash = (
		'sun' => '0',
		'mon' => 1,
		'tue' => 2,
		'wed' => 3,
		'thu' => 4,
		'fri' => 5,
		'sat' => 6
	);

	$input =~ tr/A-Z/a-z/;
	return "e:Invalid Day ($input)! "  unless (defined $dayhash{$input});
	return '';
}

sub _tod_Day
{
	return &_tod_day(@_);
}

sub _tod_DAY
{
	return &_tod_day(@_);
}

sub _tod_dayofweek
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	my %dayhash = (
		'sunday' => '0',
		'monday' => 1,
		'tuesday' => 2,
		'wednesday' => 3,
		'thursday' => 4,
		'friday' => 5,
		'saturday' => 6
	);

	$input =~ tr/A-Z/a-z/;
	return "e:Invalid Day ($input)! "  unless (defined $dayhash{$input});
	return '';
}

sub _tod_Dayofweek
{
	return &_tod_dayofweek(@_);
}

sub _tod_DAYOFWEEK
{
	return &_tod_dayofweek(@_);
}

sub _tod_ww
{
	return '';
}

sub _tod_w
{
	return '';
}

sub _tod_q
{
	my $indx = shift;
	my $input = shift || $inputs[$indx];

	return "e:Invalid Quarter ($input) - must be 1-4! "  if ($input < 1 || $input > 4);
	unless ($#tl >= 5) {
		$tl[3] ||= 1;
		$tl[4] = ($input-1)*3;
	}
	return '';
}

1
