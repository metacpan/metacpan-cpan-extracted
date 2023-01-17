#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

package Date::Parse::Modern;

use Carp;
use Time::Local;
use Exporter 'import';
our @EXPORT = ('strtotime');

our $VERSION = 0.2;

# If we use state the variables doesn't get instantiated EVERY time and it's much faster
# https://timezonedb.com/download
our $TZ_OFFSET = {
	'ACDT'  =>  10, 'ACST'  =>   9, 'ACT'   =>  -5, 'ACWST' =>   8, 'ADT'   =>  -3, 'AEDT'  =>  11, 'AEST'  =>  10, 'AFT'   =>   4,
	'AKDT'  =>  -8, 'AKST'  =>  -9, 'ALMT'  =>   6, 'AMST'  =>   5, 'AMT'   =>   4, 'ANAST' =>  12, 'ANAT'  =>  12, 'AQTT'  =>   5,
	'ART'   =>  -3, 'AST'   =>  -4, 'AWDT'  =>   9, 'AWST'  =>   8, 'AZOST' =>   0, 'AZOT'  =>  -1, 'AZST'  =>   5, 'AZT'   =>   4,
	'AoE'   => -12, 'BNT'   =>   8, 'BOT'   =>  -4, 'BRST'  =>  -2, 'BRT'   =>  -3, 'BST'   =>   1, 'BTT'   =>   6, 'CAST'  =>   8,
	'CAT'   =>   2, 'CCT'   =>   6, 'CDT'   =>  -5, 'CEST'  =>   2, 'CET'   =>   1, 'CHADT' =>  13, 'CHAST' =>  12, 'CHOST' =>   9,
	'CHOT'  =>   8, 'CHUT'  =>  10, 'CIDST' =>  -4, 'CIST'  =>  -5, 'CKT'   => -10, 'CLST'  =>  -3, 'CLT'   =>  -4, 'COT'   =>  -5,
	'CST'   =>  -6, 'CVT'   =>  -1, 'CXT'   =>   7, 'ChST'  =>  10, 'DAVT'  =>   7, 'DDUT'  =>  10, 'EASST' =>  -5, 'EAST'  =>  -6,
	'EAT'   =>   3, 'ECT'   =>  -5, 'EDT'   =>  -4, 'EEST'  =>   3, 'EET'   =>   2, 'EGST'  =>   0, 'EGT'   =>  -1, 'EST'   =>  -5,
	'FET'   =>   3, 'FJST'  =>  13, 'FJT'   =>  12, 'FKST'  =>  -3, 'FKT'   =>  -4, 'FNT'   =>  -2, 'GALT'  =>  -6, 'GAMT'  =>  -9,
	'GET'   =>   4, 'GFT'   =>  -3, 'GILT'  =>  12, 'GMT'   =>   0, 'GST'   =>  -2, 'GYT'   =>  -4, 'HDT'   =>  -9, 'HKT'   =>   8,
	'HOVST' =>   8, 'HOVT'  =>   7, 'HST'   => -10, 'ICT'   =>   7, 'IDT'   =>   3, 'IOT'   =>   6, 'IRDT'  =>   4, 'IRKST' =>   9,
	'IRKT'  =>   8, 'IRST'  =>   3, 'IST'   =>   2, 'JST'   =>   9, 'KGT'   =>   6, 'KOST'  =>  11, 'KRAST' =>   8, 'KRAT'  =>   7,
	'KST'   =>   9, 'KUYT'  =>   4, 'LHDT'  =>  11, 'LHST'  =>  10, 'LINT'  =>  14, 'MAGST' =>  12, 'MAGT'  =>  11, 'MART'  =>  -9,
	'MAWT'  =>   5, 'MDT'   =>  -6, 'MHT'   =>  12, 'MMT'   =>   6, 'MSD'   =>   4, 'MSK'   =>   3, 'MST'   =>  -7, 'MUT'   =>   4,
	'MVT'   =>   5, 'MYT'   =>   8, 'NCT'   =>  11, 'NDT'   =>  -2, 'NFDT'  =>  12, 'NFT'   =>  11, 'NOVST' =>   7, 'NOVT'  =>   7,
	'NPT'   =>   5, 'NRT'   =>  12, 'NST'   =>  -3, 'NUT'   => -11, 'NZDT'  =>  13, 'NZST'  =>  12, 'OMSST' =>   7, 'OMST'  =>   6,
	'ORAT'  =>   5, 'PDT'   =>  -7, 'PET'   =>  -5, 'PETST' =>  12, 'PETT'  =>  12, 'PGT'   =>  10, 'PHOT'  =>  13, 'PHT'   =>   8,
	'PKT'   =>   5, 'PMDT'  =>  -2, 'PMST'  =>  -3, 'PONT'  =>  11, 'PST'   =>  -8, 'PWT'   =>   9, 'PYST'  =>  -3, 'PYT'   =>   8,
	'QYZT'  =>   6, 'RET'   =>   4, 'ROTT'  =>  -3, 'SAKT'  =>  11, 'SAMT'  =>   4, 'SAST'  =>   2, 'SBT'   =>  11, 'SCT'   =>   4,
	'SGT'   =>   8, 'SRET'  =>  11, 'SRT'   =>  -3, 'SST'   => -11, 'SYOT'  =>   3, 'TAHT'  => -10, 'TFT'   =>   5, 'TJT'   =>   5,
	'TKT'   =>  13, 'TLT'   =>   9, 'TMT'   =>   5, 'TOST'  =>  14, 'TOT'   =>  13, 'TRT'   =>   3, 'TVT'   =>  12, 'ULAST' =>   9,
	'ULAT'  =>   8, 'UYST'  =>  -2, 'UYT'   =>  -3, 'UZT'   =>   5, 'VET'   =>  -4, 'VLAST' =>  11, 'VLAT'  =>  10, 'VOST'  =>   6,
	'VUT'   =>  11, 'WAKT'  =>  12, 'WARST' =>  -3, 'WAST'  =>   2, 'WAT'   =>   1, 'WEST'  =>   1, 'WET'   =>   0, 'WFT'   =>  12,
	'WGST'  =>  -2, 'WGT'   =>  -3, 'WIB'   =>   7, 'WIT'   =>   9, 'WITA'  =>   8, 'WST'   =>   1, 'YAKST' =>  10, 'YAKT'  =>   9,
	'YAPT'  =>  10, 'YEKST' =>   6, 'YEKT'  =>   5, 'Z'     =>   0,
};

our $LOCAL_TZ_OFFSET = undef;

our $MONTH_MAP = {
	'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4 , 'may' => 5 , 'jun' => 6 ,
	'jul' => 7, 'aug' => 8, 'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12,
};

our $MONTH_REGEXP = qr/Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|September|Oct|October|Nov|November|Dec|December/i;

# Cache repeated lookups for the same TZ offset
our $USE_TZ_CACHE = 1;

# Separator between dates pieces: '-' or '/' or '\'
our $sep = qr/[\/\\-]/;

######################################################################################################
######################################################################################################
######################################################################################################

=head1 NAME

C<Date::Parse::Modern> - Provide string to unixtime conversions

=head1 DESCRIPTION

C<Date::Parse::Modern> provides a single function C<strtotime()> which takes a textual datetime string
and returns a unixtime. Initial tests shows that C<Date::Parse::Modern> is about 40% faster than
C<Date::Parse>. Part of this speed increase may be due to the fact that we don't support as many
"unique" string formats.

Care was given to support the most modern style strings that you would commonly run in to in log
files or on the internet. Some "weird" examples that C<Date::Parse> supports but C<Date::Parse::Modern>
does B<not> would be:

  21 dec 17:05
  2000 10:02:18 "GMT"
  20020722T100000Z
  2002-07-22 10:00 Z

Corner cases like this were purposely not implemented because they're not commonly used and it would
affect performance of the more common strings.

=head1 USAGE

  use Date::Parse::Modern;

=head1 FUNCTIONS

=head2 strtotime($string)

  my $unixtime = strtotime('1979-02-24'); # 288691200

C<Date::Parse::Modern> exports the C<strtotime()> function automatically.

Simply feed C<strtotime()> a string with some type of date or time in it, and it will return an
integer unixtime. If the string is unparseable, or a weird error occurs, it will return C<undef>.

All the "magic" in C<Date::Parse::Modern> is done using regular expressions that look for common datetime
formats. Common formats like YYYY-MM-DD and HH:II:SS are easily detected and converted to the
appropriate formats. This allows the date or time to be found anywhere in the string, in (almost) any
order. In all cases, the day of the week is ignored in the input string.

B<Note:> Strings without a year are assumed to be in the current year. Example: C<May 15th, 10:15am>

B<Note:> Strings with only a date are assumed to be at the midnight. Example: C<2023-01-15>

B<Note:> Strings with only time are assumed to be the current day. Example: C<10:15am>

B<Note:> In strings with numeric B<and> textual time zone offsets, the numeric is used. Example:
C<14 Nov 1994 11:34:32 -0500 (EST)>

=head1 AUTHORS

Scott Baker <scott@perturb.org>

=cut

######################################################################################################
######################################################################################################
######################################################################################################

# The logic here is that we use regular expressions to pull out various patterns
# YYYY/MM/DD, H:I:S, DD MonthWord YYYY
sub strtotime {
	my ($str, $debug) = @_;

	if (!defined($str)) {
		return undef;
	}

	my ($year, $month, $day)    = (0,0,0);
	my ($hour, $min, $sec, $ms) = (0,0,0,0);

	####################################################################################################
	####################################################################################################

	# First we look to see if we have anything that mathches YYYY-MM-DD (numerically)
	if ($str =~ m/\b((\d{4})$sep(\d{2})$sep(\d{2})|(\d{2})$sep(\d{2})$sep(\d{4}))/) {
		# YYYY-MM-DD: 1999-12-24
		if ($2 || $3) {
			$year  = $2;
			$month = $3;
			$day   = $4;
		}

		# DD-MM-YYYY: 12-24-1999
		if ($5 || $6) {
			$day   = $5;
			$month = $6;
			$year  = $7;

			# It might be American format (MM-DD-YYYY) so we do a quick flip/flop
			if ($month > 12) {
				($day, $month) = ($month, $day);
			}
		}
	}

	# The year may be on the end of the string like: Sat May  8 21:24:31 2021
	if (!$year) {
		($year) = $str =~ m/\s(\d{4})\b/;
	}

	####################################################################################################

	# Next we look for alpha months followed by a digit if we didn't find a numeric month above
	# This will find: "April 13" and also "13 April 1995"
	if (!$month && $str =~ m/(\d{1,2})?\s*($MONTH_REGEXP)\s+(\d{1,4})/) {

		# Get the numerical number for this month
		my $month_name = lc(substr($2,0,3));
		$month = $MONTH_MAP->{$month_name};

		# 17 March 94
		if ($1) {
			$day  = int($1);
			$year = int($3);
		} else {
			$day = int($3);
		}
	}

	####################################################################################################

	# Alternate date string like like: 21/dec/93 or dec/21/93 (much less common) not sure if it's worth supporting this)
	if (!$month && $str =~ /(.*)($MONTH_REGEXP)(.*)/) {
		my $before = $1;
		my $after  = $3;

		$month = $MONTH_MAP->{lc($2)};

		# Month starts string: dec/21/93
		if ($before eq "") {
			$after =~ m/(\d{2})$sep(\d{2,4})/;

			$day  = $1;
			$year = $2;

		# Month in the middle: 21/dec/93
		} elsif ($before && $after) {
			$before =~ s/(\d+)\D/$1/g;
			$after  =~ s/\D(\d{2,4}).*/$1/g;

			$day  = $before;
			$year = $after;
		}
	}

	####################################################################################################

	# Now we look for times: 10:14, 10:14:17, 08:15pm
	if ($str =~ m/(\b|T)(\d{1,2}):(\d{1,2}):?(\d{2}(Z|\.\d+)?)?( ?am|pm|AM|PM)?\b/) {
		$hour = int($2);
		$min  = int($3);
		$sec  = $4 || 0; # Not int() cuz it might be float for milliseconds

		$sec =~ s/Z$//;

		my $ampm = lc($6 || "");

		# PM means add 12 hours
		if ($ampm eq "pm") {
			$hour += 12;
		}

		# 12:15am = 00:15 / 12:15pm = 12:15 so we have to compensate
		if ($ampm && ($hour == 24 || $hour == 12)) {
			$hour -= 12;
		}
	}

	my $has_time = ($hour || $min || $sec);
	my $has_date = ($year || $month || $day);

	if (!$has_time && !$has_date) {
		return undef;
	}

	####################################################################################################
	####################################################################################################

	# Sanity check some basic boundaries
	if ($month > 12 || $day > 31 || $hour > 23 || $min > 60 || $sec > 61) {
		return undef;
	}

	$month ||= (localtime())[4] + 1; # If there is no month, we assume the current month
	$day   ||= (localtime())[3];     # If there is no day, we assume the current day
	# If we STILL don't have a year it may be a time only string so we assume it's the current year
	$year  ||= (localtime())[5] + 1900;

	# Convert any two digit years to four digits
	if ($year < 100) {
		$year += 1900;
	}

	# If we have all the requisite pieces we build a unixtime
	my $ret;
	eval {
		$ret = Time::Local::timegm_modern($sec, $min, $hour, $day, $month - 1, $year);
	};

	# If we find a timezone offset we take that in to account now
	# Either: +1000 or -0700
	# or
	# 11:53 PST (Three or four chars after a time)
	my $tz_offset_seconds = 0;
	my $tz_str = '';
	if ($ret && $str =~ m/(\s([+-])(\d{1,2})(\d{2})|:\d{2} ([A-Z]{1,4})\b|\d{2}(Z)$)/) {

		my $str_offset = 0;
		if ($5 || $6)  {
			my $tz_code = $5 || $6 || '';

			# Timezone offsets are in hours, so we convert to seconds
			$str_offset  = $TZ_OFFSET ->{$tz_code} || 0;
			$str_offset *= 3600;

			#k("$tz_code = $str_offset");
			$tz_str = $tz_code;
		} else {
			# Break the input string into parts so we can do math
			$str_offset = ($3 + ($4 / 60)) * 3600;
			if ($2 eq "-") {
				$str_offset *= -1;
			}
			$tz_str = "$2$3$4";
		}

		$tz_offset_seconds = $str_offset;
	# No timezone to account for so we assume the local timezone
	} elsif ($ret) {
		my $local_offset = 0;

		# We get the local timezone by creating local time obj and a UTC time obj
		# and comparing the two
		$local_offset = get_local_offset($ret);

		$tz_offset_seconds = $local_offset;
		$tz_str = 'No Timezone found';
	}

	$ret -= $tz_offset_seconds;

	if ($debug) {
		my $color = "\e[38;5;45m";
		my $reset = "\e[0m";
		my $header = sprintf("%*s = YYYY-MM-DD HH:II:SS (timezone offset)", length($str) + 2, "Input string");
		my $output = sprintf("'%s' = %02d-%02d-%02d %02d:%02d:%02d (%s = %d seconds)", $str, $year || -1, $month || -1, $day || -1, $hour, $min, $sec, $tz_str, $tz_offset_seconds);

		print STDERR $color . $header . $reset . "\n";
		print STDERR $output . "\n";
	}


	return $ret;
}

sub get_local_offset {
	my $unixtime = $_[0];

	# If we have a forced LOCAL_TZ_OFFSET we use that (unit tests)
	if (defined($LOCAL_TZ_OFFSET)) {
		return $LOCAL_TZ_OFFSET;
	}

	# Simple memoizing (improves repeated performance a LOT)
	# Note: this is even faster than `use Memoize`
	state $x = {};
	if ($USE_TZ_CACHE && $x->{$unixtime}) {
		return $x->{$unixtime};
	}

	# Get a time obj for this local timezone and UTC for the Unixtime
	# Then compare the two to get the local TZ offset
	my @t   = localtime($unixtime);
	my $ret = (Time::Local::timegm(@t) - Time::Local::timelocal(@t));

	# Cache the result
	if ($USE_TZ_CACHE) {
		$x->{$unixtime} = $ret;
	}

	return $ret;
}

1;

__END__

Performance varies depending on string input

Running the entire test suite through both strtotime() (mine) and
Date::Parse::str2time() via --bench gets the following output:

$ perl -I lib compare.pl --bench
Comparing 31 strings
                      Rate         Date::Parse Date::Parse::Modern
Date::Parse         1208/s                  --                -26%
Date::Parse::Modern 1623/s                 34%                  --
