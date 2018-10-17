# -*-cperl-*-
#
# Crypt::EECDH - Simple ephemeral ECDH + AES hybrid cryptosystem
# Copyright (c) Ashish Gulhati <crypt-eecdh at hash.neo.tc>
#
# $Id: lib/Crypt/EECDH.pm v1.007 Tue Oct 16 23:45:54 PDT 2018 $

package Crypt::EECDH;

use warnings;
use strict;

use Crypt::Curve25519;
use Crypt::Ed25519;
use Crypt::EC_DSA;
use Bytes::Random::Secure;
use Crypt::Rijndael;
use Digest::SHA qw/sha256 hmac_sha256/;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.007 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  bless { debug     => $arg{Debug} || 0,
	  sigscheme => $arg{SigScheme} || 'ECDSA'
	}, $class;
}

my $format = 'C/a C/a n/a N/a';

sub encrypt {
  my ($self, %arg) = @_;

  if (defined $arg{SigningKey} && defined $arg{Signature}) {
    # Check signature on $public_key
    if ($self->sigscheme eq 'Ed25519') {
      return unless Crypt::Ed25519::verify($arg{PublicKey}, $arg{SigningKey}, $arg{Signature});
    }
    else {
      my $ecdsa = new Crypt::EC_DSA;
      return unless $ecdsa->verify( Message => $arg{PublicKey}, Signature => $arg{Signature},
				    Key => $arg{SigningKey} );
    }
  }

  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my $private = curve25519_secret_key($random->bytes(32));
  my $public  = curve25519_public_key($private);
  my $shared  = curve25519_shared_secret($private, $arg{PublicKey});

  my ($encrypt_key, $sign_key) = unpack 'a16 a16', sha256($shared);
  my $iv     = substr sha256($public), 0, 16;
  my $cipher = Crypt::Rijndael->new($encrypt_key, Crypt::Rijndael::MODE_CBC);
  $cipher->set_iv($iv);

  my $pad_length = 16 - length($arg{Message}) % 16;
  my $padding = chr($pad_length) x $pad_length;

  my $ciphertext = $cipher->encrypt($arg{Message} . $padding);
  my $mac = hmac_sha256($iv . $ciphertext, $sign_key);
  return (pack ($format, '', $public, $mac, $ciphertext), $private);
}

sub decrypt {
  my ($self, %arg) = @_;

  my ($options, $public, $mac, $ciphertext) = unpack $format, $arg{Ciphertext};
  die 'Unknown options' if $options ne '';

  my $shared = curve25519_shared_secret($arg{Key}, $public);
  my ($encrypt_key, $sign_key) = unpack 'a16 a16', sha256($shared);
  my $iv     = substr sha256($public), 0, 16;
  die 'MAC is incorrect' if hmac_sha256($iv . $ciphertext, $sign_key) ne $mac;
  my $cipher = Crypt::Rijndael->new($encrypt_key, Crypt::Rijndael::MODE_CBC);
  $cipher->set_iv($iv);

  my $plaintext = $cipher->decrypt($ciphertext);
  my $pad_length = ord substr $plaintext, -1;
  substr($plaintext, -$pad_length, $pad_length, '') eq chr($pad_length) x $pad_length or die 'Incorrectly padded';
  return ($plaintext, $public);
}

sub keygen {
  my ($self, %arg) = @_;
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my $secret = curve25519_secret_key($random->bytes(32));
  my $public = curve25519_public_key($secret);
  if ($arg{PrivateKey}) {
    # Sign public key with the signing key
    my $signature;
    if ($self->sigscheme eq 'Ed25519') {
      $signature = Crypt::Ed25519::sign( $public, $arg{PublicKey}, $arg{PrivateKey} );
    }
    else {
      my $ecdsa = new Crypt::EC_DSA;
      $signature = $ecdsa->sign( Message => $public, Key => $arg{PrivateKey} );
    }
    return ($public, $secret, $signature);
  }
  else {
    return ($public, $secret);
  }
}

sub signkeygen {
  my $self = shift;
  if ($self->sigscheme eq 'Ed25519') {
    return Crypt::Ed25519::generate_keypair;
  }
  else {
    my $ecdsa = new Crypt::EC_DSA;
    $ecdsa->keygen;
  }
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(debug|sigscheme)$/x) {
    $self->{$auto} = shift if (defined $_[0]);
    return $self->{$auto};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

1; # End of Crypt::EECDH

__END__

=head1 NAME

Crypt::EECDH - Simple ephemeral ECDH + AES hybrid cryptosystem

=head1 VERSION

 $Revision: 1.007 $
 $Date: Tue Oct 16 23:45:54 PDT 2018 $

=head1 SYNOPSIS

    use Crypt::EECDH;

    my $eecdh = new Crypt::EECDH;

    # Generate server's signing keypair
    my ($pub_signkey, $sec_signkey) = $eecdh->signkeygen;

    # Generate server's messaging key and signature
    my ($pubkey, $seckey, $signature) =
      $eecdh->keygen( PrivateKey => $sec_signkey, PublicKey => $pub_signkey );

    my $msg = "Testing";

    # Encrypt a message to server
    my ($encrypted, $clientsec) = $eecdh->encrypt( PublicKey => $pubkey,
      Message => $msg, SigningKey => $pub_signkey, Signature => $signature );

    # Server decrypts message
    my ($decrypted, $clientpub) =
      $eecdh->decrypt( Key => $seckey, Ciphertext => $encrypted );
    print "OK\n" if $decrypted eq $msg;

    # Server encrypts response (using a fresh ephemeral keypair)
    my ($encrypted2, $newsec) =
      $eecdh->encrypt( PublicKey => $clientpub, Message => $msg );

    # Client decrypts the response
    my ($decrypted2, $newpub) =
      $eecdh->decrypt( Key => $clientsec, Ciphertext => $encrypted2);

    # Now client can use $newpub to encrypt another message and the
    # exchange can continue. Note that the server will need to hold on
    # to $newsec in order to decrypt the response.

    # Alternately the client can use server's $pubkey for all messages
    # it sends, which frees server from having to keep track of new
    # ephemeral keys.

=head1 DESCRIPTION

A simple hybrid crypto system with ephemeral ECDH key agreement in
combination with the AES cipher.

=head1 TECHNICAL DETAILS

This modules uses Daniel J. Bernstein's curve25519 to perform a
Diffie-Hellman key agreement. A new keypair is generated for every
encryption operation. The shared key resulting from the key agreement
is hashed and used to encrypt the plaintext using AES in CBC mode
(with the IV deterministically derived from the public key). It also
adds a HMAC, with the key derived from the same shared secret as the
encryption key.

Some of the code in this module (and most of the text of the previous
paragraph) is from the L<Crypt::ECDH_ES> module, which provides
one-way communication functionality in an ephemeral-static mode, where
one side (the decoder or "server") uses a static key.

Crypt::EECDH provides full two-way encryption capability with
ephemeral keys on both sides. Instead of a static messaging key, the
server uses a static signing key, and signs its ephemeral messaging
keys with its signing key. The signing key is never used to encrypt
messages. The server may generate a new ephemeral messaging key pair
at the start of each client session, or it may perodically generate
and publish new messaging keys.

=head1 METHODS

=head2 new

Creates and returns a new Crypt::EECDH object. The following optional
named parameters can be provided:

=over

SigScheme - The signature scheme to use for the signing keys. Valid
options are 'ECDSA' and 'Ed25519', which use the L<Crypt::EC_DSA> and
L<Crypt::Ed25519> modules respectively. The default is 'ECDSA'.

Debug - Set to a true value to have the module emit messages useful
for debugging.

=back

=head2 signkeygen

Generates and returns a signing keypair as a two element list, with
the public key as the first element, private key as the second.

=head2 keygen

Generates and returns a messaging keypair as a two element list, with
the public key as the first element, private key as the second. The
following optional parameters may be provided:

=over

PrivateKey - The signing private key

PublicKey - The signing public key

=back

=head2 encrypt

Encrypts a message. A new keypair is generated for each encryption
operation. Returns a list whose first element is the cipherext and
second element is the generated private key. The following named
parameters are required:

=over

PublicKey - The public messaging key of the recipient

Message - The message to be encrypted

=back

The following optional parameters can be provided:

=over

SigningKey - The public signing key of the recipient

Signature - Signature on the messaging key

=back

=head2 decrypt

Decrypts a message. Returns a list whose first element is the
decrypted message and second element is the public key of the
sender. The following named parameters are required:

=over

Key - The private messaging key of the recipient

Ciphertext - The ciphertext to be decrypted

=back

=head1 SEE ALSO

=over 4

=item * L<Crypt::ECDH_ES>

=back

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-eecdh at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-eecdh at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-EECDH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::EECDH

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-EECDH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-EECDH>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-EECDH>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-EECDH/>

=back

=head1 ACKNOWLEDGEMENTS

Some of the code in this module is from L<Crypt::ECDH_ES> by Leon
Timmermans <leont@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
