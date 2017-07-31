=head1 NAME

Date::ISO8601 - the three ISO 8601 numerical calendars

=head1 SYNOPSIS

    use Date::ISO8601 qw(present_y);

    print present_y($y);

    use Date::ISO8601 qw(
	month_days cjdn_to_ymd ymd_to_cjdn present_ymd);

    $md = month_days(2000, 2);
    ($y, $m, $d) = cjdn_to_ymd(2406029);
    $cjdn = ymd_to_cjdn(1875, 5, 20);
    print present_ymd(2406029);
    print present_ymd(1875, 5, 20);

    use Date::ISO8601 qw(year_days cjdn_to_yd yd_to_cjdn present_yd);

    $yd = year_days(2000);
    ($y, $d) = cjdn_to_yd(2406029);
    $cjdn = yd_to_cjdn(1875, 140);
    print present_yd(2406029);
    print present_yd(1875, 140);

    use Date::ISO8601 qw(
	year_weeks cjdn_to_ywd ywd_to_cjdn present_ywd);

    $yw = year_weeks(2000);
    ($y, $w, $d) = cjdn_to_ywd(2406029);
    $cjdn = ywd_to_cjdn(1875, 20, 4);
    print present_ywd(2406029);
    print present_ywd(1875, 20, 4);

=head1 DESCRIPTION

The international standard ISO 8601 "Data elements and interchange formats
- Information interchange - Representation of dates and times" defines
three distinct calendars by which days can be labelled.  It also defines
textual formats for the representation of dates in these calendars.
This module provides functions to convert dates between these three
calendars and Chronological Julian Day Numbers, which is a suitable
format to do arithmetic with.  It also supplies functions that describe
the shape of these calendars, to assist in calendrical calculations.
It also supplies functions to represent dates textually in the ISO
8601 formats.  ISO 8601 also covers time of day and time periods, but
this module does nothing relating to those parts of the standard; this
is only about labelling days.

The first ISO 8601 calendar divides time up into years, months, and days.
It corresponds exactly to the Gregorian calendar, invented by Aloysius
Lilius and promulgated by Pope Gregory XIII in the late sixteenth century,
with AD (CE) year numbering.  This calendar is applied to all time,
not just to dates after its invention nor just to years 1 and later.
Thus for ancient dates it is the proleptic Gregorian calendar with
astronomical year numbering.

The second ISO 8601 calendar divides time up into the same years as
the first, but divides the year directly into days, with no months.
The standard calls this "ordinal dates".  Ordinal dates are commonly
referred to as "Julian dates", a mistake apparently deriving from true
Julian Day Numbers, which divide time up solely into linearly counted
days.

The third ISO 8601 calendar divides time up into years, weeks, and days.
The years approximate the years of the first two calendars, so they stay
in step in the long term, but the boundaries differ.  This week-based
calendar is sometimes called "the ISO calendar", apparently in the belief
that ISO 8601 does not define any other.  It is also referred to as
"business dates", because it is most used by certain businesses to whom
the week is the most important temporal cycle.

The Chronological Julian Day Number is an integral number labelling each
day, where the day extends from midnight to midnight in whatever time zone
is of interest.  It is a linear count of days, where each day's number
is one greater than the previous day's number.  It is directly related to
the Julian Date system: in the time zone of the prime meridian, the CJDN
equals the JD at noon.  By way of epoch, the day on which the Convention
of the Metre was signed, which ISO 8601 defines to be 1875-05-20 (and
1875-140 and 1875-W20-4), is CJDN 2406029.

This module places no limit on the range of dates to which it may be
applied.  All function arguments are permitted to be C<Math::BigInt> or
C<Math::BigRat> objects in order to achieve arbitrary range.  Native Perl
integers are also permitted, as a convenience when the range of dates
being handled is known to be sufficiently small.

=cut

package Date::ISO8601;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.005";

use parent "Exporter";
our @EXPORT_OK = qw(
	present_y
	month_days cjdn_to_ymd ymd_to_cjdn present_ymd
	year_days cjdn_to_yd yd_to_cjdn present_yd
	year_weeks cjdn_to_ywd ywd_to_cjdn present_ywd
);

# _numify(A): turn possibly-object number into native Perl integer

sub _numify($) {
	my($a) = @_;
	return ref($a) eq "" ? $a : $a->numify;
}

# _fdiv(A, B): divide A by B, flooring remainder
#
# B must be a positive Perl integer.  A may be a Perl integer, Math::BigInt,
# or Math::BigRat.  The result has the same type as A.

sub _fdiv($$) {
	my($a, $b) = @_;
	if(ref($a) eq "Math::BigRat") {
		return ($a / $b)->bfloor;
	} else {
		if($a < 0) {
			use integer;
			return -(($b - 1 - $a) / $b);
		} else {
			use integer;
			return $a / $b;
		}
	}
}

# _fmod(A, B): A modulo B, flooring remainder
#
# B must be a positive Perl integer.  A may be a Perl integer, Math::BigInt,
# or Math::BigRat.  The result has the same type as A.

sub _fmod($$) {
	my($a, $b) = @_;
	if(ref($a) eq "Math::BigRat") {
		return $a - $b * ($a / $b)->bfloor;
	} else {
		return $a % $b;
	}
}

=head1 FUNCTIONS

Numbers in this API may be native Perl integers, C<Math::BigInt> objects,
or integer-valued C<Math::BigRat> objects.  All three types are acceptable
for all parameters, in any combination.  In all conversion functions,
the most-significant part of the result (which is the only part with
unlimited range) is of the same type as the most-significant part of
the input.  Less-significant parts of results (which have a small range)
are consistently native Perl integers.

All functions C<die> if given invalid parameters.

=head2 Years

=over

=item present_y(YEAR)

Puts the given year number into ISO 8601 textual presentation format.
For years [0, 9999] this is simply four digits.  For years outside that
range it is a sign followed by at least four digits.

This is the minimum-length presentation format.  If it is desired to
use a form that is longer than necessary, such as to use at least five
digits for all year numbers (as the Long Now Foundation does), then the
right tool is C<sprintf> (see L<perlfunc/sprintf>).

This format is unconditionally conformant to all versions of ISO 8601
for years [1583, 9999].  For years [0, 1582], preceding the historical
introduction of the Gregorian calendar, it is conformant only where
it is mutually agreed that such dates (represented in the proleptic
Gregorian calendar) are acceptable.  For years outside the range [0,
9999], where the expanded format must be used, the result is only
conformant to ISO 8601:2004 (earlier versions lacked these formats),
and only where it is mutually agreed to use this format.

=cut

sub present_y($) {
	my($y) = @_;
	my($sign, $digits) = ("$y" =~ /\A\+?(-?)0*([0-9]+?)\z/);
	$digits = ("0" x (4 - length($digits))).$digits
		unless length($digits) >= 4;
	$sign = "+" if $sign eq "" && length($digits) > 4;
	return $sign.$digits;
}

=back

=head2 Gregorian calendar

Each year is divided into twelve months, numbered [1, 12]; month number
1 is January.  Each month is divided into days, numbered sequentially
from 1.  The month lengths are irregular.  The year numbers have
unlimited range.

=over

=item month_days(YEAR, MONTH)

The parameters identify a month, and the function returns the number of
days in that month as a native Perl integer.

=cut

sub _year_leap($) {
	my($y) = @_;
	return _fmod($y, 4) == 0 &&
		(_fmod($y, 100) != 0 || _fmod($y, 400) == 0);
}

{
	my @month_length = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	sub month_days($$) {
		my($y, $m) = @_;
		croak "month number $m is out of the range [1, 12]"
			unless $m >= 1 && $m <= 12;
		if($m == 2) {
			return _year_leap($y) ? 29 : 28;
		} else {
			return $month_length[$m - 1];
		}
	}
}

{
	my @nonleap_monthstarts =
		(0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365);
	my @leap_monthstarts =
		(0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);
	sub _year_monthstarts($) {
		my($y) = @_;
		return _year_leap($y) ?
			\@leap_monthstarts : \@nonleap_monthstarts;
	}
}

=item cjdn_to_ymd(CJDN)

This function takes a Chronological Julian Day Number and returns a list
of a year, month, and day.

=cut

sub cjdn_to_yd($);

sub cjdn_to_ymd($) {
	my($cjdn) = @_;
	my($y, $d) = cjdn_to_yd($cjdn);
	my $monthstarts = _year_monthstarts($y);
	my $m = 1;
	while($d > $monthstarts->[$m]) {
		$m++;
	}
	return ($y, $m, $d - $monthstarts->[$m - 1]);
}

=item ymd_to_cjdn(YEAR, MONTH, DAY)

This performs the reverse of the translation that C<cjdn_to_ymd> does.
It takes year, month, and day numbers, and returns the corresponding CJDN.

=cut

sub yd_to_cjdn($$);

sub ymd_to_cjdn($$$) {
	my($y, $m, $d) = @_;
	croak "month number $m is out of the range [1, 12]"
		unless $m >= 1 && $m <= 12;
	$m = _numify($m);
	my $monthstarts = _year_monthstarts($y);
	my $md = $monthstarts->[$m] - $monthstarts->[$m - 1];
	croak "day number $d is out of the range [1, $md]"
		unless $d >= 1 && $d <= $md;
	$d = _numify($d);
	return yd_to_cjdn($y, $monthstarts->[$m - 1] + $d);
}

=item present_ymd(CJDN)

=item present_ymd(YEAR, MONTH, DAY)

Puts the given date into ISO 8601 Gregorian textual presentation format.
The `extended' format (with "-" separators) is used.  The conformance
notes for C<present_y> apply to this function also.

If the date is given as a (YEAR, MONTH, DAY) triplet then these are not
checked for consistency.  The MONTH and DAY values are only checked to
ensure that they fit into the fixed number of digits.  This allows the
use of this function on data other than actual Gregorian dates.

=cut

sub present_ymd($;$$) {
	my($y, $m, $d);
	if(@_ == 1) {
		($y, $m, $d) = cjdn_to_ymd($_[0]);
	} else {
		($y, $m, $d) = @_;
		croak "month number $m is out of the displayable range"
			unless $m >= 0 && $m < 100;
		croak "day number $d is out of the displayable range"
			unless $d >= 0 && $d < 100;
	}
	return sprintf("%s-%02d-%02d", present_y($y),
		_numify($m), _numify($d));
}

=back

=head2 Ordinal dates

Each year is divided into days, numbered sequentially from 1.  The year
lengths are irregular.  The years correspond exactly to those of the
Gregorian calendar.

=over

=item year_days(YEAR)

The parameter identifies a year, and the function returns the number of
days in that year as a native Perl integer.

=cut

sub year_days($) {
	my($y) = @_;
	return _year_leap($y) ? 366 : 365;
}

use constant GREGORIAN_ZERO_CJDN => 1721060;   # 0000-001

=item cjdn_to_yd(CJDN)

This function takes a Chronological Julian Day Number and returns a
list of a year and ordinal day.

=cut

sub cjdn_to_yd($) {
	my($cjdn) = @_;
	use integer;
	my $d = $cjdn - GREGORIAN_ZERO_CJDN;
	my $qcents = _fdiv($d, 365*400 + 97);
	$d = _numify($d - $qcents * (365*400 + 97));
	my $y = $d / 366;
	my $leaps = ($y + 3) / 4;
	$leaps -= ($leaps - 1) / 25 unless $leaps == 0;
	$d -= 365 * $y + $leaps;
	my $yd = year_days($y);
	if($d >= $yd) {
		$d -= $yd;
		$y++;
	}
	return ($qcents*400 + $y, 1 + $d);
}

=item yd_to_cjdn(YEAR, DAY)

This performs the reverse of the translation that C<cjdn_to_yd> does.
It takes year and ordinal day numbers, and returns the corresponding CJDN.

=cut

sub yd_to_cjdn($$) {
	my($y, $d) = @_;
	use integer;
	my $qcents = _fdiv($y, 400);
	$y = _numify($y - $qcents * 400);
	my $yd = year_days($y);
	croak "day number $d is out of the range [1, $yd]"
		unless $d >= 1 && $d <= $yd;
	$d = _numify($d);
	my $leaps = ($y + 3) / 4;
	$leaps -= ($leaps - 1) / 25 unless $leaps == 0;
	return (GREGORIAN_ZERO_CJDN + 365*$y + $leaps + ($d - 1)) +
		$qcents * (365*400 + 97);
}

=item present_yd(CJDN)

=item present_yd(YEAR, DAY)

Puts the given date into ISO 8601 ordinal textual presentation format.
The `extended' format (with "-" separators) is used.  The conformance
notes for C<present_y> apply to this function also.

If the date is given as a (YEAR, DAY) pair then these are not checked
for consistency.  The DAY value is only checked to ensure that it fits
into the fixed number of digits.  This allows the use of this function
on data other than actual ordinal dates.

=cut

sub present_yd($;$) {
	my($y, $d);
	if(@_ == 1) {
		($y, $d) = cjdn_to_yd($_[0]);
	} else {
		($y, $d) = @_;
		croak "day number $d is out of the displayable range"
			unless $d >= 0 && $d < 1000;
	}
	return sprintf("%s-%03d", present_y($y), _numify($d));
}

=back

=head2 Week-based calendar

Each year is divided into weeks, numbered sequentially from 1.  Each week
is divided into seven days, numbered [1, 7]; day number 1 is Monday.
The year lengths are irregular.  The year numbers have unlimited range.

The years correspond to those of the Gregorian calendar.  Each week is
associated with the Gregorian year that contains its Thursday and hence
contains the majority of its days.

=over

=item year_weeks(YEAR)

The parameter identifies a year, and the function returns the number of
weeks in that year as a native Perl integer.

=cut

# _year_phase(YEAR): find day of week of first day of year
#
# The argument must be a native Perl integer.  The return value is
# zero-based, in the range 0 = Monday to 6 = Sunday.

sub _year_phase($) {
	my($y) = @_;
	return yd_to_cjdn($y, 1) % 7;
}

sub year_weeks($) {
	my($y) = @_;
	$y = _numify(_fmod($y, 400));
	my $phase = _year_phase($y);
	return $phase == 3 || ($phase == 2 && _year_leap($y)) ? 53 : 52;
}

=item cjdn_to_ywd(CJDN)

This function takes a Chronological Julian Day Number and returns a list
of a year, week, and day.

=cut

sub cjdn_to_ywd($) {
	my($cjdn) = @_;
	my($y, $d) = cjdn_to_yd($cjdn);
	my $py = _numify(_fmod($y, 400));
	my $phase = _year_phase($py);
	my $start_wk1 = ($phase <= 3 ? 1 : 8) - $phase;
	my $w = _fdiv($d - $start_wk1, 7);
	if($w == -1) {
		$y--;
		$w = year_weeks($py - 1);
	} elsif($w >= year_weeks($py)) {
		$y++;
		$w = 1;
	} else {
		$w++;
	}
	return ($y, $w, ($d - $start_wk1) % 7 + 1);
}

=item ywd_to_cjdn(YEAR, WEEK, DAY)

This performs the reverse of the translation that C<cjdn_to_ywd> does.
It takes year, week, and day numbers, and returns the corresponding CJDN.

=cut

sub ywd_to_cjdn($$$) {
	my($y, $w, $d) = @_;
	my $yw = year_weeks($y);
	croak "week number $w is out of the range [1, $yw]"
		unless $w >= 1 && $w <= $yw;
	croak "day number $d is out of the range [1, 7]"
		unless $d >= 1 && $d <= 7;
	my $start_cjdn = yd_to_cjdn($y, 1);
	my $phase = _fmod($start_cjdn, 7);
	return $start_cjdn +
		(($phase <= 3 ? -8 : -1) - $phase +
			_numify($w)*7 + _numify($d));
}

=item present_ywd(CJDN)

=item present_ywd(YEAR, WEEK, DAY)

Puts the given date into ISO 8601 week-based textual presentation format.
The `extended' format (with "-" separators) is used.  The conformance
notes for C<present_y> apply to this function also.

If the date is given as a (YEAR, WEEK, DAY) triplet then these are not
checked for consistency.  The WEEK and DAY values are only checked to
ensure that they fit into the fixed number of digits.  This allows the
use of this function on data other than actual week-based dates.

=cut

sub present_ywd($;$$) {
	my($y, $w, $d);
	if(@_ == 1) {
		($y, $w, $d) = cjdn_to_ywd($_[0]);
	} else {
		($y, $w, $d) = @_;
		croak "week number $w is out of the displayable range"
			unless $w >= 0 && $w < 100;
		croak "day number $d is out of the displayable range"
			unless $d >= 0 && $d < 10;
	}
	return sprintf("%s-W%02d-%d", present_y($y), _numify($w), _numify($d));
}

=back

=head1 SEE ALSO

L<Date::JD>,
L<DateTime>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2011, 2017
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
