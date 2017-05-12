package Crypt::Skip32::Base32Crockford;
use strict;
use warnings;
use Encode::Base32::Crockford qw(base32_encode base32_decode);
our $VERSION = '0.33';
use base 'Crypt::Skip32';

sub encrypt_number_b32_crockford {
    my ( $self, $number ) = @_;
    my $plaintext  = pack( 'N', $number );
    my $ciphertext = $self->encrypt($plaintext);
    my $b64        = base32_encode( unpack 'N', $ciphertext );
    return $b64;
}

sub decrypt_number_b32_crockford {
    my ( $self, $b64 ) = @_;
    my $ciphertext = base32_decode($b64);
    my $plaintext  = $self->decrypt( pack 'N', $ciphertext );
    my $number     = unpack( 'N', $plaintext );
    return $number;
}

1;

__END__

=head1 NAME

Crypt::Skip32::Base32Crockford - Create url-safe encodings of 32-bit values

=head1 SYNOPSIS

  use Crypt::Skip32::Base32Crockford;
  my $key    = pack( 'H20', "112233445566778899AA" ); # Always 10 bytes!
  my $cipher = Crypt::Skip32::Base32Crockford->new($key);
  my $b32    = $cipher->encrypt_number_b32_crockford(3493209676); # 1PT4W80
  my $number = $cipher->decrypt_number_b32_crockford('1PT4W80'); # 3493209676

=head1 DESCRIPTION

This module melds together L<Crypt::Skip32> and L<Encode::Base32::Crockford>.

L<Crypt::Skip32> is a 80-bit key, 32-bit block cipher based on Skipjack.
One example where Crypt::Skip32 has been useful: You have numeric database
record ids which increment sequentially. You would like to use them in
URLs, but you don't want to make it obvious how many X's you have in 
the database by putting the ids directly in the URLs.

L<Encode::Base32::Crockford> creates a 32-symbol notation for expressing
numbers in a form that can be conveniently and accurately transmitted 
between humans and computer systems.

Putting the two together lets you have numeric database records ids
which you can use safely in URLs without letting users see how many
records you have or letting them jump forward or backwards between
records.

You should pick a different key to the one in the synopsis.
It should be 10 bytes.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 LICENSE

This code is distributed under the same license as Perl.
