package ACME::Base64::Hexagram;

use warnings;
use strict;
use utf8;

use MIME::Base64 qw{ encode_base64 decode_base64 };

use Exporter qw{ import };
our @EXPORT = qw{ encode_base64h decode_base64h };

our $VERSION = '0.002';

sub encode_base64h {
    my ($string) = @_;
    my $encoded = encode_base64($string);
    $encoded =~ tr{A-Za-z0-9+/=}{䷀䷁䷂䷃䷄䷅䷆䷇䷈䷉䷊䷋䷌䷍䷎䷏䷐䷑䷒䷓䷔䷕䷖䷗䷘䷙䷚䷛䷜䷝䷞䷟䷠䷡䷢䷣䷤䷥䷦䷧䷨䷩䷪䷫䷬䷭䷮䷯䷰䷱䷲䷳䷴䷵䷶䷷䷸䷹䷺䷻䷼䷽䷾䷿·};
    $encoded
}

sub decode_base64h {
    my ($encoded) = @_;
    $encoded =~ tr{䷀䷁䷂䷃䷄䷅䷆䷇䷈䷉䷊䷋䷌䷍䷎䷏䷐䷑䷒䷓䷔䷕䷖䷗䷘䷙䷚䷛䷜䷝䷞䷟䷠䷡䷢䷣䷤䷥䷦䷧䷨䷩䷪䷫䷬䷭䷮䷯䷰䷱䷲䷳䷴䷵䷶䷷䷸䷹䷺䷻䷼䷽䷾䷿·}{A-Za-z0-9+/=};
    my $decoded = decode_base64($encoded);
    $decoded
}


=head1 NAME

 ACME::Base64::Hexagram - Base64 encoding using I Ching hexagrams

=head1 SYNOPSIS

  use ACME::Base64::Hexagram qw{ decode_base64h encode_base64h };

  my $encoded = encode_base64h('The Book of Changes');

=head1 FUNCTIONS

=over 4

=item encode_base64h($string)

Returns the $string encoded in hexagrams.

=item decode_base64h($encoded)

Returns the decoded string back.

=back

=head1 ORDER

The module uses King Wen order.

=head1 THANKS

  #perl on Libera.chat
  thrig: there are 64 hexagrams. just saying.

=head1 AUTHOR

E. Choroba <chorobaE<64>matfyz.cz>

=cut

__PACKAGE__
