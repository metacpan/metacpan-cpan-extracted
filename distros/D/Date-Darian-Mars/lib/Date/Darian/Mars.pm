=head1 NAME

Date::Darian::Mars - the Darian calendar for Mars

=head1 SYNOPSIS

	use Date::Darian::Mars qw(present_y);

	print present_y($y);

	use Date::Darian::Mars
		qw(month_days cmsdn_to_ymd ymd_to_cmsdn present_ymd);

	$md = month_days(209, 23);
	($y, $m, $d) = cmsdn_to_ymd(546236);
	$cmsdn = ymd_to_cmsdn(209, 23, 18);
	print present_ymd(546236);
	print present_ymd(209, 23, 18);

	use Date::Darian::Mars
		qw(year_days cmsdn_to_yd yd_to_cmsdn present_yd);

	$yd = year_days(209);
	($y, $d) = cmsdn_to_yd(546236);
	$cmsdn = yd_to_cmsdn(209, 631);
	print present_yd(546236);
	print present_yd(209, 631);

=head1 DESCRIPTION

The Darian calendar for Mars is a mechanism by which Martian solar days
(also known as "sols") can be labelled in a manner useful to inhabitants
of Mars.  This module provides functions to convert dates between the
Darian calendar and Chronological Mars Solar Day Numbers, which is a
suitable format to do arithmetic with.  It also supplies functions that
describe the shape of the Darian calendar, to assist in calendrical
calculations.  It also supplies functions to represent Darian dates
textually in a conventional format.

The Darian calendar divides time up into years, months, and days.
This module also supports dividing the Darian year directly into days,
with no months.

The Chronological Mars Solar Day Number is an integral number labelling
each Martian day, where the day extends from midnight to midnight in
whatever time zone is of interest.  It is a linear count of days, where
each day's number is one greater than the previous day's number.

This module places no limit on the range of dates to which it may be
applied.  All function arguments are permitted to be C<Math::BigInt> or
C<Math::BigRat> objects in order to achieve arbitrary range.  Native Perl
integers are also permitted, as a convenience when the range of dates
being handled is known to be sufficiently small.

=head1 DARIAN CALENDAR FOR MARS

The main cycle in the Darian calendar is the year.  It approximates the
length of a Martian tropical year (specifically, the northward equinoctal
year), and the year starts approximately on the northward equinox.
Years are either 668 or 669 Martian solar days long.  669-day years are
referred to as "leap years".

Each year is divided into 24 months, of nearly equal length.  The months
are purely nominal: they do not correspond to any astronomical cycle.
Each quarter of the year consists of five months of 28 days followed by
one month of 27 days, except that the last month of a leap year contains
28 days instead of 27.

All odd-numbered years are leap years.  Even-numbered years are not leap
years, except for years divisible by ten which are leap years, except
for years divisible by 100 which are not, except for years divisible by
500 which are.

Days within each month are numbered sequentially, starting at 1.
The months have names (in fact several competing sets of names), but this
module does not deal with the names.  In this module, months within each
year are numbered sequentially from 1.

Years are numbered sequentially.  Year 0 is the year in which the first
known telescopic observations of Mars occurred.  Specifically, year 0
started at the midnight that occurred on the Airy meridian (the Martian
prime meridian) at approximately MJD -91195.22 in Terrestrial Time.

The calendar is described canonically, and in more detail, at
L<http://pweb.jps.net/~tgangale/mars/converter/calendar_clock.htm>.

The day when Mars Exploration Rover "Opportunity" landed in Meridiani
Planum was 0209-23-18 or 0209-631 in the Darian calendar, and CMSDN
546236.

=cut

package Date::Darian::Mars;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(
	present_y
	month_days cmsdn_to_ymd ymd_to_cmsdn present_ymd
	year_days cmsdn_to_yd yd_to_cmsdn present_yd
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

Puts the given year number into the conventional textual presentation
format.  For years [0, 9999] this is simply four digits.  For years
outside that range it is a sign followed by at least four digits.

This is the minimum-length presentation format.  If it is desired
to use a form that is longer than necessary, such as to use at least
five digits for all year numbers, then the right tool is C<sprintf>
(see L<perlfunc/sprintf>).

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

=head2 Darian calendar

Each year is divided into 24 months, numbered [1, 24].  Each month is
divided into days, numbered sequentially from 1.  The month lengths
are irregular.  The year numbers have unlimited range.

=over

=item month_days(YEAR, MONTH)

The parameters identify a month, and the function returns the number of
days in that month as a native Perl integer.

=cut

sub _year_leap($) {
	my($y) = @_;
	return _fmod($y, 2) == 1 ||
		(_fmod($y, 10) == 0 &&
			(_fmod($y, 100) != 0 || _fmod($y, 500) == 0));
}

{
	sub month_days($$) {
		my($y, $m) = @_;
		croak "month number $m is out of the range [1, 24]"
			unless $m >= 1 && $m <= 24;
		if($m == 24) {
			return _year_leap($y) ? 28 : 27;
		} else {
			return _fmod($m, 6) == 0 ? 27 : 28;
		}
	}
}

=item cmsdn_to_ymd(CMSDN)

This function takes a Chronological Mars Solar Day Number and returns
a list of a year, month, and day.

=cut

sub cmsdn_to_yd($);

sub cmsdn_to_ymd($) {
	my($cmsdn) = @_;
	my($y, $d) = cmsdn_to_yd($cmsdn);
	return ($y, 24, 28) if $d == 669;
	$d--;
	my $sixm = _fdiv($d, 28*6 - 1);
	$d -= $sixm * (28*6 - 1);
	my $m = _fdiv($d, 28);
	return ($y, 1 + 6*$sixm + $m, 1 + _fmod($d, 28));
}

=item ymd_to_cmsdn(YEAR, MONTH, DAY)

This performs the reverse of the translation that C<cmsdn_to_ymd> does.
It takes year, month, and day numbers, and returns the corresponding
CMSDN.

=cut

sub yd_to_cmsdn($$);

sub ymd_to_cmsdn($$$) {
	my($y, $m, $d) = @_;
	croak "month number $m is out of the range [1, 24]"
		unless $m >= 1 && $m <= 24;
	$m = _numify($m);
	my $md = month_days($y, $m);
	croak "day number $d is out of the range [1, $md]"
		unless $d >= 1 && $d <= $md;
	return yd_to_cmsdn($y, ($m - 1) * 28 - _fdiv($m - 1, 6) + _numify($d));
}

=item present_ymd(CMSDN)

=item present_ymd(YEAR, MONTH, DAY)

Puts the given date into conventional Darian textual presentation format.

If the date is given as a (YEAR, MONTH, DAY) triplet then these are not
checked for consistency.  The MONTH and DAY values are only checked to
ensure that they fit into the fixed number of digits.  This allows the
use of this function on data other than actual Darian dates.

=cut

sub present_ymd($;$$) {
	my($y, $m, $d);
	if(@_ == 1) {
		($y, $m, $d) = cmsdn_to_ymd($_[0]);
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
Darian calendar.

=over

=item year_days(YEAR)

The parameter identifies a year, and the function returns the number of
days in that year as a native Perl integer.

=cut

sub year_days($) {
	my($y) = @_;
	return _year_leap($y) ? 669 : 668;
}

use constant DARIAN_ZERO_CMSDN => 405871;   # 0000-001

=item cmsdn_to_yd(CMSDN)

This function takes a Chronological Mars Solar Day Number and returns
a list of a year and ordinal day.

=cut

sub cmsdn_to_yd($) {
	my($cmsdn) = @_;
	use integer;
	my $d = $cmsdn - DARIAN_ZERO_CMSDN;
	my $qcents = _fdiv($d, 668*500 + 296);
	$d = _numify($d - $qcents * (668*500 + 296));
	my $y = $d / 669;
	my $leaps = ($y / 2) + ($y+9) / 10 - ($y+99) / 100 + ($y == 0 ? 0 : 1);
	$d -= 668 * $y + $leaps;
	my $yd = year_days($y);
	if($d >= $yd) {
		$d -= $yd;
		$y++;
	}
	return ($qcents*500 + $y, 1 + $d);
}

=item yd_to_cmsdn(YEAR, DAY)

This performs the reverse of the translation that C<cmsdn_to_yd> does.
It takes year and ordinal day numbers, and returns the corresponding
CMSDN.

=cut

sub yd_to_cmsdn($$) {
	my($y, $d) = @_;
	use integer;
	my $qcents = _fdiv($y, 500);
	$y = _numify($y - $qcents * 500);
	my $yd = year_days($y);
	croak "day number $d is out of the range [1, $yd]"
		unless $d >= 1 && $d <= $yd;
	$d = _numify($d);
	my $leaps = ($y / 2) + ($y+9) / 10 - ($y+99) / 100 + ($y == 0 ? 0 : 1);
	return (DARIAN_ZERO_CMSDN + 668*$y + $leaps + ($d - 1)) +
		$qcents * (668*500 + 296);
}

=item present_yd(CMSDN)

=item present_yd(YEAR, DAY)

Puts the given date into the conventional ordinal textual presentation
format.

If the date is given as a (YEAR, DAY) pair then these are not checked
for consistency.  The DAY value is only checked to ensure that it fits
into the fixed number of digits.  This allows the use of this function
on data other than actual ordinal dates.

=cut

sub present_yd($;$) {
	my($y, $d);
	if(@_ == 1) {
		($y, $d) = cmsdn_to_yd($_[0]);
	} else {
		($y, $d) = @_;
		croak "day number $d is out of the displayable range"
			unless $d >= 0 && $d < 1000;
	}
	return sprintf("%s-%03d", present_y($y), _numify($d));
}

=back

=head1 SEE ALSO

L<Date::MSD>,
L<http://pweb.jps.net/~tgangale/mars/converter/calendar_clock.htm>,
L<http://www.fysh.org/~zefram/time/define_cmsd.txt>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2009, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
