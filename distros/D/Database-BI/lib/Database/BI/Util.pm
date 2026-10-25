package Database::BI::Util;

use strict;
use warnings;

our $VERSION = '0.017.0';

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

=head1 FUNCTIONS

=head2 urlencode

  my $encoded = urlencode($str);

Percent-encodes a string for use as a URI query-parameter value.  Preserves
the RFC 3986 unreserved characters (C<A-Z a-z 0-9 - . _ ~>) and replaces all
other bytes with C<%XX> uppercase hex escapes.

=head1 AUTHOR

Nigel Horne

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
