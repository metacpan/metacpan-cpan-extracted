package Database::BI::Util;

use strict;
use warnings;

our $VERSION = '0.020.0';

use Exporter qw(import);
use Readonly;

our @EXPORT_OK = qw( urlencode parse_number );

# A list rather than any three capitals, or 'SKU 100' would be read as 100.
Readonly my $CURRENCY_CODES => join '|', qw(AUD BRL CAD CHF CNY DKK EUR GBP HKD INR JPY MXN NOK NZD SEK SGD USD ZAR);
Readonly my $INFINITY       => 9**9**9;

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

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
