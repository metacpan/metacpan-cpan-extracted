package Database::BI::Util;

use strict;
use warnings;

our $VERSION = '0.021.0';

use Exporter qw(import);
use Readonly;

our @EXPORT_OK = qw( urlencode parse_number iso_datetime minute_stamp iso8601_utc );

# A list rather than any three capitals, or 'SKU 100' would be read as 100.
Readonly my $CURRENCY_CODES => join '|', qw(AUD BRL CAD CHF CNY DKK EUR GBP HKD INR JPY MXN NOK NZD SEK SGD USD ZAR);
Readonly my $INFINITY       => 9**9**9;

# A date, or a date and a time with T or a space between them; the time may
# carry seconds, a fraction of a second, and a zone (Z, or an offset such as
# +01:00, +0100 or +01).  The last three are what JSON APIs and exports write.
Readonly my $ISO_DATETIME_RE => qr{
	\A (\d{4}-\d{2}-\d{2})
	(?: [T ] (\d{2}) : (\d{2}) (?: : (\d{2}) (?: [.,] \d+ )? )?
		(?: [Zz] | [+-] \d{2} (?: :? \d{2} )? )? )?
	\z
}x;

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
sub parse_number {
	my $value = $_[0];

	return undef unless defined($value) && length($value);

	my $is_accounting = ($value =~ /\A\s*\(/);
	(my $text = $value) =~ s/(?:\A|(?<=[\s(]))(?:$CURRENCY_CODES)(?=[\s\d.])|(?<=[\s\d])(?:$CURRENCY_CODES)(?=[\s)]|\z)//g;
	$text =~ s/[\s(),\$%]|[^\x00-\x7F]//g;
	$text = "-$text" if $is_accounting && $text =~ /\A\d/;
	return undef unless $text =~ /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/;

	my $number = $text + 0;

	# 1e999 spells a number, but infinity is no use to a total or an axis.
	return undef if abs($number) == $INFINITY;
	return $number;
}

# iso_datetime($value) -> ($day, $hour, $minute, $second) | ()
#
# The one reading of an ISO date or timestamp, for the filters, the time range
# and the formulas alike.  A time is taken as written: a fraction of a second
# and a zone are accepted and set aside, so 2026-11-06T23:30:00Z is 23:30 on
# the 6th, the day the table shows, for every reader.
sub iso_datetime {
	my ($value) = @_;
	return () unless defined $value && !ref $value;
	my ($day, $hour, $minute, $second) = $value =~ $ISO_DATETIME_RE or return ();
	return ($day, $hour, $minute, $second);
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

=head4 OUTPUT

A number, or C<undef> if the value is missing, empty, holds anything other
than a number and its currency or thousands formatting, or is too large to be
finite.

=head2 iso_datetime

Read an ISO 8601 date or timestamp.

    iso_datetime('2026-11-06');                  # ('2026-11-06', undef, undef, undef)
    iso_datetime('2026-11-06 09:15');            # ('2026-11-06', '09', '15', undef)
    iso_datetime('2026-11-06T23:30:00.250Z');    # ('2026-11-06', '23', '30', '00')
    iso_datetime('2026-11-06T23:30:00+01:00');   # ('2026-11-06', '23', '30', '00')
    iso_datetime('06/11/2026');                  # ()

The time is the one written in the value: a fraction of a second and a zone
(C<Z>, C<+01:00>, C<+0100>, C<+01>) are accepted and not applied, so a
timestamp falls on the day it names, the one the table shows.  The month and
day are not checked against a calendar; the callers that need a real day check
it themselves.

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
