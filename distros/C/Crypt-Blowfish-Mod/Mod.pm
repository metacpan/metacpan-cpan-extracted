package Crypt::Blowfish::Mod;
our $VERSION = '0.04';

use strict;
use warnings;
use Carp;
use MIME::Base64;

use vars qw/$VERSION @ISA/;

require DynaLoader;
@ISA = qw/DynaLoader/;

bootstrap Crypt::Blowfish::Mod $VERSION;

sub new {
	my $class = shift;
	my %p = @_ == 1 ? ( key=>shift ) : ( @_ );

	confess "Missing 'key' parameter to $class->new()" unless( $p{key} || $p{key_raw} );

	my $endianness = $p{endianness} || $class->_detect_endianness;
	my $key = $p{key_raw} || MIME::Base64::decode_base64( $p{key} );
	return bless( {  key => $key, endianness=>$endianness }, $class );
}

sub _detect_endianness {
	return 10002000 == unpack("h*", pack("s2", 1, 2)) ? 'little' : 'big';
}

sub _is_big_endian {
	my $self = shift;
	return $self->{endianness} eq 'little' ? 0 : 1;
}

sub encrypt_raw {
	my ($self, $str ) = @_;
    return MIME::Base64::decode_base64($self->encrypt($str));
}

sub decrypt_raw {
	my ($self, $str ) = @_;
    $self->decrypt( MIME::Base64::encode_base64($str, '') );
}

sub encrypt {
	my ($self, $str ) = @_;
	return Crypt::Blowfish::Mod::b_encrypt( $self->{key}, $str, $self->_is_big_endian )
}

sub decrypt {
	my ($self, $str ) = @_;
	return Crypt::Blowfish::Mod::b_decrypt( $self->{key}, $str, $self->_is_big_endian );
}

1;

__END__

=head1 NAME

Crypt::Blowfish::Mod - Another Blowfish Algorithm 

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Crypt::Blowfish::Mod;

    my $cipher = new Crypt::Blowfish::Mod $key; 
    my $ciphertext = $cipher->encrypt($plaintext);
    $plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Crypt::Blowfish::Mod implements the Blowfish algorithm using functions adapted from examples from Bruce Schneier
and other authors. 

Crypt::Blowfish::Mod has an interface similar to L<Crypt::Blowfish>, but produces different results. This module
is endianness sensitive, making sure that it gives the same encription/decription results in different architectures.

Also, this module accepts variable length keys up to 256 bytes. By default, it assumes the C<key> is a Base64
string. And all text encrypted or decrypted is also in Base64. 

=head1 METHODS

=head2 new

Usage:

    ## the key should be base64
    my $b = Crypt::Blowfish::Mod->new('YaKjsKjY0./');

    ## or use a raw key:
    my $b = Crypt::Blowfish::Mod->new( key_raw=>'this_is_a_raw_key9k&$!djf29389238928938' );

    my $enc = $b->encrypt( 'secret text' ); 
    my $dec = $b->decrypt( $enc );

If you prefer, work with raw encrypted strings:

    my $enc = $b->encrypt_raw( 'secret text' ); 
    my $dec = $b->decrypt_raw( $enc );

Or just call it even more raw (Big Endian):

    my $enc = Crypt::Blowfish::Mod::b_encrypt( $key, $str, 1 );
    my $dec = Crypt::Blowfish::Mod::b_decrypt( $key, $enc, 1 );

=head2 encrypt

Returns a encrypted string encoded in Base64.

=head2 decrypt

Decodes a base64 encoded blowfish encrypted string.

=head2 encrypt_raw

Returns a raw encrypted string.

=head2 decrypt_raw

Decodes a raw encoded blowfish encrypted string.

=head2 b_encrypt( Str $text, Str $key, Bool is_big_endian )

Raw C decrypt function.

=head2 b_decrypt( Str $text, Str $key, Bool is_big_endian )

Raw C decrypt function.

=head1 NOTES

The Blowfish algorithm is highly dependent on the endianness of your architecture.
This module attempts to detect the correct endianness for your architecture, otherwise
it will most likely default to little-endian. 

You may override this behavior by setting the endianness on instantiation:

	# force little-endian
    my $b = Crypt::Blowfish::Mod->new( key=>'YaKjsKjY0./', endianness=>'little' );

Intel-based architectures are typically Little-Endian. 

=head1 SEE ALSO

L<Crypt::Blowfish>

L<Crypt::OpenSSL::Blowfish>

This algorithm has been implemented in other languages:

http://www.schneier.com/blowfish-download.html

=head1 AUTHOR

Rodrigo de Oliveira, E<lt>rodrigo@cpan.orgE<gt>

=cut