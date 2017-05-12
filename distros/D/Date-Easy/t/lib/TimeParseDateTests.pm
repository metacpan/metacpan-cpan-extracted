package TimeParseDateTests;

use strict;
use warnings;
use autodie;

use Test::More;
use List::Util 1.29 qw< pairgrep pairmap >;			# minimum version for pairgrep/pairmap

# This giant variable is shamlessly stolen from the test file for Time::ParseDate.
# This is taken from MUIR/Time-ParseDate-2015.103/t/datetime.t.
# Applied `my` and quoted barewords; lines commented out are verbatim from the original.


	my
	@sdt = (
		796969332, ['950404 00:22:12 "EDT'],
		796969332, ['950404 00:22:12.500 "EDT'],
		796969332.5, ['950404 00:22:12.500 "EDT', SUBSECOND => 1],
		786437763, ['Fri Dec  2 22:56:03 1994', NOW => 785300000],
		786437763, ['Fri Dec  2 22:56:03 1994,', NOW => 785300000, WHOLE => 0],
		786408963, ['Fri Dec  2 22:56:03 GMT+0 1994', NOW => 785300000],
		786408963, ['Fri Dec  2 22:56:03 GMT+0 1994,', NOW => 785300000, WHOLE => 0],
		786408963, ['Fri Dec  2 22:56:03.500 GMT+0 1994', NOW => 785300000],
		786408963.5, ['Fri Dec  2 22:56:03.500 GMT+0 1994', SUBSECOND => 1, NOW => 785300000],
		786437763, ['Fri Dec  2 22:56:03 GMT-8 1994', NOW => 785300000],
		786437763, ['Fri Dec  2 22:56:03 GMT-8 1994, stuff', NOW => 785300000, WHOLE => 0],
		786437760, ['94/12/02.22:56', NOW => 785300000],
		786437760, ['1994/12/02 10:56Pm', NOW => 785300000],
		786437760, ['1994/12/2 10:56 PM', NOW => 785300000],
		786437760, ['12/02/94 22:56', NOW => 785300000],
		786437760, ['12/02/94 22:56.', NOW => 785300000, WHOLE => 0],
		786437760, ['12/2/94 10:56Pm', NOW => 785300000],
		786437760, ['94/12/2 10:56 pm', NOW => 785300000],
		786437763, ['94/12/02 22:56:03', NOW => 785300000],
		786437763, ['94/12/02 22:56:03.500', NOW => 785300000],
		786437763.5, ['94/12/02 22:56:03.500', SUBSECOND => 1, NOW => 785300000],
		786437763, ['94/12/02 10:56:03:500PM', NOW => 785300000],
		786437763.5, ['94/12/02 10:56:03:500PM', SUBSECOND => 1, NOW => 785300000],
		786437760, ['10:56Pm 94/12/02', NOW => 785300000],
		786437763, ['22:56:03 1994/12/02', NOW => 785300000],
		786437763, ['22:56:03.5 1994/12/02', NOW => 785300000],
		786437763.5, ['22:56:03.5 1994/12/02', SUBSECOND => 1,  NOW => 785300000],
		786437760, ['22:56 1994/12/2', NOW => 785300000],
		786437760, ['10:56PM 12/02/94', NOW => 785300000],
		786437760, ['10:56 pm 12/2/94', NOW => 785300000],
#		786437760, ['10:56 pm 12/2/94, when', NOW => 785300000, WHOLE => 0],
		786437760, ['22:56 94/12/2', NOW => 785300000],
		786437760, ['10:56Pm 94/12/02', NOW => 785300000],
		796980132, ['Tue Apr 4 00:22:12 PDT 1995'],
		796980132, ['April 4th 1995 12:22:12AM', ZONE => 'PDT'],
		827878812, ['Tue Mar 26 14:20:12 1996'],
		827878812, ['Tue Mar 26 14:20:12 1996', SUBSECOND => 1],
		827878812, ['Tue Mar 26 14:20:12.5 1996, and then', WHOLE => 0],
		827878812.5, ['Tue Mar 26 14:20:12.5 1996', SUBSECOND => 1],
		827878812, ['Tue Mar 26 14:20:12 GMT-0800 1996'],
		827878812, ['Tue Mar 26 17:20:12 EST 1996'],
		827878812, ['Tue Mar 26 17:20:12 EST 1996, before Joe', WHOLE => 0],
		827878812, ['Tue Mar 26 17:20:12 GMT-0500 1996'],
		827878812, ['Tue Mar 26 22:20:12 GMT 1996'],
		827878812, ['Tue Mar 26 22:20:12 +0000 (GMT) 1996'],
		827878812, ['Tue, 26 Mar 22:20:12 +0000 (GMT) 1996'],
		784394917, ['Wed, 9 Nov 1994 7:28:37'],
		784394917, ['Wed, 9 Nov 1994 7:28:37: Seven', WHOLE => 0],
		784887518, ['Tue, 15 Nov 1994 0:18:38'],
		788058300, ['21 dec 17:05', NOW => 785300000],
		802940400, ['06/12/1995'],
		802940400, ['12/06/1995', UK => 1],
		802940400, ['12/06/95', UK => 1],
		802940400, ['06.12.1995'],
		802940400, ['06.12.1995, Fred', WHOLE => 0],
		803026800, ['13/06/1995'],
		803026800, ['13/06/95'],
		784394917, ['Wed, 9 Nov 1994 15:28:37 +0000 (GMT)'],
		827878812, ['Tue Mar 26 23:20:12 GMT+0100 1996'],
		827878812, ['Wed Mar 27 05:20:12 GMT+0700 1996'],
		827878812, ['Wed Mar 27 05:20:12 +0700 1996'],
		827878812, ['Wed Mar 27 05:20:12 +07:00 1996'],
		827878812, ['Wed Mar 27 05:20:12 +0700 (EST) 1996'],
		796980132, ['1995/04/04 00:22:12 PDT'],
		796720932, ['1995/04 00:22:12 PDT'],
		796980132, ['1995/04/04 00:22:12 PDT'],
		796980132, ['Tue, 4 Apr 95 00:22:12 PDT'],
		796980132, ['Tue 4 Apr 1995 00:22:12 PDT'],
		796980132, ['04 Apr 1995 00:22:12 PDT'],
		796980132, ['4 Apr 1995 00:22:12 PDT'],
		796980132, ['Tue, 04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['Tue 04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 04 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 4 00:22:12 PDT', NOW => 796980132],
		796980132, ['Tue, Apr 4 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 4 1995 00:22:12 PDT'],
		796980132, ['April 4th 1995 00:22:12 PDT'],
		796980132, ["April 4th, '95 00:22:12 PDT"],
		796980132, ["April 4th 00:22:12 PDT", NOW => 796980132],
		796980132, ['95/04/04 00:22:12 PDT'],
		796980132, ['04/04/95 00:22:12 PDT'],
		796720932, ['95/04 00:22:12 PDT'],
		796720932, ['04/95 00:22:12 PDT'],
		796980132, ['04/04 00:22:12 PDT', NOW => 796980132],
		796980132, ['040495 00:22:12 PDT'],
		796980132, ['950404 00:22:12 PDT'],
		796969332, ['950404 00:22:12 EDT'],
		796980132, ['04.04.95 00:22:12', ZONE => 'PDT'],
		796980120, ['04.04.95 00:22', ZONE => 'PDT'],
		796978800, ['04.04.95 12AM', ZONE => 'PDT'],
		796978800, ['04.04.95 12am', ZONE => 'PDT'],
		796980120, ['04.04.95 0022', ZONE => 'PDT'],
		796980132, ['04.04.95 12:22:12am', ZONE => 'PDT'],
		797023332, ['950404 122212', ZONE => 'PDT'],
		797023332, ['122212 950404', ZONE => 'PDT', TIMEFIRST => 1],
		796980120, ['04.04.95 12:22AM', ZONE => 'PDT'],
		796978800, ['95/04/04 midnight', ZONE => 'PDT'],
		796978800, ['95/04/04 Midnight', ZONE => 'PDT'],
		797022000, ['95/04/04 Noon', ZONE => 'PDT'],
		797022000, ['95/04/04 noon', ZONE => 'PDT'],
		797022000, ['95/04/04 12Pm', ZONE => 'PDT'],
		796978803, ['+3 secs', NOW => 796978800],
		796979600, ['+0800 seconds', NOW => 796978800],
		796979600, ['+0800 seconds, Nothing', NOW => 796978800, WHOLE => 0],
		796986000, ['+2 hour', NOW => 796978800],
		796979400, ['+10min', NOW => 796978800],
		796979400, ['+10 minutes', NOW => 796978800],
		797011203, ['95/04/04 +3 secs', ZONE => 'EDT', NOW => 796935600],
		797062935, ['4 day +3 secs', ZONE => 'PDT', NOW => 796720932],
		797062935, ['now + 4 days +3 secs', ZONE => 'PDT', NOW => 796720932],
		797062935, ['now +4 days +3 secs', ZONE => 'PDT', NOW => 796720932],
		796720932, ['now', ZONE => 'PDT', NOW => 796720932],
		796720936, ['now +4 secs', ZONE => 'PDT', NOW => 796720932],
		796735332, ['now +4 hours', ZONE => 'PDT', NOW => 796720932],
		797062935, ['+4 days +3 secs', ZONE => 'PDT', NOW => 796720932],
		797062935, ['+ 4 days +3 secs', ZONE => 'PDT', NOW => 796720932],
		797062929, ['4 day -3 secs', ZONE => 'PDT', NOW => 796720932],
		796375329, ['-4 day -3 secs', ZONE => 'PDT', NOW => 796720932],
		796375329, ['now - 4 days -3 secs', ZONE => 'PDT', NOW => 796720932],
		796375329, ['now -4 days -3 secs', ZONE => 'PDT', NOW => 796720932],
		796720928, ['now -4 secs', ZONE => 'PDT', NOW => 796720932],
		796706532, ['now -4 hours', ZONE => 'PDT', NOW => 796720932],
		796375329, ['-4 days -3 secs', ZONE => 'PDT', NOW => 796720932],
		796375329, ['- 4 days -3 secs', ZONE => 'PDT', NOW => 796720932],
		797322132, ['1 week', NOW => 796720932],
		801987732, ['2 month', NOW => 796720932],
		804579732, ['3 months', NOW => 796720932],
		804579732, ['3 months, 7 days', NOW => 796720932, WHOLE => 0],  # perhaps this is wrong
		859879332, ['2 years', NOW => 796720932],
		797671332, ['Wed after next', NOW => 796980132],
		797498532, ['next monday', NOW => 796980132],
		797584932, ['next tuesday', NOW => 796980132],
		797584932, ['next tuesday, the 9th', NOW => 796980132, WHOLE => 0],  # perhaps this is wrong
		797066532, ['next wEd', NOW => 796980132],
		796378932, ['last tuesday', NOW => 796980132],
		796465332, ['last wednesday', NOW => 796980132],
		796893732, ['last monday', NOW => 796980132],
		797036400, ['today at 4pm', NOW => 796980132],
		797080932, ['tomorrow +4hours', NOW => 796980132],
		796950000, ['yesterday at 4pm', NOW => 796980132],
		796378932, ['last week', NOW => 796980132],
		794305332, ['last month', NOW => 796980132],
		765444132, ['last year', NOW => 796980132],
		797584932, ['next week', NOW => 796980132],
		799572132, ['next month', NOW => 796980132],
		828606132, ['next year', NOW => 796980132],
		836391600, ['July 3rd, 4:00AM 1996 ', DATE_REQUIRED =>1, TIME_REQUIRED=>1, NO_RELATIVE=>1, NOW=>796980132],
		783718105, ['Tue, 01 Nov 1994 11:28:25 -0800'],
		202779300, ['5:35 pm june 4th CST 1976'],
		236898000, ['5pm EDT 4th july 1977'],
		236898000, ['5pm EDT 4 july 1977'],
		819594300, ['21-dec 17:05', NOW => 796980132],
		788058300, ['21-dec 17:05', NOW => 796980132, PREFER_PAST => 1],
		819594300, ['21-dec 17:05', NOW => 796980132, PREFER_FUTURE => 1],
		793415100, ['21-feb 17:05', NOW => 796980132, PREFER_PAST => 1],
		824951100, ['21-feb 17:05', NOW => 796980132, PREFER_FUTURE => 1],
		819594300, ['21/dec 17:05', NOW => 796980132],
		756522300, ['21/dec/93 17:05'],
		788058300, ['dec 21 1994 17:05'],
		788058300, ['dec 21 94 17:05'],
		788058300, ['dec 21 94 17:05'],
		796465332, ['Wednesday', NOW => 796980132, PREFER_PAST => 1],
		796378932, ['Tuesday', NOW => 796980132, PREFER_PAST => 1],
		796893732, ['Monday', NOW => 796980132, PREFER_PAST => 1],
		797066532, ['Wednesday', NOW => 796980132, PREFER_FUTURE => 1],
		797584932, ['Tuesday', NOW => 796980132, PREFER_FUTURE => 1],
		797498532, ['Monday', NOW => 796980132, PREFER_FUTURE => 1],
		802915200, ['06/12/1995', ZONE => 'GMT'],
		828860438, ['06/Apr/1996:23:00:38 -0800'],
		828860438, ['06/Apr/1996:23:00:38'],
		828943238, ['07/Apr/1996:23:00:38 -0700'],
		828878618, ['07/Apr/1996:12:03:38', ZONE => 'GMT'],
		828856838, ['06/Apr/1996:23:00:38 -0700'],
		828946838, ['07/Apr/1996:23:00:38 -0800'],
		895474800, ['5/18/1998'],
		796980132, ['04/Apr/1995:00:22:12', ZONE => 'PDT'],
		796983732, ['04/Apr/1995:00:22:12 -0800'],
		796983732, ['04/Apr/1995:00:22:12', ZONE => 'PST'],
		202772100, ['5:35 pm june 4th 1976 EDT'],
		796892400, ['04/03', NOW => 796980132, PREFER_PAST => 1],
		765702000, ['04/07', NOW => 796980132, PREFER_PAST => 1],
		883641600, ['1/1/1998', VALIDATE => 1],
		852105600, ['1/1/1997'],
		852105600, ['last year', NOW => 883641600],
		820483200, ['-2 years', NOW => 883641600],
		832402800, ['-2 years', NOW => 895474800],
		891864000, ['+3 days', NOW => 891608400],
		891777600, ['+2 days', NOW => 891608400],
		902938515, ['1998-08-12 12:15:15', ZONE => 'EDT'],
		946684800, ['2000-01-01 00:00:00', ZONE => 'GMT'],
		1262304000, ['2010-01-01 00:00:00', ZONE => 'GMT'],
		757065600, ['12/28/93', NOW => 1262304000],
		1924675200, ['12/28/30', NOW => 1262304000],
		946751430, ['Jan  1 2000 10:30:30AM'],
		946722083, ['Sat Jan  1 02:21:23 2000'],
		946774740, ['Jan 1 2000 4:59PM', WHOLE => 1],
		946774740, ['Jan  1 2000  4:59PM', WHOLE => 1],
		0, ['1970/01/01 00:00:00', ZONE => 'GMT'],
		796980132, ['Tue 4 Apr 1995 00:22:12 PDT 8', WHOLE => 0],
		789008700, ['dec 32 94 17:05'],
		796983072, ['1995/04/04 00:71:12 PDT'],
		undef, ['1995/04/04 00:71:12 PDT', VALIDATE => 1],
		undef, ['38/38/21', VALIDATE => 1],
		undef, ['dec 32 94 17:05', VALIDATE => 1],
		undef, ['Tue 4 Apr 1995 00:22:12 PDT 8', WHOLE => 1],
		undef, ['Tue 4 Apr 199 00:22:12 PDT'],
		1924675200, ['12/28/30', NOW => 1262304000, PREFUR_FUTURE => 1],
		1924675200, ['28/12/30', NOW => 1262304000, PREFUR_FUTURE => 1, UK => 1],
		-1578240000, ['12/28/19', NOW => 902938515, PREFER_PAST => 1],
		-347155200, ['1959-01-01 00:00:00', ZONE => 'GMT'],
		-158083200, ['12/28/64', NOW => 902938515],
		-1231084800, ['12/28/30', NOW => 1262304000, PREFER_PAST => 1],
		-345600, ['1969-12-28 00:00:00', ZONE => 'GMT'],
		-1231084800, ['28/12/30', NOW => 1262304000, PREFER_PAST => 1, UK => 1],
		1577520000, ['12/28/19', NOW => 902938515, PREFER_FUTURE => 1],
		1766908800, ['12/28/25', NOW => 902938515],
		958521600, ['17 May 2000 00:00:00 GMT'],
		979718400, ['1/17/01', NOW => 993067736],
		995353200, ['7/17/01', NOW => 993067736],
		995353200, ['7/17/01', NOW => 993067736, PREFER_FUTURE => 1],
		995366188, ['17/07/2001 18:36:28 +0800', WHOLE => 1],
		995366188, ['17/07/2001 18:36:28+0800', WHOLE => 1],
		995330188, ['17/07/2001 0:36:28+0000', WHOLE => 1],
		995416588, ['17/07/2001 24:36:28+0000', WHOLE => 1],
		undef, ['17/07/2001 24:36:28+0000', WHOLE => 1, VALIDATE => 1],
		995330188, ['17/07/2001 0:36:28+0000', WHOLE => 1, VALIDATE => 1],
		796375332, ['4 days ago', WHOLE =>1, ZONE => 'PDT', NOW => 796720932],
		796720931, ['1 second ago', WHOLE =>1, ZONE => 'PDT', NOW => 796720932],
		796375331, ['4 days 1 second ago', WHOLE =>1, ZONE => 'PDT', NOW => 796720932],
		796375331, ['1 second 4 days ago', WHOLE =>1, ZONE => 'PDT', NOW => 796720932],
		953467299, ['Sun Mar 19 17:31:39 IST 2000'],
		784111777, ['Sunday, 06-Nov-94 08:49:37 GMT' ],
		954933672, ['Wed Apr  5 13:21:12 MET DST 2000' ],
		729724230, ['1993-02-14T13:10:30', NOW => 796980132],
#ISO8601		729724230, ['19930214T131030', NOW => 796980132],
		14400, ['+4 hours', NOW => 0],
		345600, ['+4 days', NOW => 0],
		957744000, ['Sunday before last', NOW => 958521600],
		957139200, ['Sunday before last', NOW => 958348800],
		796720930.5, ['1.5 second ago', WHOLE =>1.5, ZONE => 'PDT', NOW => 796720932],
		796720930.5, ['1 1/2 second ago', WHOLE =>1.5, ZONE => 'PDT', NOW => 796720932],
		5, ['5 seconds', UK => 1, NOW => 0],
		6, ['5 seconds', UK => 1, NOW => 1],
		1078876800, ['2004-03-10 00:00:00 GMT'],
		1081551599, ['-1 second +1 month', NOW => 1078876800, ZONE => 'PDT'],
		1081526399, ['-1 second +1 month', NOW => 1078876800, ZONE => 'GMT'],
		1304661600, ['11pm', NOW => 1304611460],
		1304636400, ['11pm', NOW => 1304611460, GMT => 1],
		1304557200, ['1am', NOW => 1304611460, GMT => 1],
		1246950000, ['2009/7/7'],
		-1636819200, ['1918/2/18'],
		1246950000, ['2009/7/7'],
		1256435700, ['2009-10-25 02:55:00', ZONE => 'MET'],
		1256439300, ['+ 1 hour', NOW => 1256435700, ZONE => 'MET'],
		1256464500, ['2009-10-25 02:55:00', ZONE => 'PDT'],
		1256468100, ['+ 1 hour', NOW => 1256464500, ZONE => 'PDT'],
		1256468100, ['2009-10-25 02:55:00', ZONE => 'PST'],
		1256471700, ['+ 1 hour', NOW => 1256468100, ZONE => 'PST'],
		[1304622000, 'Foo'], ['12pm Foo', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo 12pm', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo noon', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo midnight', NOW => 1304611460, WHOLE => 0],
		1011252345, ['Wed Jan 16 23:25:45 2002'],
		1012550400, ['Feb 1', NOW => 1011252345],
		1012550400, ['Feb 1', NOW => 1011252345, FUZZY => 1, PREFER_FUTURE => 1],
		1012550400, ['2/1/02', NOW => 1011252345, FUZZY => 1, PREFER_FUTURE => 1],
		1011247200, ['6am', GMT => 1, NOW => 1011252345],
		1256435700, ['2009-10-25 02:55:00', ZONE => 'MEZ'],
		1348073459, ['2012-09-19 09:50:59'],
		1348073459.344702843, ['2012-09-19 09:50:59.344702843', SUBSECOND => 1],
		1304233200, ['May 1, 2011', WHOLE => 1],
		1304233200, ['May 1, 2011', WHOLE => 0],
		1301641200, ['April 1, 2011', WHOLE => 0],
		1301641200, ['April 1, 2011', WHOLE => 1],
		);


# Now let's turn this data into something a bit easier to deal with:
# (Note that this is more complicated than t/lib/DateParseTests.pm.
# That uses a hash which is key=input_string, value=return_value.
# We can't use a hash, because there are duplicate input strings
# (e.g. with different extra parameters).  So this one is
# 	input_string, [ return_value, @extra_params ], ...
# and you just have to cycle through the array 2 elements at a time.)

our @TIME_PARSE_DATE_TESTS =
	pairmap { shift @$b => [ ref $a eq 'ARRAY' ? $a->[0] : $a, @$b ] }
	@sdt;


# And we'll go ahead and export our hash.
# This is only ever used by test files anyway.

use parent 'Exporter';
our @EXPORT_OK = qw< @TIME_PARSE_DATE_TESTS get_ymd_from_parsedate >;


####################################################################################################
# This is a stolen and hacked up copy of parsedate from Time::ParseDate as of v2015.103.  Its
# purpose is to return a number of epoch seconds *without* doing any timezone adjustment.  This is
# then used by a small function (get_ymd_from_parsedate) directly underneath it, which just pulls
# out the year, month, and day from the seconds.  This gives us a YMD to construct a date object
# with, which we can compare against what the parsedate fallback in Date::Easy::Date produces.  If
# the two don't match, there's likely a problem somewhere.
#
# For this purpose, we have changed the parsedate code only minimally.  Specifically:
#	*	All debugging printing is removed.
#	*	All references to `$parse` (which was only used if `$debug` was true) are removed.
#	*	The call to `jd_secondsgm` is changed to `jd_secondslocal` (because all dates for
#		Date::Easy::Date are parsed locally, then stored as GMT).
#	*	The block of code starting with `if ($tz)` (lines 358-395 in the original file) is excised
#		completely.  This is the sum of all the timezone adjustements.
# Other than those changes, the code should be identical.
#
# In order to let the code call the functions it wants, we have import a number of non-exported
# functions, which we do by coderef aliasing.  We also have to suck in whatever Time::JulianDay
# exports, and the `%mtable` hash from Time::ParseDate.
#
# Note that we have to pull in one line of code from outside the parsedate sub: the definition of
# `$break`.  Also note that the copied code is changed so minimally that we even left the few cases
# of whitespace at the ends of lines.
####################################################################################################

use Time::ParseDate '%mtable';
use Time::JulianDay;
*righttime = \&Time::ParseDate::righttime;
*parse_tz_only = \&Time::ParseDate::parse_tz_only;
*parse_time_only = \&Time::ParseDate::parse_time_only;
*parse_date_only = \&Time::ParseDate::parse_date_only;
*parse_year_only = \&Time::ParseDate::parse_year_only;
*parse_time_offset = \&Time::ParseDate::parse_time_offset;
*parse_date_offset = \&Time::ParseDate::parse_date_offset;
*expand_two_digit_year = \&Time::ParseDate::expand_two_digit_year;

my $break = qr{(?:\s+|\Z|\b(?![-:.,/]\d))};

sub parsedate
{
        my ($t, %options) = @_;

        my ($y, $m, $d);        # year, month - 1..12, day
        my ($H, $M, $S);        # hour, minute, second
        my $tz;                 # timezone
        my $tzo;                # timezone offset
        my ($rd, $rs);          # relative days, relative seconds

        my $rel;                # time&|date is relative

        my $isspec;
        my $now = defined($options{NOW}) ? $options{NOW} : time;
        my $passes = 0;
        my $uk = defined($options{UK}) ? $options{UK} : 0;

	if ($t =~ s#^   ([ \d]\d) 
			/ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			/ (\d\d\d\d)
			: (\d\d)
			: (\d\d)
			: (\d\d)
			(?:
			 [ ]
			 ([-+] \d\d\d\d)
			  (?: \("?(?:(?:[A-Z]{1,4}[TCW56])|IDLE)\))?
			 )?
			 $break
			##xi) { #"emacs
		# [ \d]/Mon/yyyy:hh:mm:ss [-+]\d\d\d\d
		# This is the format for www server logging.

		($d, $m, $y, $H, $M, $S, $tzo) = ($1, $mtable{"\u\L$2"}, $3, $4, $5, $6, $7 ? &mkoff($7) : ($tzo || undef));
	} elsif ($t =~ s#^(\d\d)/(\d\d)/(\d\d)\.(\d\d)\:(\d\d)($break)##) {
		# yy/mm/dd.hh:mm
		# I support this format because it's used by wbak/rbak
		# on Apollo Domain OS.  Silly, but historical.

		($y, $m, $d, $H, $M, $S) = ($1, $2, $3, $4, $5, 0);
        } else {
                while(1) {
                        if (! defined $m and ! defined $rd and ! defined $y
                                and ! ($passes == 0 and $options{'TIMEFIRST'}))
                        {
                                # no month defined.
                                if (&parse_date_only(\$t, \$y, \$m, \$d, $uk)) {
                                        next;
                                }
                        }
                        if (! defined $H and ! defined $rs) {
                                if (&parse_time_only(\$t, \$H, \$M, \$S,
                                        \$tz, %options))
                                {
                                        next;
                                }
                        }
                        next if $passes == 0 and $options{'TIMEFIRST'};
                        if (! defined $y) {
                                if (&parse_year_only(\$t, \$y, $now, %options)) {
                                        next;
                                }
                        }
                        if (! defined $tz and ! defined $tzo and ! defined $rs
                                and (defined $m or defined $H))
                        {
                                if (&parse_tz_only(\$t, \$tz, \$tzo)) {
                                        next;
                                }
                        }
                        if (! defined $H and ! defined $rs) {
                                if (&parse_time_offset(\$t, \$rs, %options)) {
                                        $rel = 1;
                                        next;
                                }
                        }
                        if (! defined $m and ! defined $rd and ! defined $y) {
                                if (&parse_date_offset(\$t, $now, \$y,
                                        \$m, \$d, \$rd, \$rs, %options))
                                {
                                        $rel = 1;
                                        next;
                                }
                        }
                        if (defined $M or defined $rd) {
                                if ($t =~ s/^\s*(?:at|\@|\+)($break)//x) {
                                        $rel = 1;
                                        next;
                                }
                        }
                        last;
                } continue {
                        $passes++;

                }

                if ($passes == 0) {
			return (undef, "no match on time/date") 
				if wantarray();
			return undef;
                }
        }

	$t =~ s/^\s+//;

	if ($t ne '') {
		# we didn't manage to eat the string
		if ($options{WHOLE}) {
			return (undef, "characters left over after parse")
				if wantarray();
			return undef 
		}
	}

	# define a date if there isn't one already

	if (! defined $y and ! defined $m and ! defined $rd) {
		if (defined $rs or defined $H) {
			# we do have a time.
			if ($options{DATE_REQUIRED}) {
				return (undef, "no date specified")
					if wantarray();
				return undef;
			}
			if (defined $rs) {
				my $rv = $now + $rs;
				return ($rv, $t) if wantarray();
				return $rv;
			}
			$rd = 0;
		} else {
			return (undef, "no time specified")
				if wantarray();
			return undef;
		}
	}

	if ($options{TIME_REQUIRED} && ! defined($rs) 
		&& ! defined($H) && ! defined($rd))
	{
		return (undef, "no time found")
			if wantarray();
		return undef;
	}

	my $secs;
	my $jd;

        if (defined $rd) {
                if (defined $rs || ! (defined($H) || defined($M) || defined($S))) {
                        my ($j, $in, $it);
                        my $definedrs = defined($rs) ? $rs : 0;
                        my ($isdst_now, $isdst_then);
                        my $r = $now + $rd * 86400 + $definedrs;
                        #
                        # It's possible that there was a timezone shift
                        # during the time specified.  If so, keep the
                        # hours the "same".
                        #
                        $isdst_now = (localtime($r))[8];
                        $isdst_then = (localtime($now))[8];
                        if (($isdst_now == $isdst_then) || $options{GMT})
                        {
				return ($r, $t) if wantarray();
				return $r 
                        }
                }

                $jd = $options{GMT}
                        ? gm_julian_day($now)
                        : local_julian_day($now);
                $jd += $rd;
        } else {
                unless (defined $y) {
                        if ($options{PREFER_PAST}) {
                                my ($day, $mon011);
                                ($day, $mon011, $y) = (&righttime($now))[3,4,5];

                                $y -= 1 if ($mon011+1 < $m) ||
                                        (($mon011+1 == $m) && ($day < $d));
                        } elsif ($options{PREFER_FUTURE}) {
                                my ($day, $mon011);
                                ($day, $mon011, $y) = (&righttime($now))[3,4,5];
                                $y += 1 if ($mon011 >= $m) ||
                                        (($mon011+1 == $m) && ($day > $d));
                        } else {
                                $y = (localtime($now))[5];
                        }
                        $y += 1900;
                }

                $y = expand_two_digit_year($y, $now, %options)
                        if $y < 100;

                if ($options{VALIDATE}) {
                        require Time::DaysInMonth;
                        my $dim = Time::DaysInMonth::days_in($y, $m);
                        if ($y < 1000 or $m < 1 or $d < 1
                                or $y > 9999 or $m > 12 or $d > $dim)
                        {
				return (undef, "illegal YMD: $y, $m, $d")
					if wantarray();
				return undef;
                        }
                }
                $jd = julian_day($y, $m, $d);
        }

	# put time into HMS

	if (! defined($H)) {
		if (defined($rd) || defined($rs)) {
			($S, $M, $H) = &righttime($now, %options);
		} 
	}

	my $carry;

	#
	# add in relative seconds.  Do it this way because we want to
	# preserve the localtime across DST changes.
	#

	$S = 0 unless $S; # -w
	$M = 0 unless $M; # -w
	$H = 0 unless $H; # -w

	if ($options{VALIDATE} and
		($S < 0 or $M < 0 or $H < 0 or $S > 59 or $M > 59 or $H > 23)) 
	{
		return (undef, "illegal HMS: $H, $M, $S") if wantarray();
		return undef;
	}

	$S += $rs if defined $rs;
	$carry = int($S / 60) - ($S < 0 && $S % 60 && 1);
	$S -= $carry * 60;
	$M += $carry;
	$carry = int($M / 60) - ($M < 0 && $M % 60 && 1);
	$M %= 60;
	$H += $carry;
	$carry = int($H / 24) - ($H < 0 && $H % 24 && 1);
	$H %= 24;
	$jd += $carry;

	$secs = jd_secondslocal($jd, $H, $M, $S);

	return ($secs, $t) if wantarray();
	return $secs;
}

sub get_ymd_from_parsedate
{
	my ($d,$m,$y) = (localtime(scalar parsedate(shift)))[3,4,5];
	return ($y + 1900, ++$m, $d);
}


1;
