package Database::BI::Util;

use strict;
use warnings;

our $VERSION = '0.018.0';

use Exporter qw(import);

our @EXPORT_OK = qw( urlencode );

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
# Multi-byte characters: ord() returns the Unicode codepoint, not the
# individual UTF-8 byte values.  Column names and spec keys in this
# application are ASCII-only (enforced by TABLE_NAME_RE / $EXT_RE), so this
# is sufficient.  Do not use this function on arbitrary Unicode strings
# without first encoding to UTF-8 bytes: Encode::encode_utf8($str).
sub urlencode {
	my ($str) = @_;
	return '' unless defined $str;
	# '-' placed at end of character class to avoid ambiguity with a range.
	$str =~ s/([^A-Za-z0-9._~-])/sprintf('%%%02X', ord($1))/ge;
	return $str;
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
other bytes with C<%XX> uppercase hex escapes.

=head3 API SPECIFICATION

=head4 INPUT

	$str   # string or undef

=head4 OUTPUT

	'string'   # percent-encoded; undef gives ''

Each character outside the unreserved set is encoded from its code point, so
a character above 0xFF must be encoded to UTF-8 bytes first
(C<Encode::encode_utf8>).  The application only passes ASCII column names and
specs.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
