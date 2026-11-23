package Database::BI::Util;

use strict;
use warnings;

our $VERSION = '0.024.0';

use Exporter qw(import);
use Readonly;
use POSIX ();
use Carp qw(croak);

our @EXPORT_OK = qw( urlencode parse_number iso_datetime minute_stamp iso8601_utc
	parse_zone zone_wall frame_epoch );

# A list rather than any three capitals, or 'SKU 100' would be read as 100.
Readonly my $CURRENCY_CODES => join '|', qw(AUD BRL CAD CHF CNY DKK EUR GBP HKD INR JPY MXN NOK NZD SEK SGD USD ZAR);
# The largest number a chart can use: a C double's, which is what the browser
# has (parseAccounting refuses what is not isFinite there).  Not perl's own
# infinity: a perl built with -Duselongdouble or -Dusequadmath holds 1e999 as
# a finite number, so comparing with infinity let it through on those perls
# alone (GitHub issue 6).
Readonly my $LARGEST_NUMBER => POSIX::DBL_MAX();

# A date, or a date and a time with T or a space between them; the time may
# carry seconds, a fraction of a second, and a zone (Z, or an offset such as
# +01:00, +0100 or +01).  The last three are what JSON APIs and exports write.
Readonly my $ISO_DATETIME_RE => qr{
	\A (\d{4}-\d{2}-\d{2})
	(?: [T ] (\d{2}) : (\d{2}) (?: : (\d{2}) (?: [.,] \d+ )? )?
		( [Zz] | [+-] \d{2} (?: :? \d{2} )? )? )?
	\z
}x;

# Premise 1: iso_datetime runs once per cell of a date filter, time range or
#            formula.
# Premise 2: reading a Readonly scalar costs several times a plain lexical's,
#            and a compiled regex is the same object either way.
# Conclusion: the hot path matches against a lexical copy; the Readonly stays
#             the one definition, so the pattern is still written once.
my $ISO_DATETIME_FAST = $ISO_DATETIME_RE;

# urlencode($str) -> $encoded
#
# Percent-encodes a string for use as a URI query-parameter value.
# Preserves only the RFC 3986 unreserved characters (letters, digits,
# hyphen, dot, underscore, tilde) and encodes everything else as %XX.
#
# Why a shared copy rather than Mojo::Util::url_escape:
#   Ask.pm and Insights.pm are plain Perl modules with no Mojo dependency;
#   pulling in Mojo::Util for a 3-line function would be an undue coupling.
#
# Multi-byte characters: a decoded string is encoded to its UTF-8 bytes first,
# because ord() returns the codepoint and U+263A would print as "%263A", which
# decodes to "&3A".  A string of bytes (the usual CSV cell) is left as it is, so
# text that is already UTF-8 is not encoded twice.
sub urlencode {
	my ($str) = @_;
	return '' unless defined $str;
	utf8::encode($str) if utf8::is_utf8($str);
	# '-' placed at end of character class to avoid ambiguity with a range.
	$str =~ s/([^A-Za-z0-9._~-])/sprintf('%%%02X', ord($1))/ge;
	return $str;
}

# Only what dresses up a number is removed: spaces, brackets, thousands
# separators, a percent sign, currency symbols and a known currency code.  Any
# other letter stays and fails the match, so 'SKU123' and 'AB-100' are text
# rather than 123 and -100.  The bracket is read before it is removed.
# The browser's parseAccounting (layouts/parse_accounting.html.tt) is a copy,
# so a table sorts the same on the server as on the page: change one, change
# the other.
sub parse_number {
	my $value = $_[0];

	return undef unless defined($value) && length($value);

	# Premise 1: the slow path below only removes spaces, brackets, commas, $, %,
	#            non-ASCII and currency codes before matching a plain decimal.
	# Premise 2: an ASCII plain decimal contains none of those.
	# Premise 3: at most 300 integer digits is below 1e300, under DBL_MAX.
	# Conclusion: such a cell reaches the same number without the substitutions
	#             or the range check (a Readonly read costs several times a
	#             lexical's); longer ones take the full path.
	return $value + 0 if $value =~ /\A-?[0-9]{1,300}(?:\.[0-9]+)?\z/;

	my $is_accounting = ($value =~ /\A\s*\(/);
	(my $text = $value) =~ s/(?:\A|(?<=[\s(]))(?:$CURRENCY_CODES)(?=[\s\d.])|(?<=[\s\d])(?:$CURRENCY_CODES)(?=[\s)]|\z)//g;
	$text =~ s/[\s(),\$%]|[^\x00-\x7F]//g;
	$text = "-$text" if $is_accounting && $text =~ /\A\d/;
	return undef unless $text =~ /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/;

	my $number = $text + 0;

	# 1e999 spells a number, but one past a double's range is infinity in the
	# browser, which is no use to a total or an axis -- on every perl.
	return undef unless abs($number) <= $LARGEST_NUMBER;
	return $number;
}

# The zone the server works in, or undef (the default: a time is as written).
# A { kind => 'fixed', offset => seconds } or { kind => 'local' } from
# parse_zone.  The app's around_dispatch hook sets it with `local` from config
# time_zone, so it is the one setting every reader of a time sees.
our $ZONE;

# parse_zone($spec) -> \%zone | undef
#
# 'UTC' (or 'Z', 'GMT'), 'local' (the server's own zone, daylight saving
# included), or a fixed offset: +05:30, -0800, +01.  undef and '' are no zone.
# Anything else croaks, so a typo in the configuration stops the start.
sub parse_zone {
	my ($spec) = @_;
	return undef unless defined $spec && length $spec;
	croak "time_zone: '" . (ref $spec || $spec) . "' is not UTC, local, or an offset such as +05:30"
		if ref $spec;
	return { kind => 'fixed', offset => 0 } if $spec =~ /\A(?:utc|gmt|z)\z/i;
	return { kind => 'local' }             if $spec =~ /\Alocal\z/i;
	if (my ($sign, $hh, $mm) = $spec =~ /\A([+-])([0-9]{2})(?::?([0-9]{2}))?\z/) {
		croak "time_zone: '$spec' is not UTC, local, or an offset such as +05:30"
			unless $hh <= 14 && ($mm // 0) <= 59;
		my $secs = $hh * 3_600 + ($mm // 0) * 60;
		return { kind => 'fixed', offset => $sign eq '-' ? -$secs : $secs };
	}
	croak "time_zone: '$spec' is not UTC, local, or an offset such as +05:30";
}

# zone_wall($epoch) -> (sec, min, hour, mday, mon, year, wday, yday, isdst)
#
# What localtime gives, but in the configured zone: the clock on the wall
# there at that moment.  With no zone it is localtime.
sub zone_wall {
	my ($epoch) = @_;
	local $!;	# localtime's tzset may leave errno set; see Calc::_epoch_of
	return ($ZONE && $ZONE->{kind} eq 'fixed')
		? gmtime($epoch + $ZONE->{offset})
		: localtime($epoch);
}

# frame_epoch($epoch) -> $epoch'
#
# The date code (Calc, the time range) reads a clock with localtime and builds
# one with mktime, so it lives in the server's zone.  For a time read in
# another zone this gives the epoch whose localtime shows that zone's wall
# clock; with no zone, or the server's own, it is $epoch.
sub frame_epoch {
	my ($epoch) = @_;
	return $epoch unless $ZONE && $ZONE->{kind} eq 'fixed';
	my @wall = zone_wall($epoch);
	local $!;
	return POSIX::mktime(@wall[0 .. 5]) // $epoch;
}

# _days_from_civil($y, $m, $d) -> days since 1970-01-01 (proleptic Gregorian)
sub _days_from_civil {
	my ($y, $m, $d) = @_;
	$y -= $m <= 2 ? 1 : 0;
	my $era = int(($y >= 0 ? $y : $y - 399) / 400);
	my $yoe = $y - $era * 400;
	my $doy = int((153 * ($m + ($m > 2 ? -3 : 9)) + 2) / 5) + $d - 1;
	my $doe = $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy;
	return $era * 146_097 + $doe - 719_468;
}

# _in_zone($day, $hour, $minute, $second, $zone_text) -> ($day, $h, $m, $s)
#
# Premise 1: a value that names a zone names one moment.
# Premise 2: a configured zone is the clock the reader works to.
# Conclusion: the written time is moved to that zone's clock, and the day may
#             change with it.  A date or time that cannot exist (a 31st of
#             February, hour 25) is left as written: the callers that need a
#             real one refuse it, and arithmetic would make it another day.
sub _in_zone {
	my ($day, $hour, $minute, $second, $zone_text) = @_;
	my ($y, $mon, $dom) = split /-/, $day;
	my @dim = (31, (($y % 4 == 0 && $y % 100 != 0) || $y % 400 == 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return ($day, $hour, $minute, $second)
		unless $mon >= 1 && $mon <= 12 && $dom >= 1 && $dom <= $dim[$mon - 1]
			&& $hour <= 23 && $minute <= 59 && ($second // 0) <= 59;

	my $from = 0;
	if ($zone_text =~ /\A([+-])([0-9]{2}):?([0-9]{2})?\z/) {
		$from = ($2 * 3_600 + ($3 // 0) * 60) * ($1 eq '-' ? -1 : 1);
	}
	my $epoch = _days_from_civil($y + 0, $mon + 0, $dom + 0) * 86_400
		+ $hour * 3_600 + $minute * 60 + ($second // 0) - $from;
	my @wall = zone_wall($epoch);
	return (
		sprintf('%04d-%02d-%02d', $wall[5] + 1900, $wall[4] + 1, $wall[3]),
		sprintf('%02d', $wall[2]),
		sprintf('%02d', $wall[1]),
		defined $second ? sprintf('%02d', $wall[0]) : undef,
	);
}

# iso_datetime($value) -> ($day, $hour, $minute, $second) | ()
#
# The one reading of an ISO date or timestamp, for the filters, the time range
# and the formulas alike.  A fraction of a second is set aside.  A time that
# names a zone (Z, +01:00) is moved to the configured zone ($ZONE, config
# time_zone) when there is one, so 2026-11-06T23:30:00Z is 18:30 on the 6th
# for -05:00; with no zone configured, or a time with none written, the time
# is taken as written and the value is the day the table shows.
sub iso_datetime {
	my ($value) = @_;
	return () unless defined $value && !ref $value;
	my ($day, $hour, $minute, $second, $zone) = $value =~ $ISO_DATETIME_FAST or return ();
	return ($day, $hour, $minute, $second) unless defined $zone && $ZONE;
	return _in_zone($day, $hour, $minute, $second, $zone =~ /\A[Zz]\z/ ? '+00:00' : $zone);
}

# minute_stamp(@tm) -> 'YYYY-MM-DD HH:MM'
# iso8601_utc($epoch) -> 'YYYY-MM-DDTHH:MM:SSZ'
#
# Written with sprintf rather than POSIX::strftime: on Windows, perl 5.38's
# strftime did not return (CI sat in t/function.t until the job's limit),
# and these fixed formats need nothing from the C library.
sub minute_stamp {
	my @tm = @_;
	return '' unless @tm >= 6;
	return sprintf '%04d-%02d-%02d %02d:%02d', $tm[5] + 1900, $tm[4] + 1, $tm[3], $tm[2], $tm[1];
}

sub iso8601_utc {
	my ($epoch) = @_;
	my @tm = gmtime(defined $epoch ? $epoch : time);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ', $tm[5] + 1900, $tm[4] + 1, $tm[3], $tm[2], $tm[1], $tm[0];
}

1;

__END__

=head1 NAME

Database::BI::Util - Shared utility functions for Database::BI modules

=head1 SYNOPSIS

  use Database::BI::Util qw(urlencode);
  my $safe = urlencode($query_param_value);

=head1 DESCRIPTION

Small helpers shared by the plain-Perl modules (L<Database::BI::Ask>,
L<Database::BI::Insights>) that build URLs without depending on Mojolicious.
Nothing is exported by default.

=head1 FUNCTIONS

=head2 urlencode

  my $encoded = urlencode($str);

Percent-encodes a string for use as a URI query-parameter value.  Preserves
the RFC 3986 unreserved characters (C<A-Z a-z 0-9 - . _ ~>) and replaces all
other bytes with C<%XX> uppercase hex escapes.  A decoded string is encoded as
UTF-8 first; a string of bytes is taken as it stands.

=head3 API SPECIFICATION

=head4 INPUT

	$str   # string or undef

=head4 OUTPUT

	'string'   # percent-encoded; undef gives ''

Each character outside the unreserved set is encoded from its code point, so
a character above 0xFF must be encoded to UTF-8 bytes first
(C<Encode::encode_utf8>).  The application only passes ASCII column names and
specs.

=head2 parse_number

Read a table cell as a number, or say it is not one.

    parse_number('$1,234.56');    # 1234.56
    parse_number('(1,234.56)');   # -1234.56
    parse_number('USD 100');      # 100
    parse_number('SKU123');       # undef

=head3 API SPECIFICATION

=head4 INPUT

    $value: string, optional

  Domains:
    ASCII plain decimal, up to 300 integer digits   a number (the fast path)
    the same with commas, spaces, brackets, $, %,
      a known currency code, or any non-ASCII symbol
      (a euro sign, a right-to-left mark)            the number, symbols removed
    brackets round the number                        negative
    more than 300 digits, or an exponent             a number while its size is at
                                                     most POSIX::DBL_MAX, else undef
    any other letter, a second point, or no digit    undef (SKU123, 1.2.3, "Gr\x{F6}\x{DF}e")
    non-ASCII digits (Arabic-Indic, fullwidth)       undef: only 0-9 are digits

=head4 OUTPUT

A number, or C<undef> if the value is missing, empty, holds anything other
than a number and its currency or thousands formatting, or lies beyond the
range of a C double (C<POSIX::DBL_MAX>, about 1.8e308) -- the browser's
numbers -- whatever kind of number this perl was built with.

=head2 iso_datetime

Read an ISO 8601 date or timestamp.

    iso_datetime('2026-11-06');                  # ('2026-11-06', undef, undef, undef)
    iso_datetime('2026-11-06 09:15');            # ('2026-11-06', '09', '15', undef)
    iso_datetime('2026-11-06T23:30:00.250Z');    # ('2026-11-06', '23', '30', '00')
    iso_datetime('2026-11-06T23:30:00+01:00');   # ('2026-11-06', '23', '30', '00')
    iso_datetime('06/11/2026');                  # ()

A fraction of a second is accepted and set aside.  A zone (C<Z>, C<+01:00>,
C<+0100>, C<+01>) is applied only when a C<time_zone> is configured
(C<$Database::BI::Util::ZONE>, see L</parse_zone>): the time is then moved to
that zone's clock, and the day moves with it, so C<2026-11-06T23:30:00Z> is
C<2026-11-06 18:30> for C<-05:00>.  With no zone configured, or a value that
names none, the time is the one written.  The month and day are not checked
against a calendar, and a date or time that cannot exist is never moved; the
callers that need a real day check it themselves.

=head2 parse_zone

Read the C<time_zone> setting.

    parse_zone('UTC');      # { kind => 'fixed', offset => 0 }
    parse_zone('+05:30');   # { kind => 'fixed', offset => 19800 }
    parse_zone('local');    # { kind => 'local' }
    parse_zone(undef);      # undef: no zone, times are as written

Croaks, C<time_zone: 'x' is not UTC, local, or an offset such as +05:30>, for
anything else.

=head2 zone_wall

C<localtime>, in the configured zone: C<zone_wall($epoch)> returns the nine
values for the clock on the wall there.

=head2 frame_epoch

The epoch whose C<localtime> shows the configured zone's clock, so date code
that reads C<localtime> and builds with C<mktime> works in the configured zone.
It is its argument when there is no zone, or the zone is C<local>.

=head3 API SPECIFICATION

=head4 INPUT

    $value: string, optional

=head4 OUTPUT

A list: the day (C<YYYY-MM-DD>), then the hour, minute and second as written
(two digits each, C<undef> when absent), or the empty list when the value is
not an ISO date or timestamp.

=head2 minute_stamp

A time to the minute, from the list C<localtime> or C<gmtime> gives.

    minute_stamp(localtime $mtime);   # '2026-11-07 14:05'
    minute_stamp(gmtime $mtime) . ' UTC';

It is C<POSIX::strftime('%Y-%m-%d %H:%M', ...)> written out: on Windows,
perl 5.38's C<strftime> did not return.

=head3 API SPECIFICATION

=head4 INPUT

    @tm: the list from localtime or gmtime (at least six values)

=head4 OUTPUT

A string, C<YYYY-MM-DD HH:MM>; the empty string when fewer than six values
are given.

=head2 iso8601_utc

A moment as ISO 8601 in UTC, to the second.

    iso8601_utc();             # now, '2026-11-07T14:05:09Z'
    iso8601_utc(0);            # '1970-01-01T00:00:00Z'

=head3 API SPECIFICATION

=head4 INPUT

    $epoch: integer, optional (default: now)

=head4 OUTPUT

A string, C<YYYY-MM-DDTHH:MM:SSZ>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
