package CSS::DOM::Util;

$VERSION = '0.16';

use strict; use warnings; no warnings qw 'utf8 parenthesis';

use Exporter 5.57 'import';
our @EXPORT_OK = qw '
	unescape     escape
	             escape_ident
	unescape_url
	unescape_str escape_str';
our %EXPORT_TAGS = (all=>\@EXPORT_OK);


sub escape($$) {
	my $str = shift;
	my $hex_or_space = qr/[0-9a-fA-F]|(?!$_[0])[ \t]/;
	$str =~ s/([\n\r\f]|$_[0])/
		my $c = $1;
		$c =~ m'[ -\/:-@[-`{-~]'
		?  "\\$c"
		:  sprintf '\%x' . ' ' x (
		       ord $c < 0x100000 &&
		       (substr $str, $+[0], 1,||'a') =~ $hex_or_space
		   ), ord $c
	/ge;
	$str;
}

sub unescape($) {
	my $val = shift;
	$val =~ s/\\(?:
		([a-fA-F0-9]{1,6})(?:\r\n|[ \n\r\t\f])?
		  |
		([^\n\r\f0-9a-f])
		  |
		(\r\n?|[\n\f])
	)/
		defined $1 ? chr hex $1 :
		defined $2 ? $2 :
		             ''
	/gex;
	$val;
}

sub escape_ident($) {
	my $str = shift;

	# An identifier can’t have [0-9] for the first character, or for
	# the second if
	# the first is [-].
	return escape $str,
		qr/([\0-,.\/:-\@[-^`{-\177]|^[0-9]|(?<=^-)[0-9])/;
}

sub unescape_url($) {
	my $token = shift;
	$token =~ s/^url\([ \t\r\n\f]*//;
	$token =~ s/[ \t\r\n\f]*\)\z//;
	$token =~ s/^['"]// and chop $token;
	return unescape $token
}

sub escape_str($) {
	"'" . escape($_[0],qr/'/) . "'"
}

sub unescape_str($) {
	unescape substr $_[0], 1, -1;
}

                              **__END__**

=head1 NAME

CSS::DOM::Util - Utility functions for dealing with CSS tokens

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM::Util ':all';
  # or:
  use CSS::DOM::Util qw[
    escape unescape
    escape_ident unescape_url
    escape_str unescape_str
  ];

=head1 DESCRIPTION

This module provides utility functions for dealing with CSS tokens.

=head1 FUNCTIONS

All functions below that take one argument have a C<($)> prototype, so they
have the same precedence as C<closedir> 
and C<delete>.

=over

=item escape $string, $chars_to_escape

This escapes any characters in C<$string> that occur in 
C<$chars_to_escape>, which is interpreted as a regular expression. The
regexp must consume just one character; otherwise you'll find chars
missing from the output. ASCII vertical whitespace (except the vertical
tab) is always escaped.

Printable non-alphanumeric ASCII characters and the space character are 
escaped with a single
backslash. Other characters are encoded in hexadecimal.

C<escape> also considers that you might want to include the escaped string
in a larger string, so it appends a space if the escaped string ends with a
hexadecimal escape with fewer than six digits.

=item unescape $string

This turns something like \"H\65llo\" into "Hello" (including quotes).

=item escape_ident $string

=item escape_ident $string, $more_chars_to_escape

This escapes C<$string> as a CSS identifier, escaping also any characters
matched by C<$more_chars_to_escape>.

=item unescape_url $url_token

Returns the URL that the token represents.

=item escape_str $string

Returns a CSS string token containing C<$string> (within quotes; characters
possibly escaped).

=item unescape_str $string_token

Returns the value that a CSS string token represents.

=back

=head1 SEE ALSO

L<CSS::DOM>
