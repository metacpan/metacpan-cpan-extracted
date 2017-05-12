=head1 NAME

Date::Fmtstr2time - Functions to format date/time strings into a Perl Time based on a "Picture" format string.

=head1 AUTHOR

Jim Turner

(c) 2015, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 SYNOPSIS

use Date::Fmtstr2time;

print str2time('12-25-2015 07:15 AM', 'mm-dd-yyyy hh:mi PM');

=head1 DESCRIPTION

Date::Fmtstr2time provides a single function B<str2time> that accepts a date or date / time 
in a string (I<data-string>) and a I<format-string> consisting of special substrings which represent 
the various parts of a date and time value.  It returns a standard Perl (Unix) "time" value (a 
large integer equivalent to the number of seconds since 1980).

=head1 METHODS

=over 4

=item <$integer> = B<str2time>(I<data-string>, I<format-string>);

Returns a standard Perl (Unix) "time" value (a large integer).  The I<format-string> tells 
the software what format to expect the date / time value in the I<data-string> to be in.

For example:

$s = B<str2time>('01-09-2016 01:20 AM (Sat) (January)', 'mm-dd-yyyy hh:mi PM (Day) (Month)');

would set $s to 1452324000, (the Unix time equivalent).

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

L<Date::Time2fmtstr>, L<String::PictureFormat>, formatting, picture_clause, strings

=cut

package Date::Fmtstr2time;

use strict;
#use warnings;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.00';

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
	my $err = '';
	$rtnTime = '';
	@tl = ();
	$begofyear = timelocal(0,0,0,1,0,$today[5]);

	my $fn;
	for (my $i=0;$i<=$#fmts;$i++)
	{
		foreach my $f (qw(month Month MONTH dayofweek Dayofweek DAYOFWEEK day Day DAY ddd 
			ddmm dd d1 d0 mmddyyyy yyyymmdd yyyymm yymmdd mmyyyy mmddyy yyyy yymm mmyy yy hh24 hh 
			HH h1 H1 mi mm mon Mon MON m1 sssss ss am pm AM PM a p A P rm RM rr d ww q))
		{
			if ($fmts[$i] =~ /^$f/i)
			{
				$fn = '_tod_'.$f;
no strict 'refs';
				$err .= &$fn($i);
				last;
			}
		}
	}
	$tl[3] = '1'  unless ($tl[3]);
	my $rt = timelocal(@tl);

	return ($#tl >= 5) ? timelocal(@tl) : $rtnTime;
}

sub _tod_month
{
	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$inputs[$indx]};
	return "Invalid Month ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub _tod_mon
{
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

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{substr($inputs[$indx],0,3)};
	return "Invalid Mth ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub _tod_rm
{
	my $indx = shift;

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

	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$inputs[$indx]};
	return "Invalid Roman Mth. ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub _tod_mm
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid month ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 && $inputs[$indx] <= 12);
	$tl[4] = $inputs[$indx] - 1;
	return '';
}

sub _tod_m1
{
	return &_tod_mm(@_);
}

sub _tod_yyyymmdd
{
	my $indx = shift;
	$tl[5] = substr($inputs[$indx],0,4) - 1900;
	$tl[4] = substr($inputs[$indx],4,2) - 1;
	$tl[3] = substr($inputs[$indx],6,2);
	return '';
}

sub _tod_yyyymm
{
	my $indx = shift;
	$tl[5] = substr($inputs[$indx],0,4) - 1900;
	$tl[4] = substr($inputs[$indx],4,2) - 1;
	return '';
}

sub _tod_yymmdd
{
	my $indx = shift;
	&_tod_rr($indx);
	$tl[4] = substr($inputs[$indx],2,2) - 1;
	$tl[3] = substr($inputs[$indx],4,2);
	return '';
}

sub _tod_yymm
{
	my $indx = shift;
	&_tod_rr($indx);
	$tl[4] = substr($inputs[$indx],2,2) - 1;
	return '';
}

sub _tod_mmyyyy
{
	my $indx = shift;
	&_tod_mm($indx);
	$inputs[$indx] = substr($inputs[$indx],2,4);
	$tl[5] = substr($inputs[$indx],2,4) - 1900;
	return '';
}

sub _tod_mmyy
{
	my $indx = shift;
	&_tod_mm($indx);
	$inputs[$indx] = substr($inputs[$indx],2,2);
	&_tod_rr;
	return '';
}

sub _tod_mmddyyyy
{
	my $indx = shift;
	&_tod_mm($indx);
	$tl[3] = substr($inputs[$indx],2,2) - 1;
	$tl[5] = substr($inputs[$indx],4,4) - 1900;
	return '';
}

sub _tod_mmddyy
{
	my $indx = shift;
	&_tod_mm($indx);
	$tl[3] = substr($inputs[$indx],2,2) - 1;
	$inputs[$indx] =~ substr($inputs[$indx],4,2);
	&_tod_rr($indx);
	return '';
}

sub _tod_mmdd
{
	my $indx = shift;
	&_tod_mm($indx);
	$tl[3] = substr($inputs[$indx],2,2);
	return '';
}

sub _tod_ddmm
{
	my $indx = shift;
	&_tod_dd($indx);
	$tl[4] = substr($inputs[$indx],2,2) - 1;
	return '';
}

sub _tod_yyyy
{
	my $indx = shift;
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d\d\d$/);
	$tl[5] = $inputs[$indx] - 1900;
	return '';
}

sub _tod_yy
{
	return &_tod_rr(shift);
}

sub _tod_rr
{
	my $indx = shift;
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d$/);
	if (($today[5] % 100) > 50)
	{
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	else
	{
		#$inputs[$indx] -= 100  if ($inputs[$indx] > 50);
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	$tl[5] = $inputs[$indx];
	return '';
}

sub _tod_rrrr
{
	my $indx = shift;
	return &_tod_rr($indx)  if ($inputs[$indx] =~ /^\d\d?$/);
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d\d\d?$/);
	if (($today[5] % 100) > 50)
	{
		$inputs[$indx] += 100  if (($inputs[$indx] % 100) < 50);
	}
	else
	{
		#$inputs[$indx] -= 100  if (($inputs[$indx] % 100) > 50);
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	$tl[5] = $inputs[$indx] - 1900;
	return '';
}

sub _tod_ddd
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0+//;
	return "Invalid year-day ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 and $inputs[$indx] <= 366);
	$rtnTime += $begofyear + (($inputs[$indx]*86400) - 86400)  unless ($rtnTime > 86400);
	return '';
}

sub _tod_dd
{
	my $indx = shift;
	return "Invalid day ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 and $inputs[$indx] <= 31);
	$inputs[$indx] =~ s/^0//;
	$tl[3] = $inputs[$indx];
	return '';
}

sub _tod_d1
{
	return &_tod_dd(@_);
}

sub _tod_hh
{
	my $indx = shift;
	return "Invalid hour ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] < 24);
	$tl[2] = $inputs[$indx]  unless ($tl[2] =~ /\d/);
	$rtnTime += ($inputs[$indx] * 3600)  if ($rtnTime);
	return '';
}

sub _tod_h1
{
	return &_tod_hh(@_);
}

sub _tod_H1
{
	return &_tod_hh(@_);
}

sub _tod_hh24
{
	my $indx = shift;
	return "Invalid 24-hr time ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 2400 
			and ($inputs[$indx] % 100) < 60);
	$tl[1] = ($inputs[$indx] % 100);
	$inputs[$indx] = int($inputs[$indx] / 100);
	return "Invalid 24-hr time ($inputs[$indx])! "
			unless ($inputs[$indx] > 0 and $inputs[$indx] < 24);
	$tl[2] = $inputs[$indx];
	return '';
}

sub _tod_HH
{
	my $indx = shift;
	return &_tod_hh($indx);
}

sub _tod_a
{
	my $indx = shift;
	if ($tl[2] < 12)
	{
		$tl[2] += 12  if ($inputs[$indx] =~ /p/io);
	}
	else
	{
		$tl[2] -= 12  if ($inputs[$indx] =~ /a/io);
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
	$inputs[$indx] =~ s/^0//;
	return "Invalid minutes ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 59);
	$tl[1] = $inputs[$indx];
	$rtnTime += ($inputs[$indx] * 60)  if ($rtnTime);
	return '';
}

sub _tod_sssss
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid seconds ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 86400);
	$tl[2] = int($inputs[$indx] / 3600);
	$tl[0] = $inputs[$indx] % 60;
	$tl[1] = int($inputs[$indx]/60) % 60;
	$rtnTime += $inputs[$indx];
	return '';
}

sub _tod_ss
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid seconds ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 59);
	$tl[0] = $inputs[$indx];
	$rtnTime += $inputs[$indx];
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
	my %dayhash = (
		'sun' => '0',
		'mon' => 1,
		'tue' => 2,
		'wed' => 3,
		'thu' => 4,
		'fri' => 5,
		'sat' => 6
	);

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	return "Invalid Day ($inputs[$indx])! "  unless (defined $mthhash{$inputs[$indx]});
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
	my %dayhash = (
		'sunday' => '0',
		'monday' => 1,
		'tuesday' => 2,
		'wednesday' => 3,
		'thursday' => 4,
		'friday' => 5,
		'saturday' => 6
	);

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	return "Invalid Day ($inputs[$indx])! "  unless (defined $dayhash{$inputs[$indx]});
	return '';
}

sub _tod_Dayofweek
{
	return &_tod_day(@_);
}

sub _tod_DAYOFWEEK
{
	return &_tod_day(@_);
}

sub _tod_ww
{
	return '';
}

sub _tod_q
{
	return '';
}

1
