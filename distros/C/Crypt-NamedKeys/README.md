# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-Crypt-NamedKeys.svg?branch=master)](https://travis-ci.org/binary-com/perl-Crypt-NamedKeys)
[![codecov](https://codecov.io/gh/binary-com/perl-Crypt-NamedKeys/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Crypt-NamedKeys)

Crypt::NamedKeys - A Crypt::CBC wrapper with key rotation support

# SYNOPSYS

    use Crypt::NamedKeys;
    my $crypt = Crypt::NamedKeys->new(keyname => 'href');
    my $encrypted = $crypt->encrypt_data(data => $href);
    my $restored_href = $crypt->decrypt_data(
        data => $encrypted->{data},
        mac  => $encrypted->{mac},
    );

# DESCRIPTION

This module provides functions to serialize data for transfer via non-protected
channels with encryption and data integrity protection.  The module tracks key
number used to encrypt information so that keys can be rotated without making
data unreadable.

# CONFIGURATION AND KEY ROTATION

The keys are stored in the keyfile, configurable as below.  Keys are numbered 
starting at 1.  Numbers must never be reused.  Typically key rotation will be 
done in several steps, each with its own rollout.  These steps MUST be done as 
separate releases because otherwise keys may not be available to decrypt data, 
and so things may not work.

## keyfile location

The keyfile can be set using the keyfile($path) function.  There is no default.

## keyfile format

The format of the keyfile is YAML, following a basic structure of

    keyname:
       [keyhashdef]

so for example:

    cryptedfeed:
       default_keynum: 9
       none: queith7eeTh0teejaichoodobooX9ceechee9Sai9gauChiengaeraew3aDiehei
       1: aePh8ahBaNg1bee6ohj3er5cuzeepoophai1oogohpoixothah4AuYiongu4ahta
       2: oht1eep8uxoo1eeshaSaemee9aem5chahqueu0Aedaa7eeXae9aeghe5umoNah6a
       3: chigh4veifoofe0Vohphee4ohkaef9giz2iaje2ahF4ohboSh6ifaiNgohwohchi
       4: Ahphahmisaingo5Ietheangeegi5ia1uuF9taerooShaitoh1Eophig3ohziejet
       5: oe5wi2equee6FeiZohjah2peas6Ahquohniefeimai0beip2waxeizoo1OhthohN
       6: eigaezee3CeuC8phae4giph6Miqu6piy3Eideipahticesheij7se9eecai9fiez
       7: DuuGhohViGh0Sheihahr6ce4Phuin7ahpaiSa5jaiphie3eiz8oa3dohrohghuow
       8: ahfoniemah4boemeN8seJ7hohhualeetei7aegohhai5ohwahlohnah2Ee2Ewal1
       9: Ceixei4shelohxee1ohdoochuliebael1kae8eit0Geeth1so9fohZi0cohs8go4
       10: boreiDe0shueNgie7shai7ooc1yaeveiKeihuox0xahp1hai8phe7aephiel2oob

In general we assume key spefications to use numeric keys within the named 
key hash.  This makes key rotation a lot easier and prevents reusing key 
numbers.

Key names may not contain = or -.

All keys listed can be used for decryption (with the special 'none' key used if
no key number is specified in the cyphertex), but by default only the default 
keynumber (default\_keynum, in this case 9) is used for encrypting.

The keynumber is specified in the resulting cyphertext so we know which key 
to use for decrypting the cyphertext even if we don't try to decrypt it.  This
allows:

- Key checking

    If you store cyphertext in your rdbms, you can check which keys are used before 
    you remove decryption support for a key.

- Orderly key rotation

    You can add a key, and later depricate it, managing the transition (and perhaps
    even using logging to know when the old key is no longer needed).

## Step 1:  Adding a New Key

In many cases you need to be able to add and remove keys without requiring that
everything gets the new keys at the same time.  For example if you have multiple
production systems, they are likely to get updated in series, and if you expect
that everyone gets the keys at the same time, timing issues may occur.

For this reason, we recommend breaking up the encryption key rollout into a
number of steps.  The first one is making sure that everyone can use the
new key to decrypt before anyone uses it to encrypt.

The first release is by adding a new key so that it is available for decryption.

For example, in the keyfile suppose one has:

    mykey:
      default_keynum: 1
      none: rsdfagtiaueIUPOIUYHH
      1: rsdfagtiaueIUPOIUYHH

We might add another line

    2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

Once this file is released, the key number 2 will be available globally for
decryption purposes, but everything will still be encrypted using key number 1.

This means it is safe then to go onto the second step.

## Step 2:  Setting the new key as default

Once the new keys have been released, the next step is to change the default 
keynumber.  Data encrypted in this way will be available even to servers waiting
to be updated because the keys have previously been rolled out.  To do this,
simply change the default\_keynum:

    mykey:
      default_keynum: 1
      1: rsdfagtiaueIUPOIUYHH
      2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

becomes:

    mykey:
      default_keynum: 2
      1: rsdfagtiaueIUPOIUYHH
      2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

Now all new data will be encrypted using keynumber 2.

## Step 3:  Retiring the old key

Once the old key is no longer being used, it can be retired by deleting the 
row.

## The Special 'none' keynum

For aes keys before the key versioning was introduced, there is no keynum 
associated with the cyphertext, so we use this key.

# CONFIGURATION PARAMETERS

## $Crypt::NamedKeys::Escape\_Eq;

Set to true, using local or not, if you want to encode with - instead of =

Note that on decryption both are handled.

# PROPERTIES

## keynum

Defaults to the default keynumber specified in the keyfile (for encryption)

## keyname

The name of the key in the keyfile.

# METHODS AND FUNCTIONS

## Crypt::NamedKeys->keyfile($path)

Can also be called as Crypt::NamedKeys::keyfile($path)

Sets the path of the keyfile.  It does not load or reload it (that is done on
demand or by reload\_keyfile() below

## reload\_keyhash

Can be called as an object method or function (i.e. 
Crypt::NamedKeys::reload\_keyhash()

Loads or reloads the keyfile.  Can be used via event handlers to reload
confguration as needed

## $self->encrypt\_data(data => $data)

Serialize _$data_ to JSON, encrypt it, and encode as base64. Also compute HMAC
code for the encrypted data. Returns hash reference with 'data' and 'mac'
elements.

Args include

- data

    Data structure reference to be encrypted

- cypher

    Cypher to use (default: Rijndael)

## $self->decrypt\_data(data => $data, mac => $mac)

Decrypt data encrypted using _encrypt\_data_. First checks HMAC code for data.
If data was not tampered, decrypts it and decodes from JSON. Returns data, or
undef if decryption failed.

## $self->encrypt\_payload(data  => $data)

Encrypts data using _encrypt\_data_ and returns result as a string including 
both cyphertext and hmac in base-64 format.  This can work on arbitrary data
structures, scalars, and references provided that the data can be serialized
as an attribute on a JSON document.

## $self->decrypt\_payload(value => $value)

Accepts payload encrypted with _encrypt\_payload_, checks HMAC and decrypts
the value. Returns decripted value or undef if check or decryption has failed.
