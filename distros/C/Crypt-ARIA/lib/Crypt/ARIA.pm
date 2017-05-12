use strict;
use warnings;
package Crypt::ARIA;
{
  $Crypt::ARIA::VERSION = '0.004';
}

use Carp qw/croak carp/;

# ABSTRACT: Perl extension for ARIA encryption/decryption algorithm.

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use Crypt::ARIA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

# our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Crypt::ARIA', $Crypt::ARIA::VERSION);

# Preloaded methods go here.

use constant BLOCKSIZE => 16;
use constant KEYSIZES => ( 128, 192, 256 );
use constant MAX_USER_KEYS => 99_999_999;

sub blocksize { return BLOCKSIZE; }
sub keysize     { return max_keysize(); }
sub max_keysize { return (KEYSIZES)[-1] / 8; }
sub min_keysize { return (KEYSIZES)[0] / 8;  }

sub usage {
    my ( $package, $filename, $line, $subr ) = caller(1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr(@_)";
}

# new( [ key ] )
sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = { };
    bless $self, $class;

    if ( @_ ) {
        $self->set_key( shift );
    }

    return $self;
}

sub has_key {
    my $self = shift;

    return defined( $self->{key} );
}

sub set_key {
    my $self = shift;
    my $key  = shift;

    my $len  = 8 * length $key;
    unless ( grep { $len == $_ } KEYSIZES ) {
        croak 'Keysize should be one of '.join(',', KEYSIZES).' bits.'
             .'(current keysize = '.$len.' bits)';
    }
    $self->{key} = $key;
    $self->{keybits} = 8 * length $key;

    ( $self->{enc_round}, $self->{enc_roundkey} ) = _setup_enc_key( $self->{key}, $self->{keybits} );
    ( $self->{dec_round}, $self->{dec_roundkey} ) = _setup_dec_key( $self->{key}, $self->{keybits} );

    return $self;
}

sub set_key_hexstring {
    my $self = shift;
    my $key  = shift;

    $key =~ s/\s+//g;
    $self->set_key( pack("H*", $key) );

    return $self;
}

sub unset_key {
    my $self = shift;

    undef $self->{key};
    undef $self->{enc_round};
    undef $self->{enc_roundkey};
    undef $self->{dec_round};
    undef $self->{dec_roundkey};

    return $self;
}

# one block
sub encrypt {
    my $self = shift;
    my $data = shift;

    unless ( defined $self->{enc_roundkey} and defined $self->{enc_round} ) {
        carp 'key should be provided using set_key() or set_key_hexstring().';
        return undef;
    }

    my $len = length $data;
    if ( $len != BLOCKSIZE ) {
        carp 'data should be '.BLOCKSIZE.' bytes.';
        return undef;
    }

    my $cipher = _crypt( $data, $self->{enc_round}, $self->{enc_roundkey} );
    return $cipher;
}

sub decrypt {
    my $self   = shift;
    my $cipher = shift;

    unless ( defined $self->{enc_roundkey} and defined $self->{enc_round} ) {
        carp 'key should be provided using set_key() or set_key_hexstring().';
        return undef;
    }

    my $len = length $cipher;
    if ( $len != BLOCKSIZE ) {
        carp 'cipher should be '.BLOCKSIZE.' bytes.';
        return undef;
    }

    my $data = _crypt( $cipher, $self->{dec_round}, $self->{dec_roundkey} );
    return $data;
}

# ECB - null padding
sub encrypt_ecb {
    my $self = shift;
    my $data = shift;

    my $len = length $data;
    my $cipher = "";

    my $i = 0;
    while ( $i < $len ) {
        my $buflen = ($len-$i) > BLOCKSIZE ? BLOCKSIZE : $len - $i;
        my $buf = substr( $data, $i, $buflen );
        if ( $buflen < BLOCKSIZE ) {
            $buf .= "\x00" x (BLOCKSIZE - $buflen);
        }
        my $cipbuf = $self->encrypt( $buf );
        $cipher .= $cipbuf;
        $i += $buflen;
    }

    return $cipher;
}

sub decrypt_ecb {
    my $self   = shift;
    my $cipher = shift;

    my $len = length $cipher;
    if ( $len % BLOCKSIZE ) {
        carp 'Size of cipher is not a multiple of '.BLOCKSIZE;
        return undef;
    }

    my $data = "";

    my $i = 0;
    while ( $i < $len ) {
        my $cipbuf = substr( $cipher, $i, BLOCKSIZE );
        my $buf = $self->decrypt( $cipbuf );
        $data .= $buf;
        $i += BLOCKSIZE;
    }

    return $data;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Crypt::ARIA - Perl extension for ARIA encryption/decryption algorithm.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Crypt::ARIA;

  # create an object
  my $aria = Crypt::ARIA->new();
  # or,
  my $key = pack 'H*', '00112233445566778899aabbccddeeff';
  my $aria = Crypt::ARIA->new( $key );


  # set master key
  $aria->set_key( pack 'H*', '00112233445566778899aabbccddeeff' );
  # or
  # (whitespace allowed)
  $aria->set_key_hexstring( '00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff' );


  # one block encryption/decryption
  # $plaintext and $ciphertext should be of "blocksize()" bytes.
  my $cipher = $aria->encrypt( $plain );
  my $plain  = $aria->decrypt( $cipher );

  
  # multi block encryption/decryption
  # simple ECB mode
  my $cipher    = $aria->encrypt_ecb( $plain );
  my $decrypted = $aria->decrypt_ecb( $cipher );
  # note that $decrypt may not be same as $plain, because it is appended
  # null bytes to.


  # CBC mode
  use Crypt::CBC;
  my $cbc = Crypt::CBC->new(
        -cipher => Crypt::ARIA->new()->set_key( $key ),
        -iv     => $initial_vector,
        -header => 'none';
        -padding => 'none';
    );
  my $cipher = $cbc->encrypt( $plain );
  my $plain  = $cbc->decrypt( $cipher );

=head1 DESCRIPTION

Crypt::ARIA provides an interface between Perl and ARIA implementation
in C.

ARIA is a block cipher algorithm designed in South Korea.
For more information about ARIA, visit links in L</SEE ALSO> section.

The C portion of this module is made by researchers of ARIA and is
available from the ARIA website. I had asked them and they've made sure
that the code is free to use.

=head1 METHODS

=over

=item new

C<new()> method creates an object.

  my $aria = Crypt::ARIA->new();

You can give a master key as argument. The master key in ARIA should be of 16, 24, or 32 bytes.

  my $key = pack 'H*', '00112233445566778899aabbccddeeff';
  my $aria = Crypt::ARIA->new( $key );

=item set_key

C<set_key()> sets a master key. This method returns the object itself.

  $aria->set_key( pack 'H*', '00112233445566778899aabbccddeeff' );

=item set_key_hexstring

C<set_key_hexstring()> sets a master key. You can give a hexstring as
argument. The hexstring can include whitespaces.
This method returns the object itself.

  $aria->set_key_hexstring( '00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff' );

=item unset_key

This method removes the master key from object and return the object itsetf.

  $aria->unset_key();

=item has_key

This method returns true if a master key is set, false otherwise.

=item encrypt

C<encrypt()> encrypts a block of plaintext.

  my $cipher = $aria->encrypt( $plain );

$plain should be of exactly 16 bytes.
It returns a ciphertext of 16 bytes.
If you want to encrypt a text of different length,
you have to choose the operation mode and the padding method.
You may implement them by yourself or use another module for them.

C<Crypt::ARIA> is designed to be compatible with L<Crypt::CBC>.
Therefore, you can use C<Crypt::CBC> to use CBC mode with several
padding methods.

  use Crypt::CBC;
  my $cbc = Crypt::CBC->new(
        -cipher => Crypt::ARIA->new()->set_key( $key ),
        -iv     => $initial_vector,
        -header => 'none';
        -padding => 'none';
    );
  my $cipher = $cbc->encrypt( $plain );
  my $plain  = $cbc->decrypt( $cipher );

=item decrypt

C<decrypt()> decrypts a block of ciphertext.

  my $plain  = $aria->decrypt( $cipher );

$cipher should be of exactly 16 bytes.
Again, you have to use another module to decrypt multi-block
message.

=item encrypt_ecb

This method encrypts a plaintext of arbitrary length.

  my $cipher  = $aria->encrypt_ecb( $plain );

It returns the ciphertext whose length is multiple of 16 bytes.

NOTE: If the length of $plain is not n-times of 16 exactly,
C<encrypt_ecb()> appends null bytes to fill it. If the length
is n-times of 16 exactly, $plain would be untouched. This means
you should have to deliver the original length of $plain to the
receiver. You had better use other module like L<Crypt::CBC> that
provides advanced operation mode and padding method.
This method is just for test purpose.

=item decrypt_ecb

This method decrypts a multi-block ciphertext.

  my $decrypted = $aria->decrypt_ecb( $cipher );

As described in L</encrypt_ecb>, $decrypted may contain a sequence
of null bytes in its end. You should remove them yourself.

=back

=head1 SEE ALSO

L<Crypt::CBC>, L<Crypt::SEED>

L<http://en.wikipedia.org/wiki/ARIA_%28cipher%29>

L<http://210.104.33.10/ARIA/index-e.html>

IETF RFC 5794 : A Description of the ARIA Encryption Algorithm
L<http://tools.ietf.org/html/rfc5794>

=head1 AUTHOR

Geunyoung Park <gypark@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Geunyoung Park.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# Below is stub documentation for your module. You'd better edit it!


