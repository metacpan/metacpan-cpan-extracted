package Crypt::NaCl::Sodium;

our $VERSION = '2.003';
our $XS_VERSION = $VERSION;

use strict;
use warnings;

use Carp qw( croak );
use Sub::Exporter;

require XSLoader;
XSLoader::load('Crypt::NaCl::Sodium', $XS_VERSION);

my @funcs = qw(
    bin2hex hex2bin
    memcmp compare memzero
    increment
    random_bytes
    random_number
);

Sub::Exporter::setup_exporter(
    {
        exports => \@funcs,
        groups => {
            all => \@funcs,
            utils => \@funcs,
        }
    }
);

sub new {
    my ($proto, $submodule) = @_;

    if ( ! $submodule ) {
        my $o = 0;
        return bless \$o, $proto;
    }

    if ( my $m = $proto->can($submodule) ) {
        return $m->();
    }

    croak "Unknown submodule $submodule\n";
}

sub secretbox {
    return Crypt::NaCl::Sodium::secretbox->new();
}

sub auth {
    return Crypt::NaCl::Sodium::auth->new();
}

sub aead {
    return Crypt::NaCl::Sodium::aead->new();
}

sub box {
    return Crypt::NaCl::Sodium::box->new();
}

sub sign {
    return Crypt::NaCl::Sodium::sign->new();
}

sub generichash {
    return Crypt::NaCl::Sodium::generichash->new();
}

sub shorthash {
    return Crypt::NaCl::Sodium::shorthash->new();
}

sub pwhash {
    return Crypt::NaCl::Sodium::pwhash->new();
}

sub hash {
    return Crypt::NaCl::Sodium::hash->new();
}

sub onetimeauth {
    return Crypt::NaCl::Sodium::onetimeauth->new();
}

sub scalarmult {
    return Crypt::NaCl::Sodium::scalarmult->new();
}

sub stream {
    return Crypt::NaCl::Sodium::stream->new();
}

package
    Data::BytesLocker;

our $DEFAULT_LOCKED = 0;

package
    Crypt::NaCl::Sodium::secretbox;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::auth;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::aead;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::box;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::sign;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::generichash;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::shorthash;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::pwhash;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::hash;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::onetimeauth;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::scalarmult;

sub new { return bless {}, __PACKAGE__ }

package
    Crypt::NaCl::Sodium::stream;

sub new { return bless {}, __PACKAGE__ }


1;

__END__

=encoding utf8

=head1 NAME

Crypt::NaCl::Sodium - NaCl compatible modern, easy-to-use library for encryption, decryption, signatures, password hashing and more

=head1 SYNOPSIS

    use Crypt::NaCl::Sodium qw( :utils );

    my $crypto = Crypt::NaCl::Sodium->new();

    ##########################
    ## Secret-key cryptography

    # Secret-key authenticated encryption (XSalsa20/Poly1305 MAC)
    my $crypto_secretbox = $crypto->secretbox();

    # Secret-key message authentication (HMAC-SHA256, HMAC-SHA512, HMAC-SHA512/256 )
    my $crypto_auth = $crypto->auth();

    # Authenticated Encryption with Additional Data (ChaCha20/Poly1305 MAC, AES256-GCM)
    my $crypto_aead = $crypto->aead();

    ##########################
    ## Public-key cryptography

    # Public-key authenticated encryption (Curve25519/XSalsa20/Poly1305 MAC)
    my $crypto_box = $crypto->box();

    # Public-key signatures (Ed25519)
    my $crypto_sign = $crypto->sign();

    ##########################
    ## Hashing

    # Generic hashing (Blake2b)
    my $crypto_generichash = $crypto->generichash();

    # Short-input hashing (SipHash-2-4)
    my $crypto_shorthash = $crypto->shorthash();

    ##########################
    ## Password hashing (yescrypt)

    my $crypto_pwhash = $crypto->pwhash();

    ##########################
    ## Advanced

    # SHA-2 (SHA-256, SHA-512)
    my $crypto_hash = $crypto->hash();

    # One-time authentication (Poly1305)
    my $crypto_onetimeauth = $crypto->onetimeauth();

    # Diffie-Hellman (Curve25519)
    my $crypto_scalarmult = $crypto->scalarmult();

    # Stream ciphers (XSalsa20, ChaCha20, Salsa20, AES-128-CTR)
    my $crypto_stream = $crypto->stream();

    ##########################
    ## Utilities

    # convert binary data to hexadecimal
    my $hex = bin2hex($bin);

    # convert hexadecimal to binary
    my $bin = hex2bin($hex);

    # constant time comparision of strings
    memcmp($a, $b, $length ) or die '$a ne $b';

    # constant time comparision of large numbers
    compare($x, $y, $length ) == -1 and print '$x < $y';

    # overwrite with null bytes
    memzero($a, $b, ...);

    # generate random number
    my $num = random_number($upper_bound);

    # generate random bytes
    my $bytes = random_bytes($count);

    ##########################
    ## Guarded data storage

    my $locker = Data::BytesLocker->new($password);
    ...
    $locker->unlock();
    print $locker->to_hex();
    $locker->lock();

=head1 DESCRIPTION

L<Crypt::NaCl::Sodium> provides bindings to libsodium - NaCl compatible modern,
easy-to-use library for  encryption, decryption, signatures, password hashing
and more.

It is a portable, cross-compilable, installable, packageable fork
of L<NaCl|http://nacl.cr.yp.to/>, with a compatible API, and an extended API to
improve usability even further.

Its goal is to provide all of the core operations needed to build
higher-level cryptographic tools.

The design choices emphasize security, and "magic constants" have
clear rationales.

And despite the emphasis on high security, primitives are faster
across-the-board than most implementations of the NIST
standards.

L<Crypt::NaCl::Sodium> uses L<Alien::Sodium> that tracks the most current
releases of libsodium.

=head1 METHODS

=head2 new

    my $crypto = Crypt::NaCl::Sodium->new();

Returns a proxy object for methods provided below.

=head2 secretbox

    # Secret-key authenticated encryption (XSalsa20/Poly1305 MAC)
    my $crypto_secretbox = Crypt::NaCl::Sodium->secretbox();

Read L<Crypt::NaCl::Sodium::secretbox> for more details.

=head2 auth

    # Secret-key authentication (HMAC-SHA512/256 and advanced usage of HMAC-SHA-2)
    my $crypto_auth = Crypt::NaCl::Sodium->auth();

Read L<Crypt::NaCl::Sodium::auth> for more details.

=head2 aead

    # Authenticated Encryption with Additional Data (ChaCha20/Poly1305 MAC, AES256-GCM)
    my $crypto_aead = Crypt::NaCl::Sodium->aead();

Read L<Crypt::NaCl::Sodium::aead> for more details.

=head2 box

    # Public-key authenticated encryption (Curve25519/XSalsa20/Poly1305 MAC)
    my $crypto_box = Crypt::NaCl::Sodium->box();

Read L<Crypt::NaCl::Sodium::box> for more details.

=head2 sign

    # Public-key signatures (Ed25519)
    my $crypto_sign = Crypt::NaCl::Sodium->sign();

Read L<Crypt::NaCl::Sodium::sign> for more details.

=head2 generichash

    # Generic hashing (Blake2b)
    my $crypto_generichash = Crypt::NaCl::Sodium->generichash();

Read L<Crypt::NaCl::Sodium::generichash> for more details.

=head2 shorthash

    # Short-input hashing (SipHash-2-4)
    my $crypto_shorthash = Crypt::NaCl::Sodium->shorthash();

Read L<Crypt::NaCl::Sodium::shorthash> for more details.

=head2 pwhash

    # Password hashing (yescrypt)
    my $crypto_pwhash = Crypt::NaCl::Sodium->pwhash();

Read L<Crypt::NaCl::Sodium::pwhash> for more details.

=head2 hash

    # SHA-2 (SHA-256, SHA-512)
    my $crypto_hash = Crypt::NaCl::Sodium->hash();

Read L<Crypt::NaCl::Sodium::hash> for more details.

=head2 onetimeauth

    # One-time authentication (Poly1305)
    my $crypto_onetimeauth = Crypt::NaCl::Sodium->onetimeauth();

Read L<Crypt::NaCl::Sodium::onetimeauth> for more details.

=head2 scalarmult

    # Diffie-Hellman (Curve25519)
    my $crypto_scalarmult = Crypt::NaCl::Sodium->scalarmult();

Read L<Crypt::NaCl::Sodium::scalarmult> for more details.

=head2 stream

    # Stream ciphers (XSalsa20, ChaCha20, Salsa20, AES-128-CTR)
    my $crypto_stream = Crypt::NaCl::Sodium->stream();

Read L<Crypt::NaCl::Sodium::stream> for more details.

=head1 FUNCTIONS

    use Crypt::NaCl::Sodium qw(:utils);

Imports all provided functions.

=head2 bin2hex

    my $hex = bin2hex($bin);

Returns converted C<$bin> into a hexadecimal string.

=head2 hex2bin

    my $hex = "41 : 42 : 43";
    my $bin = hex2bin($hex, ignore => ": ", max_len => 2 );
    print $bin; # AB

Parses a hexadecimal string C<$hex> and converts it to a byte sequence.

Optional arguments:

=over 4

=item * ignore

A string of characters to skip. For example, the string C<": "> allows columns
and spaces to be present at any locations in the hexadecimal string. These
characters will just be ignored.

If unset any non-hexadecimal characters are disallowed.

=item * max_len

The maximum number of bytes to return.

=back

The parser stops when a non-hexadecimal, non-ignored character is
found or when C<max_len> bytes have been written.

=head2 memcmp

    memcmp($a, $b, $length ) or die "\$a ne \$b for length: $length";

Compares strings in constant-time. Returns true if they match, false otherwise.

The argument C<$length> is optional if variables are of the same length. Otherwise it is
required and cannot be greater then the length of the shorter of compared variables.

B<NOTE:> L<Data::BytesLocker/"memcmp"> provides the same functionality.

    $locker->memcmp($b, $length) or die "\$locker ne \$b for length: $length";

=head2 compare

    compare($x, $y, $length ) == -1 and print '$x < $y';

A constant-time version of L</memcmp>, useful to compare nonces and counters
in little-endian format, that plays well with L</increment>.

Returns C<-1> if C<$x> is lower then C<$y>, C<0> if C<$x> and C<$y> are
identical, or C<1> if C<$x> is greater then C<$y>. Both C<$x> and C<$y> are
assumed to be numbers encoded in little-endian format.

The argument C<$length> is optional if variables are of the same length. Otherwise it is
required and cannot be greater then the length of the shorter of compared variables.

B<NOTE:> L<Data::BytesLocker/"compare"> provides the same functionality.

    $locker->compare($y, $length) == -1 and print "\$locker < \$y for length: $length";

=head2 memzero

    memzero($a, $b, ...);

Replaces the value of the provided stringified variables with C<null> bytes. Length of the
zeroed variables is unchanged.

=head2 random_number

    my $num = random_number($upper_bound);

Returns an unpredictable number between 0 and optional C<$upper_bound>
(excluded).
If C<$upper_bound> is not specified the maximum value is C<0xffffffff>
(included).

=head2 increment

    increment($nonce, ...);

B<NOTE:> This function is deprecated and will be removed in next version. Please
use L<Data::BytesLocker/"increment">.

Increments an arbitrary long unsigned number(s) (in place). Function runs in constant-time
for a given length of arguments and considers them to be encoded in
little-endian format.

=head2 random_bytes

    my $bytes = random_bytes($num_of_bytes);

Generates unpredictable sequence of C<$num_of_bytes> bytes.

The length of the C<$bytes> equals the value of C<$num_of_bytes>.

Returns L<Data::BytesLocker> object.

=head2 add

    # equivalent of sodium_add($S, $l, length($l))
    my $x = Crypt::NaCl::Sodium::add($S, $l);

Accepts two integers.  It computes (a + b) mod 2^(8*len) in constant time
for a given length and returns the result.

Returns Integer

=head2 has_aes128ctr

    my $supported = Crypt::NaCl::Sodium::has_aes128ctr()

Checks whether the underlying libsodium supports ASE128CTR

Returns &PL_sv_yes or &PL_sx_no

=head2 sodium_version_string

    my $version = Crypt::NaCl::Sodium::sodium_version_string()

Gets the libsodium version string

Returns a string like "1.0.18"

=head1 VARIABLES

=head2 $Data::BytesLocker::DEFAULT_LOCKED

    use Crypt::NaCl::Sodium;
    $Data::BytesLocker::DEFAULT_LOCKED = 1;

By default all values returned from the provided methods are
unlocked L<Data::BytesLocker> objects. If this variable is set to true then
the returned objects are locked and require calling
L<Data::BytesLocker/"unlock"> before accessing.

=head1 SEE ALSO

=over 4

=item * L<Crypt::NaCl::Sodium::secretbox> - Secret-key authenticated encryption (XSalsa20/Poly1305 MAC)

=item * L<Crypt::NaCl::Sodium::auth> - Secret-key message authentication (HMAC-SHA256, HMAC-SHA512, HMAC-SHA512/256 )

=item * L<Crypt::NaCl::Sodium::aead> - Authenticated Encryption with Additional Data (ChaCha20/Poly1305 MAC, AES256-GCM)

=item * L<Crypt::NaCl::Sodium::box> - Public-key authenticated encryption (Curve25519/XSalsa20/Poly1305 MAC)

=item * L<Crypt::NaCl::Sodium::sign> - Public-key signatures (Ed25519)

=item * L<Crypt::NaCl::Sodium::generichash> - Generic hashing (Blake2b)

=item * L<Crypt::NaCl::Sodium::shorthash> - Short-input hashing (SipHash-2-4)

=item * L<Crypt::NaCl::Sodium::pwhash> - Password hashing (yescrypt)

=item * L<Crypt::NaCl::Sodium::hash> - SHA-2 (SHA-256, SHA-512)

=item * L<Crypt::NaCl::Sodium::onetimeauth> - One-time authentication (Poly1305)

=item * L<Crypt::NaCl::Sodium::scalarmult> - Diffie-Hellman (Curve25519)

=item * L<Crypt::NaCl::Sodium::stream> - Stream ciphers (XSalsa20, ChaCha20, Salsa20, AES-128-CTR)

=item * L<Data::BytesLocker> - guarded data storage

=item * L<libsodium|http://jedisct1.gitbooks.io/libsodium> - libsodium

=back

=head1 AUTHOR

Alex J. G. Burzyński <F<ajgb@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2015 Alex J. G. Burzyński. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
