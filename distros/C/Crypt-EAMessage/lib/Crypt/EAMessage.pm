#
# Copyright (C) 2015-2023 Joelle Maslak
# All Rights Reserved - See License
#

package Crypt::EAMessage;
$Crypt::EAMessage::VERSION = '1.232011';
use v5.22;

# ABSTRACT: Simple-to-use Abstraction of Encrypted Authenticated Messages

use strict;
use warnings;
use autodie;

use feature "signatures";

use Carp;

use Moose;
use Moose::Util::TypeConstraints;

no warnings "experimental::signatures";

use Bytes::Random::Secure;
use Crypt::AuthEnc::CCM qw(ccm_encrypt_authenticate ccm_decrypt_verify);
use MIME::Base64        qw(encode_base64 decode_base64);
use Storable            qw(nfreeze thaw);

use namespace::autoclean;



around 'BUILDARGS', sub ( $orig, $class, %args ) {
    my (@only_one) = qw(raw_key hex_key);
    my $cnt = 0;
    foreach my $a (@only_one) {
        if ( exists( $args{$a} ) ) {
            $cnt++;
        }
    }
    if ( $cnt > 1 ) { die("Must not have multiple *_key arguments"); }

    if ( exists( $args{hex_key} ) ) {
        my $hex = $args{hex_key};
        delete( $args{hex_key} );

        $args{raw_key} = _hex_to_raw($hex);
    }

    $class->$orig(%args);
};

sub _hex_to_raw ($hex) {
    $hex =~ s/^0x//;    # Remove 0x leader if it is present

    if ( $hex =~ /[^0-9A-Fa-f]/s ) { die("Non-hex characters present in hex_key"); }

    my $l = length($hex);
    if ( ( $l != 32 ) && ( $l != 48 ) && ( $l != 64 ) ) {
        die("hex_key is the wrong length");
    }

    return pack( 'H*', $hex );
}

subtype 'Crypt::EAMessage::Key', as 'Str',
  where { _valid_key($_) },
  message { "AES key lengths must be 16, 24, or 32 bytes long" };

sub _valid_key ($key) {
    my $l = length($_);

    if ( ( $l != 16 ) && ( $l != 24 ) && ( $l != 32 ) ) { return; }
    if ( utf8::is_utf8($key) ) {
        die("Key must not be UTF-8 encoded");
    }

    return 1;
}


has 'raw_key' => (
    is       => 'rw',
    isa      => 'Crypt::EAMessage::Key',
    required => 1,
);


sub hex_key {
    if ( ( scalar(@_) < 1 ) || ( scalar(@_) > 2 ) ) {
        confess("Invalid call");
    }

    my $self = shift;

    if ( scalar(@_) == 1 ) {
        # Setter
        $self->raw_key( _hex_to_raw(shift) );
    }

    return unpack( 'H*', $self->raw_key() );
}


sub encrypt_auth ( $self, $input ) {
    my $ct = $self->_encrypt_auth_internal($input);
    return "1$ct";    # Type 1 = Binary Format
}


sub encrypt_auth_ascii ( $self, $input, $eol = undef ) {
    my $ct     = $self->_encrypt_auth_internal($input);
    my $base64 = encode_base64( $ct, $eol );
    return "2$base64";    # Type 2 = Base 64
}

sub _encrypt_auth_internal ( $self, $input, $opts = {} ) {
    state $random = Bytes::Random::Secure->new( Bits => 1024, NonBlocking => 1 );

    if ( defined Scalar::Util::reftype($input) ) {
        if ( Scalar::Util::reftype($input) eq "OBJECT" ) {
            die("Cannot encrypt a perl class (new style) object");
        }
    }

    for my $opt ( sort keys %$opts ) {
        if ( $opt eq 'text' ) { next; }

        die("Unknown option to encrypt: $opt");
    }

    my $nonce = $random->bytes(16);

    my $data;
    if ( ( !exists( $opts->{text} ) ) && ( !$opts->{text} ) ) {
        # Any type of input
        $data = nfreeze( \$input );
    } else {
        # Text only input
        $data = $input;
    }

    my ( $enc, $tag ) =
      ccm_encrypt_authenticate( 'AES', $self->raw_key(), $nonce, '', 128, $data );

    my $ct = $nonce . $tag . $enc;
    return $ct;
}


sub encrypt_auth_urlsafe ( $self, $input ) {
    my $ct = $self->_encrypt_auth_internal($input);

    my $urltext = encode_base64( $ct, "" );
    $urltext =~ tr|\+/|-_|;

    return "3$urltext";    # Type 3 = Modified Base 64
}


sub encrypt_auth_portable ( $self, $input ) {
    my $ct = $self->_encrypt_auth_internal( $input, { text => 1 } );

    my $urltext = encode_base64( $ct, "" );
    $urltext =~ tr|\+/|-_|;

    return "4$urltext";    # Type 3 = Modified Base 64
}


sub decrypt_auth ( $self, $ct ) {
    if ( length($ct) < 34 ) { die("Message too short to be valid") }

    my $type = substr( $ct, 0, 1 );
    my $enc  = substr( $ct, 1 );

    if ( $type eq '1' ) {
        return $self->_decrypt_auth_internal($enc);
    } elsif ( $type eq '2' ) {
        my $ascii = decode_base64($enc);    # It's okay if this ignores bad base64,
                                            # since we'll fail decryption.
        return $self->_decrypt_auth_internal($ascii);
    } elsif ( $type eq '3' ) {
        $enc =~ tr|-_|+/|;
        my $ascii = decode_base64($enc);    # It's okay if this ignores bad base64,
                                            # since we'll fail decryption.
        return $self->_decrypt_auth_internal($ascii);
    } elsif ( $type eq '4' ) {
        $enc =~ tr|-_|+/|;
        my $ascii = decode_base64($enc);    # It's okay if this ignores bad base64,
                                            # since we'll fail decryption.
        return $self->_decrypt_auth_internal( $ascii, { text => 1 } );
    } else {
        die("Unsupported encoding type");
    }
}

sub _decrypt_auth_internal ( $self, $ct, $opts = {} ) {
    if ( length($ct) < 32 ) { die("Message too short to be valid") }

    for my $opt ( sort keys %$opts ) {
        if ( $opt eq 'text' ) { next; }

        die("Unknown option to decrypt: $opt");
    }

    my $nonce = substr( $ct, 0,  16 );
    my $tag   = substr( $ct, 16, 16 );
    my $enc   = substr( $ct, 32 );

    my $frozen = ccm_decrypt_verify( 'AES', $self->raw_key(), $nonce, '', $enc, $tag );
    if ( !defined($frozen) ) { die("Could not decrypt message") }

    if ( ( !exists( $opts->{text} ) ) && ( !$opts->{text} ) ) {
        # Perl 5 data structure
        my $plaintext = thaw($frozen);
        return $$plaintext;
    } else {
        # Plain text
        return $frozen;
    }
}


sub generate_key ($self) {
    return Bytes::Random::Secure::random_bytes_hex(32);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::EAMessage - Simple-to-use Abstraction of Encrypted Authenticated Messages

=head1 VERSION

version 1.232011

=head1 SYNOPSIS

  use Crypt::EAMessage;

  my $eamsg = Crypt::EAMessage->new( hex_key => $hex );

  $encrypted    = $eamsg->encrypt_auth($input);
  $enc_ascii    = $eamsg->encrypt_auth_ascii($input);
  $enc_url      = $eamsg->encrypt_auth_urlsafe($input);
  $enc_portable = $eamsg->encrypt_auth_portable($input); # Input must be text

  $decrypted = $eamsg->decrypt_auth($encrypted);

=head1 DESCRIPTION

This module provides an easy-to-use method to create encrypted and
authenticated messages from arbitrary Perl objects (anything compatible
with L<Storable>). Note that Perl 5.38+ Corinna class objects are not
serializable with L<Storable>.

While there are many modules that encrypt text, there are many less that
provide encryption and authentication without a complex interface.  This
module uses AES encryption in CCM mode. This allows two parties to
communicate securely, provided they both use the same secret key.  In
addition to providing privacy, this module also ensures that the message
was created by someone who had knowledge of the private key - in otherwords
the message was also not tampered with in-transit.

When encrypting, this module produces a message that contains the
message's nonce (a unique value that changes the results of the encryption
so two identical messages will be encrypted differently), the authentication
tag (used to authenticate the message), and the cipher text.  It can be
formatted in either a "printable" base 64 encoding or in raw binary form.

=head1 ATTRIBUTES

=head2 raw_key

This is the key used for encryption/decryption (a string of 16, 24, or 32
bytes).  Note that the size of the key determines the strength of the AES
encryption - a 16 byte string uses AES-128, 24 uses AES-192, 32 uses
AES-256.

=head2 hex_key

This is the hex version of the key. This should consist of a string
of 32, 48, or 64 hex digits (creating a 16, 24, or 32 byte key).

=head1 METHODS

=head2 new

  my $eamsg = Crypt::EAMessage->new( raw_key => $key );

or

  my $eamsg = Crypt::EAMessage->new( hex_key => $hex );

Create a new workunit class.  It takes either a C<raw_key> or a C<hex_key>
parameter.  See the C<raw_key> and C<hex_key> attributes.

=head2 encrypt_auth

  my $ciphertext = $ea->encrypt_auth( $plaintext );

Encrypts the plain text (or any other Perl object that C<Storable> can
freeze and thaw) passed as a parameter, generating a binary (non-printable)
cipher text output.

=head2 encrypt_auth_ascii

  my $ciphertext = $ea->encrypt_auth_ascii( $plaintext );
  my $ciphertext = $ea->encrypt_auth_ascii( $plaintext, "" );

Encrypts the plain text (or any other Perl object that C<Storable> can
freeze and thaw) passed as a parameter, generating an ASCII (base64)
cipher text output.

Starting in version 1.004, a second, optional, argument is allowed.
If an argument after C<$plaintext> is supplied, that becomes the line ending
for the output text.  If no argument is provided, a standard newline
appropriate to the platform is used.  Otherwise, the value of that string
is used as the line ending, in the same way as it would be if passed as
the L<MIME::Base64::encode_base64> function's second argument.

Note that when using line endings other than a blank ending (no line ending)
or a standard newline, you should strip the new line identifier from the
cypertext before calling the L<decrypt_auth_ascii> method.

=head2 encrypt_auth_urlsafe

  my $ciphertext = $ea->encrypt_auth_urlsafe( $plaintext );

Added in version 1.006.

Encrypts the plain text (or any other Perl object that C<Storable> can
freeze and thaw) passed as a parameter, generating an ASCII (modified
base64) cipher text output.  This output is safe to pass as part of a
query string or URL.  Namely, it doesn't use the standard Base 64
characters C<+> or C</>, replacing them with C<-> and C<_> respectively.
In addition, the cyphertext output will start with a "3" rather than the
"2" that the base 64 variant starts with.

=head2 encrypt_auth_portable

  my $ciphertext = $ea->encrypt_auth_portable( $plaintext );

Added in version 1.190900

Encrypts the plain text (or byte string) passed as a parameter, generating
an ASCII (modified base64) cipher text output.  This output is safe to pass
as part of a query string or URL.  Namely, it doesn't use the standard Base 64
characters C<+> or C</>, replacing them with C<-> and C<_> respectively.
In addition, the cyphertext output will start with a "4".

This is intended for cross-language compatibility, so it does not utilize
store/thaw.

SECURITY NOTE: The contents of a zero length string can be determined from
the length of the encrypted portable message.

=head2 decrypt_auth

  my $plaintext = $ea->decrypt_auth( $ciphertext );

Decrypts the cipher text into the object that was frozen during encryption.

If the authentication or decryption fails, an exception is thrown. Otherwise
it returns the plaintext/object.

=head2 generate_key

 say "Hex key: " . Crypt::EAMessage->generate_key()

Added in version 1.220390

This is a class method (I.E. you do not need to instantiate the
C<Crypt::EAMessage> class to use this).

Returns a randomly generated key suitable to use with AES256 as a hex number.

=head1 GENERATING AES256 KEYS

To generate a key, a simple Perl program can accomplish this - note that you
should NOT use standard C<rand()> to do this.

  use feature 'say';
  use Crypt::EAMessage;

  my $hexkey = Crypt::EAMessage->generate_key()
  say "Key is: $hexkey";

Alternative, you can do this with a one-liner to return a hex key, and the
L<Crypt::EAMessage::Keygen> module:

  perl -MCrypt::EAMessage::Keygen -e 1

This will output a random key in hex format suitable for use as an AES256 key.

=head1 SECURITY

Note that this module use L<Storable>. Thus this module should only be used
when the endpoint is trusted. This module will ensure that the stored
object is received without tampering by an intermediary (and is secure even
when an untrusted third party can modify the encrypted message in transit),
because C<thaw> is not called unless the message passes authentication
checks.  But if an endpoint can create a malicious message using a valid
key, it is possible that this message could exploit some vulnerability in
the L<Storable> module.

This module does not protect against replay attacks.

This module is not protected against timing attacks.

=head1 ALTERNATIVES

This module implements a tiny subset of the functionality in L<Crypt::Util>
which may be a better choice for more complex use cases.

=head1 BUGS

None known, however it is certainly possible that I am less than perfect!
If you find any bug you believe has security implications, I would
greatly appreciate being notified via email sent to jmaslak@antelope.net
prior to public disclosure. In the event of such notification, I will
attempt to work with you to develop a plan for fixing the bug.

All other bugs can be reported via email to jmaslak@antelope.net or by
using the Git Hub issue tracker
at L<https://github.com/jmaslak/Crypt-EAMessage/issues>

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
