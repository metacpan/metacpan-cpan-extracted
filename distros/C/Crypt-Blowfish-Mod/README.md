# NAME

Crypt::Blowfish::Mod - Another Blowfish Algorithm

# VERSION

version 0.05

# SYNOPSIS

    use Crypt::Blowfish::Mod;

    my $cipher = new Crypt::Blowfish::Mod $key;
    my $ciphertext = $cipher->encrypt($plaintext);
    $plaintext = $cipher->decrypt($ciphertext);

# DESCRIPTION

Crypt::Blowfish::Mod implements the Blowfish algorithm using functions adapted from examples from Bruce Schneier
and other authors.

Crypt::Blowfish::Mod has an interface similar to [Crypt::Blowfish](https://metacpan.org/pod/Crypt::Blowfish), but produces different results. This module
is endianness sensitive, making sure that it gives the same encription/decription results in different architectures.

Also, this module accepts variable length keys up to 256 bytes. By default, it assumes the `key` is a Base64
string. And all text encrypted or decrypted is also in Base64.

# METHODS

## new

Usage:

    ## the key should be base64
    my $b = Crypt::Blowfish::Mod->new('YaKjsKjY0+');

    ## same as before:
    my $b = Crypt::Blowfish::Mod->new( key => 'YaKjsKjY0+');

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

## encrypt

Returns a encrypted string encoded in Base64.

## decrypt

Decodes a base64 encoded blowfish encrypted string.

## encrypt\_raw

Returns a raw encrypted string.

## decrypt\_raw

Decodes a raw encoded blowfish encrypted string.

## encrypt\_legacy

This is the legacy `encrypt` method, which behaves like `encrypt()` in
version `0.04` and earlier.

Before `0.05` encryption was performed by the XS module using C's signed
chars. This is a bug that prevented utf-8 strings from being decrypted.
This bug was solved in `0.05`.

So, if you updated to version `0.05` or greater and still need to encrypt data
as the old version did, use this method.

    # works fine

    my $enc = $b->encrypt_legacy( 'secret text' );
    my $dec = $b->decrypt( $enc );
    is( $enc, $dec );

    # fails!

    my $str = 'déjà-vu';
    my $enc = $b->encrypt_legacy( $str );
    my $dec = $b->decrypt( $enc );
    is( $str, $dec );  # not!

## b\_encrypt( Str $text, Str $key, Bool is\_big\_endian, Bool is\_signed )

Raw C decrypt function.

## b\_decrypt( Str $text, Str $key, Bool is\_big\_endian, Bool is\_signed )

Raw C decrypt function.

# NOTES

The Blowfish algorithm is highly dependent on the endianness of your architecture.
This module attempts to detect the correct endianness for your architecture, otherwise
it will most likely default to little-endian.

You may override this behavior by setting the endianness on instantiation:

    # force little-endian
    my $b = Crypt::Blowfish::Mod->new( key=>'YaKjsKjY0./', endianness=>'little' );

Intel-based architectures are typically Little-Endian.

# BREAKING CHANGES

Version 0.05 contains breaking changes.

Previous to version `0.05` any strings containing utf-8 or extended ascii
characters were not encrypted correctly.

If you were storing encrypted utf8 strings but not decrypting them with earlier
versions (`0.04` or before), if you try to compare the output of the older
encrypt() and the current (fixed) encrypt() method the result will not match!
They do match fine if no utf8 or extended ascii codes were in the string being
encrypted. This may be a problem if you were storing encrypted data, then
comparing them to validate, authenticate, etc.

Use `encrypt_legacy()` if you still need to encrypt data that outputs strings
that match the old algorithm.

# SEE ALSO

[Crypt::Blowfish](https://metacpan.org/pod/Crypt::Blowfish)

[Crypt::OpenSSL::Blowfish](https://metacpan.org/pod/Crypt::OpenSSL::Blowfish)

This algorithm has been implemented in other languages:

http://www.schneier.com/blowfish-download.html

# AUTHOR

Rodrigo de Oliveira
