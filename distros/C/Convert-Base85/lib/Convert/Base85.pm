package Convert::Base85;

use 5.016001;
use warnings;
use strict;

use Carp;
use Math::Int128 qw(
	uint128
	uint128_to_number
	uint128_add
	uint128_and
	uint128_divmod
	uint128_left
	uint128_mul
	uint128_right);

#
# Three '#' for encoding information, four '#' for decoding.
#
#use Smart::Comments q(#####);

our $VERSION = '1.02';

use Exporter qw(import);

our %EXPORT_TAGS;
our @EXPORT_OK = (qw(base85_check base85_encode base85_decode));

#
# Add an :all tag.
#
$EXPORT_TAGS{all} = [@EXPORT_OK];

=head1 NAME

Convert::Base85 - Encoding and decoding to and from Base 85 strings

=head1 SYNOPSIS

    use Convert::Base85;
 
    my $encoded = Convert::Base85::encode($data);
    my $decoded = Convert::Base85::decode($encoded);

or

    use Convert::Base85 qw(base85_encode base85_decode);
 
    my $encoded = base85_encode($data);
    my $decoded = base85_decode($encoded);

=head1 DESCRIPTION

This module implements a I<Base85> conversion for encoding binary
data as text. This is done by interpreting each group of sixteen bytes
as a 128-bit integer, which is then converted to a twenty-digit base 85
representation using the alphanumeric characters 0-9, A-Z, and a-z, in
addition to the punctuation characters !, #, $, %, &, (, ), *, +, -, ;, <, =, >,
?, @, ^, _, `, {, |, }, and ~, in that order.

This creates a string that is five fourths (1.25) larger than the original
data, making it more efficient than L<MIME::Base64>'s 3-to-4 ratio (1.3333).

As noted above, the conversion makes use of 128-bit arithmatic, which most
computers can't handle natively, which is why the module L<Math::Int128>
needs to be installed as well.

=cut

#
# character    value
#  0..9:        0..9
#  A..Z:        10..35
#  a..z:        36..61
#  punc:        62..84
#
# Take a number from 0 to 84, and turn it into a character.
#
my @b85_encode = ('0' .. '9', 'A' .. 'Z', 'a' .. 'z',
	'!', '#', '$', '%', '&', '(', ')', '*', '+',
	'-', ';', '<', '=', '>', '?', '@', '^', '_',
	'`', '{', '|', '}', '~');

#
# Take the ord() of a character, and return the number (from 0 to 84)
# for it. Unknown characters return -1.
#
my @b85_decode = (
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, 62, -1, 63, 64, 65, 66, -1, 67, 68, 69, 70, -1, 71, -1, -1,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, 72, 73, 74, 75, 76,
	77, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
	25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, 78, 79,
	80, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
	51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 81, 82, 83, 84, -1);

=head1 FUNCTIONS

=head3 base85_check

Examine a string for characters that fall outside the Base 85 character set.

Returns the first character position that fails the test, or -1 if no characters fail.

    if (my $d = base85_check($base85str) >= 0)
    {
        carp "Incorrect character at position $d; cannot decode input string";
        return undef;
    }

=cut

sub base85_check
{
	my($str) = @_;
	my(@chars) = split(//, $str);

	#
	### Check validity of: $str
	### Which becomes array: @chars
	#
	for my $j (0 .. $#chars)
	{
		my $o = ord($chars[$j]);
		return $j if ($o > 0x7f or $b85_decode[$o] == -1);
	}
	return -1;
}

=head3 base85_encode

=head3 Convert::Base85::encode

Converts input data to Base85 test.

This function may be exported as C<base85_encode> into the caller's
namespace.

   my $datalen = length($data);
   my $encoded = base85_encode($data); 

Or, if you  want to have managable lines, read 48 bytes at a time and
write 60-character lines (remembering that C<encode()> takes 16 bytes
at a time and encodes to 20 bytes). Remember to save the original length
in case the data had to be padded out to a multiple of 16.

=cut

sub encode
{
	my($plain) = @_;
	my @mlist;
	my $rem = uint128();

	#
	# Extra zero bytes to bring the length up to a multiple of sixteen.
	#
	my $extra = -length($plain) % 16;
	$plain .= "\0" x $extra;

	for my $str16 (unpack '(a16)*', $plain)
	{
		my @tmplist = (0) x 20;
		my $total16 = uint128(0);
		my @plain = unpack('C*', $str16);

		#
		### @plain: join(", ", @plain)
		#
		for my $p (@plain)
		{
			uint128_left($total16, $total16, 8);
			uint128_add($total16, $total16, uint128($p));
		}

		#
		##### total16: "$total16"
		#
		for my $j (reverse 0 .. 19)
		{
			uint128_divmod($total16, $rem, $total16, uint128(85));
			$tmplist[$j] = uint128_to_number($rem);
		}
		push @mlist, @tmplist;
	}

	return join "",	map{$b85_encode[$_]} @mlist;
}

*base85_encode = \&encode;


=head3 base85_decode

=head3 Convert::Base85::decode

Converts the Base85-encoded string back to bytes. Any spaces, linebreaks, or
other whitespace are stripped from the string before decoding.

This function may be exported as C<base85_decode> into the caller's namespace.

If your original data wasn't an even multiple of sixteen in length, the
decoded data may have some padding with null bytes ('\0'), which can be removed.

    #
    # Decode the string and compare its length with the length of the original data.
    #
    my $decoded = base85_decode($data); 
    my $padding = length($decoded) - $datalen;
    chop $decoded while ($padding-- > 0);

=cut

sub decode
{
	my($encoded) = @_;

	$encoded =~ tr[ \t\r\n\f][]d;

	my $extra = -length($encoded) % 20;

	my @mlist;
	my $imul = uint128(85);
	my $rem = uint128();

	for my $str20 (unpack '(a20)*', $encoded)
	{
		my $total20 = uint128(0);
		my @tmplist = (q(0)) x 16;

		my @coded = unpack('C*', $str20);

		#
		#### $str20: $str20
		#### @coded: join(", ", @coded)
		#
		for my $c (@coded)
		{
			my $iadd = uint128($b85_decode[$c]);
			uint128_mul($total20, $total20, $imul);
			uint128_add($total20, $total20, $iadd);
		}

		#
		##### total20: "$total20"
		#
		for my $j (reverse 0 .. 15)
		{
			uint128_divmod($total20, $rem, $total20, uint128(256));
			$tmplist[$j] = uint128_to_number($rem);
		}

		#
		##### @tmplist: join(", ", @tmplist)
		#
		push @mlist, @tmplist;
	}

	return join "",	map{chr($_)} @mlist;
}

*base85_decode = \&decode;

=head1 SEE ALSO

=head2 The Base85 Character Set

The Base85 character set is described by Robert Elz in his RFC1924 of
April 1st 1996,
L<"A Compact Representation of IPv6 Addresses"|https://tools.ietf.org/html/rfc1924>
which are made up from the 94 printable ASCII characters, minus
quote marks, comma, slash and backslash, and the brackets.

Despite it being an
L<April Fool's Day RFC|https://en.wikipedia.org/wiki/April_Fools%27_Day_Request_for_Comments>,
the reasoning for the choice of characters for the set was solid.

The character set is:

    '0'..'9', 'A'..'Z', 'a'..'z', '!', '#', '$', '%', '&',
    '*', '+', '-', ';', '<', '=', '>', '?', '@', '^', '_',
    '`', '|', and '~'.

and allows for the possibility of using the string in a MIME container.

=head2 Ascii85

Base85 is similar in concept to L<Ascii85|http://en.wikipedia.org/wiki/Ascii85>,
a format developed for the btoa program, and later adopted with changes by Adobe
for Postscript's ASCII85Encode filter. There are, of course, modules on CPAN
that provide this format.

=over 3

=item

L<Convert::Ascii85>

=item

L<Convert::Z85>

=back

=head2 Base64

L<Base64|https://en.wikipedia.org/wiki/Base64> encoding is an eight-bit to six-bit
encoding scheme that, depending on the characters used for encoding, has been used
for uuencode and MIME transfer, among many other formats. There are, of course,
modules on CPAN that provide this format.

=over 3

=item

L<Convert::Base64>

=item

L<MIME::Base64>

=back

=head1 AUTHOR

John M. Gamble C<< <jgamble at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-base85 at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-Base85>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is on Github at L<https://github.com/jgamble/Convert-Base85>.

You can also look for information on L<MetaCPAN|https://metacpan.org/release/Convert-Base85>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 John M. Gamble.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


1;

__END__

