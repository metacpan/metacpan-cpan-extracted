# NAME

Data::Tools::Crypto - authenticated symmetric and hybrid RSA encryption and signatures, one common API

# SYNOPSIS

    # Data::Tools::Crypto is the base class, it is never used on its own,
    # use one of the implementations which inherit it:

    use Data::Tools::Crypto::Symmetric;
    use Data::Tools::Crypto::RSA;

    my $crypto = Data::Tools::Crypto::Symmetric->new( $key );

    # --------------------------------------------------------------------------

    # raw binary data in, raw binary data out

    my $ctext = $crypto->encrypt( $ptext );
    my $ptext = $crypto->decrypt( $ctext );

    # --------------------------------------------------------------------------

    # the same, in text-safe encodings

    my $hex   = $crypto->encrypt_hex( $ptext );
    my $ptext = $crypto->decrypt_hex( $hex   );

    my $b64   = $crypto->encrypt_base64( $ptext );
    my $ptext = $crypto->decrypt_base64( $b64   );

    my $b64u  = $crypto->encrypt_base64url( $ptext );
    my $ptext = $crypto->decrypt_base64url( $b64u  );

    # --------------------------------------------------------------------------

    # any perl data structure, JSON-serialised and encrypted in one step

    my $data  = { name => 'test', list => [ 1, 2, 3 ] };

    my $sealed = $crypto->freeze( $data   );
    my $data   = $crypto->thaw(   $sealed );

    my $sealed = $crypto->freeze_hex(       $data   );
    my $sealed = $crypto->freeze_base64(    $data   );
    my $sealed = $crypto->freeze_base64url( $data   );

    # --------------------------------------------------------------------------

# DESCRIPTION

Data::Tools::Crypto provides authenticated encryption, hybrid public key
encryption and digital signatures, with a single common API:

    * Data::Tools::Crypto::Symmetric -- shared secret key, ChaCha20-Poly1305
    * Data::Tools::Crypto::RSA       -- public/private key pair, hybrid, signatures

This module is the base class of both. It implements no encryption of its own,
it defines the API which every implementation offers and provides the encoding
and serialisation wrappers on top of the encrypt() and decrypt() methods that
the inheriting module must provide.

Errors behave exactly as in the inheriting module, since every method here
goes through its encrypt() or decrypt(): caller errors raise an exception,
and data which does not decrypt makes decrypt\_\*() and thaw\*() return undef.

The base class is not usable by itself and has nothing to export, always use
one of the implementations listed above.

freeze/thaw use JSON as a safer option than Storable, so only plain data can
be carried: hashes, arrays, scalars and numbers. Blessed objects, code
references and circular structures cannot be serialised.

# METHODS

## encrypt( $plaintext ), decrypt( $cryptotext )

Implemented by the inheriting module, not by the base class. All the methods below are
built on top of these two.

## encrypt\_hex( $plaintext ), decrypt\_hex( $cryptotext )

As encrypt()/decrypt() but the cryptotext is HEX encoded, so it is plain text
and safe to store or pass anywhere a binary string would not survive.

## encrypt\_base64( $plaintext ), decrypt\_base64( $cryptotext )

As encrypt()/decrypt() but the cryptotext is BASE64 encoded, on a single line
with no newlines added.

## encrypt\_base64url( $plaintext ), decrypt\_base64url( $cryptotext )

As encrypt\_base64() but using the URL and filename safe BASE64 alphabet, so
the result can be used in a URL or a file name without further escaping.

## freeze( $data\_ref ), thaw( $cryptotext )

freeze() serialises any plain perl data structure to JSON and encrypts it.
thaw() reverses this and returns the data structure back, or undef if the
cryptotext cannot be decrypted, exactly as decrypt() does.

## freeze\_hex(), freeze\_base64(), freeze\_base64url() and their thaw pairs

As freeze()/thaw() but with the cryptotext encoded as described above:

    my $sealed = $crypto->freeze_hex( $data_ref );
    my $data   = $crypto->thaw_hex(   $sealed   );

# REQUIRED MODULES

Data::Tools::Crypto uses:

    * Data::Tools
    * JSON
    * MIME::Base64

# GITHUB REPOSITORY

    https://github.com/cade-vs/perl-data-tools-crypto

    git clone https://github.com/cade-vs/perl-data-tools-crypto.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

Data::Tools::Crypto::Symmetric - authenticated symmetric encryption with a shared secret key

# SYNOPSIS

    use Data::Tools::Crypto::Symmetric;
    use Crypt::PRNG;
    use Exception::Sink;

    # the key is 32 raw bytes, not a passphrase

    my $key    = Crypt::PRNG::random_bytes( 32 );
    my $crypto = Data::Tools::Crypto::Symmetric->new( $key );

    # --------------------------------------------------------------------------

    my $ctext = $crypto->encrypt( $ptext );
    my $ptext = $crypto->decrypt( $ctext );

    boom( "data cannot be decrypted" ) unless defined $ptext;

    # --------------------------------------------------------------------------

    # the whole encoding and freeze/thaw API comes from
    # Data::Tools::Crypto, see there for the full list

    my $sealed = $crypto->freeze_base64url( { name => 'test' } );
    my $data   = $crypto->thaw_base64url( $sealed );

    # --------------------------------------------------------------------------

    # a new key can be set on an existing object

    $crypto->reinit( $another_key );

    # --------------------------------------------------------------------------

# DESCRIPTION

Data::Tools::Crypto::Symmetric encrypts with ChaCha20-Poly1305, which is
authenticated: cryptotext which has been modified in any way will not decrypt
at all, rather than decrypting to wrong data. A fresh random nonce is used for
every message, so encrypting the same plaintext twice never gives the same
cryptotext.

Both sides need the same secret key. If there is no way to share one, use
Data::Tools::Crypto::RSA instead.

# METHODS

## new( $key )

Returns a new object. $key must be exactly 32 raw bytes, undef or an empty
key is refused. A key which perl
holds as characters is accepted if it can be represented as bytes, and is
converted, otherwise it is rejected -- 32 characters are not always 32 bytes.

There are no options yet. Unknown options are refused rather than silently
ignored.

## reinit( $key )

Sets a new key on an existing object. All previous state is cleared first, so
if the key or an option is rejected the object is left without a key and is
not usable until a later reinit() succeeds. Catching the exception and
handling the unusable object is left to the caller.

## encrypt( $plaintext )

Returns the cryptotext, which is always binary. There is no limit on the size
of the plaintext, the cryptotext is 29 bytes longer than the plaintext.

## decrypt( $cryptotext )

Returns the plaintext, or undef if the cryptotext cannot be decrypted, which
covers a wrong key, modified data, truncated data and random input alike.
There is deliberately no more detail than that: telling these cases apart
would help an attacker more than a caller.

# UTF8 HANDLING

encrypt()/decrypt() are transparent. Whatever goes in comes back out, with
the same value, the same length and in the same form. A byte string returns as
a byte string and a character string returns as a character string, which are
not the same thing in perl even when they print identically:

    my $chars = "caf\x{e9}";             # 4 characters
    my $bytes = "caf\xc3\xa9";           # 5 bytes, the utf8 encoding of it

    $crypto->decrypt( $crypto->encrypt( $chars ) );  # 4 characters back
    $crypto->decrypt( $crypto->encrypt( $bytes ) );  # 5 bytes back

Cryptotext is always binary. Passing a character string to decrypt() is a
mistake and raises an exception, rather than being silently mangled.

# ERRORS

The two kinds of failure are reported differently and never confused:

    * a caller or configuration error raises an exception with boom(), i.e. a
      missing, empty or wrong sized key, an unknown option, an undefined
      argument, a character string where binary data is required, or any use
      of an object whose reinit() failed

    * data which simply does not decrypt returns undef, which is a normal
      result the caller is expected to check

# DATA FORMAT

    nonce (12 bytes) . cryptotext . authentication tag (16 bytes)

The plaintext carries one leading marker byte, 'b' for binary or 'u' for a
character string, which is what makes the utf8 handling above transparent.
This accounts for the 29 bytes of overhead.

# REQUIRED MODULES

Data::Tools::Crypto::Symmetric uses:

    * Data::Tools::Crypto
    * Crypt::AuthEnc::ChaCha20Poly1305 (CryptX)
    * Crypt::PRNG (CryptX)
    * Encode
    * Exception::Sink

# GITHUB REPOSITORY

    https://github.com/cade-vs/perl-data-tools-crypto

    git clone https://github.com/cade-vs/perl-data-tools-crypto.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

Data::Tools::Crypto::RSA - hybrid public key encryption and digital signatures with an RSA key pair

# SYNOPSIS

    use Data::Tools qw( file_text_load );
    use Data::Tools::Crypto::RSA;
    use Exception::Sink;

    # the key is always the PEM text itself, never a file name

    my $pem    = file_text_load( 'private.pem' );
    my $crypto = Data::Tools::Crypto::RSA->new( $pem );

    # --------------------------------------------------------------------------

    # anyone with the public key can encrypt, only the private key can decrypt

    my $ctext = $crypto->encrypt( $ptext );
    my $ptext = $crypto->decrypt( $ctext );

    boom( "data cannot be decrypted" ) unless defined $ptext;

    # --------------------------------------------------------------------------

    # only the private key can sign, anyone with the public key can verify

    my $sig = $crypto->sign( $message );

    boom( "message is not authentic" ) unless $crypto->verify( $message, $sig );

    # the same, with the signature in text-safe encodings

    my $sig_hex  = $crypto->sign_hex( $message );
    my $sig_b64  = $crypto->sign_base64( $message );
    my $sig_b64u = $crypto->sign_base64url( $message );

    boom( "message is not authentic" ) unless $crypto->verify_base64url( $message, $sig_b64u );

    # --------------------------------------------------------------------------

    # a different hash can be selected, it applies to both wrapping and signing

    my $crypto = Data::Tools::Crypto::RSA->new( $pem, HASH => 'SHA512' );

    # --------------------------------------------------------------------------

    # the whole encoding and freeze/thaw API comes from
    # Data::Tools::Crypto, see there for the full list

    my $sealed = $crypto->freeze_base64url( { name => 'test' } );
    my $data   = $crypto->thaw_base64url( $sealed );

    # --------------------------------------------------------------------------

# DESCRIPTION

Data::Tools::Crypto::RSA encrypts with RSA-OAEP and signs with RSA-PSS.

Encryption is hybrid. RSA by itself can only encrypt a few hundred bytes, so
it is not used on the data at all: a fresh symmetric key is generated for each
message, the message is encrypted with Data::Tools::Crypto::Symmetric and only
that key is wrapped with RSA. There is no limit on the size of the data, and
the payload is authenticated exactly as it is there.

# PUBLIC AND PRIVATE KEYS

A private key contains the public key, so an object holding a private key can
do everything. A public key can only do the two public operations:

                      private key    public key
    encrypt()             yes           yes
    verify()              yes           yes
    decrypt()             yes           no
    sign()                yes           no

This is why a service which only sends encrypted data, or only verifies
signatures, should be given the public key alone -- it works exactly the same
and the private key never reaches that host.

Asking a public key object to decrypt() or sign() is a configuration error,
not a data error, and raises an exception saying so.

# SIGNATURES

Encryption does not prove who sent anything. Anyone holding the public key can
produce a well formed message, because that is precisely what the public key
is for. Only sign()/verify() establish origin, and they are independent of the
encrypt/decrypt pair -- use both when both properties are needed.

# METHODS

## new( $pem\_text, %options )

Returns a new object. $pem\_text is the PEM text of a public or a private key.
It is never taken for a file name, reading a key from a file is left to the
calling code. Options:

    HASH => 'SHA256'   hash for OAEP wrapping and PSS signatures, default SHA256

Unknown options are refused rather than silently ignored, as is a key too
small to be usable -- see KEY SIZE below.

## reinit( $pem\_text, %options )

Sets a new key on an existing object. All previous state is cleared first, so
if the key or an option is rejected the object is left without a key and is
not usable until a later reinit() succeeds. Catching the exception and
handling the unusable object is left to the caller.

## encrypt( $plaintext )

Returns the cryptotext, which is always binary. There is no limit on the size
of the plaintext, the cryptotext is the key modulus size plus 29 bytes longer
than the plaintext.

## decrypt( $cryptotext )

Returns the plaintext, or undef if the cryptotext cannot be decrypted, which
covers a wrong key, modified data, truncated data and random input alike.
Raises an exception if the object holds a public key.

## sign( $message )

Returns an RSA-PSS signature, which is always binary and is the key modulus
size. Raises an exception if the object holds a public key.

## verify( $message, $signature )

Returns true if the signature was made over this exact message by the private
key matching this object's key, false otherwise. An unusable or malformed
signature is simply false, it does not raise an exception.

## sign\_hex(), sign\_base64(), sign\_base64url() and their verify pairs

As sign()/verify() but with the signature HEX, BASE64 or URL-safe BASE64
encoded, so it can be stored or passed as plain text. BASE64 is on a single
line with no newlines added. Only the signature is encoded, the message is
signed and verified exactly as with sign()/verify():

    my $sig = $crypto->sign_hex( $message );
    my $ok  = $crypto->verify_hex( $message, $sig );

An encoded signature which does not decode to a valid signature is simply
false, as in verify().

## is\_private()

True if the object holds a private key, so the caller can tell in advance
whether decrypt() and sign() are available to it. Like every other method it
raises an exception on an object whose reinit() failed, rather than answering
false.

# KEY SIZE

OAEP can carry keysize minus twice the hash size minus two bytes, and that
must fit the 32 byte symmetric key, so the key modulus must be at least

    32 + 2 * hash size + 2 bytes

PSS signatures need less than that, so the OAEP limit is the one which
decides. The minimum key size for each HASH option:

    HASH               hash size   min modulus            smallest usual key
    SHA1                20 bytes    74 bytes ( 592 bits)   1024 bits
    SHA224              28 bytes    90 bytes ( 720 bits)   1024 bits
    SHA256 (default)    32 bytes    98 bytes ( 784 bits)   1024 bits
    SHA3_256            32 bytes    98 bytes ( 784 bits)   1024 bits
    SHA384              48 bytes   130 bytes (1040 bits)   1536 bits
    SHA512              64 bytes   162 bytes (1296 bits)   1536 bits
    SHA3_512            64 bytes   162 bytes (1296 bits)   1536 bits

So a 1024 bit key works with SHA256 but is refused with SHA384 or SHA512.
A key too small for the chosen hash is refused when it is loaded, rather than
failing on every encrypt() later.

These are the smallest keys which work at all, not a recommendation: 1024 bit
RSA is no longer considered secure, use 2048 bits or more.

# UTF8 HANDLING

encrypt()/decrypt() are transparent, exactly as described in
Data::Tools::Crypto::Symmetric, which does the work.

sign()/verify() cover the same distinction, so a character string and its utf8
byte form do not share a signature. Signatures are always binary, passing a
character string to verify() raises an exception.

# ERRORS

The two kinds of failure are reported differently and never confused:

    * a caller or configuration error raises an exception with boom(), i.e. a
      key given as a reference instead of PEM text, malformed or unsupported
      key material, a key too small, an invalid
      or unknown hash, an unknown option, an undefined argument, a private
      operation on a public key, or any use of an object whose reinit() failed

    * data which simply does not decrypt or verify returns undef from decrypt()
      and false from verify(), which are normal results the caller must check

# DATA FORMAT

    RSA wrapped symmetric key (key modulus size) . Crypto::Symmetric cryptotext

# REQUIRED MODULES

Data::Tools::Crypto::RSA uses:

    * Data::Tools::Crypto
    * Data::Tools::Crypto::Symmetric
    * Crypt::PK::RSA (CryptX)
    * Crypt::Digest (CryptX)
    * Crypt::PRNG (CryptX)
    * Data::Tools
    * Encode
    * Exception::Sink
    * MIME::Base64

# GITHUB REPOSITORY

    https://github.com/cade-vs/perl-data-tools-crypto

    git clone https://github.com/cade-vs/perl-data-tools-crypto.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
