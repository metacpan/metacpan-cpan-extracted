package Convert::XText;

use strict;
use warnings;

our $VERSION = "0.01";

use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(decode_xtext encode_xtext);

sub encode_xtext {
	my $input = shift;
	$input =~ s/([^!-*,-<>-~])/'+'.uc(unpack('H*', $1))/eg;
	return $input;
}

sub decode_xtext {
	my $input = shift;
	$input =~ s/\+([0-9A-F]{2})/chr(hex($1))/eg;
	return $input;
}

1;
__END__

=head1 NAME

Convert::XText - Convert from and to RFC 1891 xtext encoding

=head1 SYNOPSIS

  use Convert::XText;
  
  my $encoded = Convert::XText::encode_xtext('String to=encode');
  # $encoded contains "String+20to+3Dencode"
  
  my $decoded = Convert::XText::decode_xtext($encoded);
  # $decoded contains 'String to=encode'

=head1 DESCRIPTION

RFC1891 defines the xtext encoding for delivery service notifications,
to encode non-standard-ascii characters and special chars in a simple
and fast, as well as easily reversible, way.

The input data for encode_xtext simply converts all characters outside
the range of C<chr(33)> I<(!)> to C<chr(126)> I<(~)>, as well as the
plus I<(+)> and equal I<(=)> sign, into a plus sign followed by a two
digit uppercase hexadecimal representation of the character code.

For example, the I<"="> sign, ASCII 61 or \x3d, will be converted to
B<+3D>.

=head2 FUNCTIONS

=over 4

=item encode_xtext ($string_to_encode)

Expects a non-unicode-string to encode in xtext encoding. Returns
the encoded text.

=item decode_xtext ($string_to_decode)

Expects an xtext-encoded string and returns the decoded string.

=back

=head2 EXPORT

None by default.

You can manually export encode_xtext and decode_xtext:

    use Convert::XText qw(encode_xtext);
    
    encode_xtext( $string_to_encode );

=head1 SEE ALSO

http://www.faqs.org/rfcs/rfc1891.html - The original xtext definition

http://www.postfix.org/XCLIENT_README.html - Special usage of xtext encoding

=head1 AUTHOR

Chr. Winter, E<lt>CHRWIN@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Chr. Winter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
