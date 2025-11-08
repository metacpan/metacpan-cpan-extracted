#!/usr/bin/env perl

package Date::Parse::Modern;

use strict;
use warnings;
use v5.10;

use Carp;
use Time::Local 1.26;
use Exporter 'import';
our @EXPORT = ('strtotime');

###############################################################################

# https://pause.perl.org/pause/query?ACTION=pause_operating_model#3_5_factors_considering_in_the_indexing_phase
our $VERSION = '0.8';

# https://timezonedb.com/download
my $TZ_OFFSET = {
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

# Separator between dates pieces: '-' or '/' or '\'
my $sep = qr/[\/\\-]/;

# Force a local timezone offset (used for unit tests)
our $LOCAL_TZ_OFFSET = undef;

# Use caching for repeated lookups for the same TZ offset
our $USE_TZ_CACHE = 1;

# These are undocumented package variables. They could be changed to support
# alternate languages but there are caveats. These are cached and changing
# them after strtotime() is called won't affect anything. No one has requested
# alternate languages, so I'm leaving this undocumented for now.
our $MONTH_MAP = {
	'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4 , 'may' => 5 , 'jun' => 6 ,
	'jul' => 7, 'aug' => 8, 'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12,
};

# See above
our $MONTH_REGEXP = qr/
	Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|
	Jul|July|Aug|August|Sep|September|Oct|October|Nov|November|Dec|December
/ix;

###############################################################################
###############################################################################
###############################################################################

=head1 NAME

Date::Parse::Modern - Provide string to unixtime conversions

=head1 DESCRIPTION

C<Date::Parse::Modern> provides a single function C<strtotime()> which takes a datetime string
and returns a unixtime.  Care was given to support the most modern style strings that you would
commonly find in log files or on the internet.

=head1 USAGE

  use Date::Parse::Modern;

C<Date::Parse::Modern> exports the C<strtotime()> function automatically.

=head1 FUNCTIONS

=head2 strtotime($string)

  my $unixtime = strtotime('1979-02-24'); # 288691200

Simply feed C<strtotime()> a string with some type of date or time in it, and it will return an
integer unixtime. If the string is unparseable, or a weird error occurs, it will return C<undef>.

All the "magic" in C<strtotime()> is done using regular expressions that look for common datetime
formats. Common formats like YYYY-MM-DD and HH:II:SS are easily detected and converted to the
appropriate formats. This allows the date or time to be found anywhere in the string, in (almost) any
order. If you limit your string to only the date/time portion the parsing will
be much quicker. Shorter input equals faster parsing.

B<Note:> Strings without a year are assumed to be in the current year. Example: C<May 15th, 10:15am>

B<Note:> Strings with only a date are assumed to occur at midnight. Example: C<2023-01-15>

B<Note:> Strings with only time are assumed to be the current day. Example: C<10:15am>

B<Note:> In strings with numeric B<and> textual time zone offsets, the numeric is used. Example:
C<14 Nov 1994 11:34:32 -0500 (EST)>

B<Note:> In all cases, the day of the week is ignored in the input string. Example: C<Mon Mar 25 2024>

=head1 Will you support XYZ format?

Everyone has their B<favorite> date/time format, and we'd like to support as many
as possible. We have tried to support as much of
L<ISO 8601|https://en.wikipedia.org/wiki/ISO_8601> as possible, but we
cannot support everything. Every new format we support runs the risk of slowing
down things for existing formats. You can submit a feature request on Github
for new formats but we may reject them if adding support would slow down others.

=head1 Bugs/Features

Please submit bugs and feature requests on Github:

  https://github.com/scottchiefbaker/perl-Date-Parse-Modern

=head1 AUTHORS

Scott Baker - https://www.perturb.org/

=cut

###############################################################################
###############################################################################
###############################################################################

# The logic here is that we use regular expressions to pull out various patterns
# YYYY/MM/DD, H:I:S, DD MonthWord YYYY
sub strtotime {
	my ($str, $debug) = @_;

	if (!defined($str)) {
		return undef;
	}

	my ($year, $month, $day)      = (0, 0, 0);
	my ($hour, $min  , $sec, $ms) = (0, 0, 0, 0);

	###########################################################################
	###########################################################################

	state $rule_1 = qr/
		\b
		((\d{4})$sep(\d{1,2})$sep(\d{1,2}) # YYYY-MM-DD
		|
		(\d{1,2})$sep(\d{1,2})$sep(\d{4})) # DD-MM-YYYY
	/x;

	# First we look to see if we have anything that mathches YYYY-MM-DD (numerically)
	if ($str =~ $rule_1) {
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

	###########################################################################

	state $rule_2 = qr/
		(\d{1,2})?            # Maybe some digits before month
		\s*
		($MONTH_REGEXP)       # A textual month
		\s+
		(\d{1,4})             # Digits
		[\s\$]                # Whitespace OR end of line
		((\d{2}|\d{4})[ \$])? # If there are two or four digits ater it's a year
	/x;

	# Next we look for alpha months followed by a digit if we didn't find a numeric month above
	# This will find: "April 13" and also "13 April 1995"
	if (!$month && $str =~ $rule_2) {

		# Get the numerical number for this month
		my $month_name = lc(substr($2,0,3));
		$month = $MONTH_MAP->{$month_name};

		# 17 March 94
		if ($1) {
			$day  = int($1);
			$year = int($3);
		# April 13 or April 13 94
		} else {
			$day = int($3);

			# *IF* we still don't have a year
			if (!$year) {
				my $part = $5 || 0;
				$year    = int($part)
			}
		}
	}

	###########################################################################

	# Alternate date string like like: 21/dec/93 or dec/21/93 much less common
	if (!$month && $str =~ /(.*)($MONTH_REGEXP)(.*)/) {
		my $before = $1;
		my $after  = $3;

		# Lookup the numeric month based on the string name
		$month = $MONTH_MAP->{lc($2)} || 0;

		# Month starts string: dec/21/93 or feb/14/1999
		if ($before eq "") {
			if ($after =~ m/(\d{2})$sep(\d{2,4})/) {
				$day  = $1;
				$year = $2;
			}
		# Month in the middle: 21/dec/93
		} elsif ($before && $after) {
			$before =~ m/(\d+)\D/; # Just the digits
			$day    = $1 || 0;

			$after  =~ m/\D(\d{2,4})(.)/; # Get the digits AFTER the separator

			# If it's not a time (has a colon) it's the year
			if ($2 ne ":") {
				$year = $1;
			}
		}
	}

	# The year may be on the end of the string: Sat May  8 21:24:31 2021
	if (!$year) {
		($year) = $str =~ m/\b(\d{4})\b/;
	}

	# Match 1st, 2nd, 3rd, 29th
	if (!$day && $str =~ m/\b(\d{1,2})(st|nd|rd|th)/) {
		$day = $1;
	}

	###########################################################################

	state $rule_3 = qr/
		(\b|T)             # Anchor point
		(\d{1,2}):         # Hours
		(\d{1,2}):?        # Minutes
		(\d{2}(Z|\.\d+)?)? # Seconds (optional)
		\ ?(am|pm|AM|PM)?  # AMPM (optional)
	/x;

	# Now we look for times: 10:14, 10:14:17, 08:15pm
	if ($str =~ $rule_3) {
		$hour = int($2);
		$min  = int($3);
		$sec  = $4 || 0; # Not int() cuz it might be float for milliseconds
		$sec  =~ s/Z$//; # Remove and Z at the end

		# The string of AM or PM
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

	# Just some basic sanity checking
	my $has_time = ($hour || $min   || $sec);
	my $has_date = ($year || $month || $day);

	if (!$has_time && !$has_date) {
		# One final check if NOTHING else has matched, we lookup a weird format: 20020722T100000Z
		if ($str =~ m/(\d{4})(\d{2})(\d{2})T(\d\d)(\d\d)(\d\d)Z/) {
			$year  = $1;
			$month = $2;
			$day   = $3;

			$hour = $4;
			$min  = $5;
			$sec  = $6;
		} else {
			return undef;
		}
	}

	###########################################################################
	###########################################################################

	# If there is no month, we assume the current month
	if (!$month) {
		$month = (localtime())[4] + 1;
	}

	# If there is no day, we assume the current day
	if (!$day) {
		$day = (localtime())[3];
	}

	# If we STILL don't have a year it may be a time only string so we assume it's the current year
	if (!$year) {
		$year = (localtime())[5] + 1900;
	}

	# Convert any two digit years to four digits
	if ($year < 100) {
		$year += 1900;
	}

	# Time::Local doesn't support fractional seconds, so we make an int version
	# and then add the ms after the timegm_modern() conversion
	$ms  = $sec - int($sec);
	$sec = int($sec);

	# If we have all the requisite pieces we build a unixtime
	my $ret;
	my $ok = eval {
		$ret = Time::Local::timegm_modern($sec, $min, $hour, $day, $month - 1, $year);

		return 1;
	};
	# This has to be *immediately* after the eval or something else might
	# tromp on the error message
	my $err = $@;

	if ($err && $err =~ /Undefined subroutine/) {
		print STDERR $err;
		return undef;
	};

	$ret += $ms;

	# If we find a timezone offset we take that in to account now
	# Either: +1000 or -0700
	# or
	# 11:53 PST (One to four chars after a time)
	my $tz_offset_seconds = 0;
	my $tz_str            = '';
	state $tz_rule        = qr/
		(
		(\s|:\d\d)             # Start AFTER a space, or time (:12)
		([+-])(\d{1,2})(\d{2}) # +1000 or -700 (three or four digits)
		|
		\d{2}\                 # Only match chars if they're AFTER a time
		([A-Z]{1,4})\b         # Capitalized TZ at end of string
		|
		\d{2}(Z)$              # Just a simple Z at the end
		)
	/x;

	# If we have a string with a timezone piece
	if ($ret && $str =~ $tz_rule) {
		my $str_offset = 0;

		# String timezone: 11:53 PST
		if ($6 || $7)  {
			# Whichever form matches, the TZ is that one
			my $tz_code = $6 || $7 || '';

			# Lookup the timezone offset in the table
			$str_offset  = $TZ_OFFSET->{$tz_code} || 0;
			# Timezone offsets are in hours, so we convert to seconds
			$str_offset *= 3600;

			$tz_str = $tz_code;
		# Numeric format: +1000 or -0700
		} else {
			# Break the input string into parts so we can do math
			# +1000 = 10 hours, -0700 = 7 hours, +0430 = 4.5 hours
			$str_offset = ($4 + ($5 / 60)) * 3600;

			if ($3 eq "-") {
				$str_offset *= -1;
			}

			$tz_str = "$3$4$5";
		}

		$tz_offset_seconds = $str_offset;
	# No timezone info found so we assume the local timezone
	} elsif ($ret) {
		my $local_offset = get_local_offset($ret);

		$tz_offset_seconds = $local_offset;
		$tz_str            = 'UNSPECIFIED';
	}

	# Subtract the timezone offset from the unixtime
	$ret -= $tz_offset_seconds;

	if ($debug) {
		my $color  = "\e[38;5;45m";
		my $reset  = "\e[0m";
		my $header = sprintf("%*s = YYYY-MM-DD HH:II:SS (timezone offset)", length($str) + 2, "Input string");
		my $output = sprintf("%12s = %02d-%02d-%02d %02d:%02d:%02d (%s = %d seconds)", "'$str'", $year || -1, $month || -1, $day || -1, $hour, $min, $sec, $tz_str, $tz_offset_seconds);

		print STDERR $color . $header . $reset . "\n";
		print STDERR $output . "\n";
	}


	return $ret;
}

# Return the timezone offset for the local machine
sub get_local_offset {
	my $unixtime = $_[0];

	# If we have a forced LOCAL_TZ_OFFSET we use that (unit tests)
	if (defined($LOCAL_TZ_OFFSET)) {
		return $LOCAL_TZ_OFFSET;
	}

	# Since timezones only change on the half-hour (at most), we
	# round down the nearest half hour "bucket" and then cache
	# that result. We probably could get away with a full hour
	# here but we don't gain much performance/memory by doing that
	my $bucket_size = 1800;
	my $cache_key   = $unixtime - ($unixtime % $bucket_size);

	# Simple memoizing (improves repeated performance a LOT)
	# Note: this is even faster than `use Memoize`
	state $x = {};
	if ($USE_TZ_CACHE && $x->{$cache_key}) {
		return $x->{$cache_key};
	}

	# Get a time obj for this local timezone and UTC for the Unixtime
	# Then compare the two to get the local TZ offset
	my @t   = localtime($unixtime);
	my $ret = (Time::Local::timegm(@t) - Time::Local::timelocal(@t));

	# Cache the result
	if ($USE_TZ_CACHE) {
		$x->{$cache_key} = $ret;
	}

	return $ret;
}

1;

__END__

Performance varies depending on string input

Running the entire test suite through both this module and
Date::Parse::str2time() via --bench gets the following output:

$ perl -I lib compare.pl --bench
Comparing 24 strings
                      Rate         Date::Parse Date::Parse::Modern
Date::Parse         1590/s                  --                -57%
Date::Parse::Modern 3663/s                130%                  --

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
