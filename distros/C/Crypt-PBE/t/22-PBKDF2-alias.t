#!perl

use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64 decode_base64);

use_ok('Crypt::PBE::PBKDF2');

use Crypt::PBE::PBKDF2 qw(
    pbkdf2_hmac_sha1
    pbkdf2_hmac_sha1_base64
    pbkdf2_hmac_sha1_hex
    pbkdf2_hmac_sha1_ldap

    pbkdf2_hmac_sha224
    pbkdf2_hmac_sha224_base64
    pbkdf2_hmac_sha224_hex

    pbkdf2_hmac_sha256
    pbkdf2_hmac_sha256_base64
    pbkdf2_hmac_sha256_hex
    pbkdf2_hmac_sha256_ldap

    pbkdf2_hmac_sha384
    pbkdf2_hmac_sha384_base64
    pbkdf2_hmac_sha384_hex

    pbkdf2_hmac_sha512
    pbkdf2_hmac_sha512_base64
    pbkdf2_hmac_sha512_hex
    pbkdf2_hmac_sha512_ldap

    PBKDF2WithHmacSHA1
    PBKDF2WithHmacSHA224
    PBKDF2WithHmacSHA256
    PBKDF2WithHmacSHA384
    PBKDF2WithHmacSHA512
);

my %p = ( password => 'password', salt => 'salt' );

# RAW

cmp_ok( pbkdf2( prf => 'hmac-sha1',   %p ), 'eq', pbkdf2_hmac_sha1(%p),   'pbkdf2_hmac_sha1' );
cmp_ok( pbkdf2( prf => 'hmac-sha224', %p ), 'eq', pbkdf2_hmac_sha224(%p), 'pbkdf2_hmac_sha224' );
cmp_ok( pbkdf2( prf => 'hmac-sha256', %p ), 'eq', pbkdf2_hmac_sha256(%p), 'pbkdf2_hmac_sha256' );
cmp_ok( pbkdf2( prf => 'hmac-sha384', %p ), 'eq', pbkdf2_hmac_sha384(%p), 'pbkdf2_hmac_sha384' );
cmp_ok( pbkdf2( prf => 'hmac-sha512', %p ), 'eq', pbkdf2_hmac_sha512(%p), 'pbkdf2_hmac_sha512' );

# Base64

cmp_ok( pbkdf2_base64( prf => 'hmac-sha1',   %p ), 'eq', pbkdf2_hmac_sha1_base64(%p),   'pbkdf2_hmac_sha1_base64' );
cmp_ok( pbkdf2_base64( prf => 'hmac-sha224', %p ), 'eq', pbkdf2_hmac_sha224_base64(%p), 'pbkdf2_hmac_sha224_base64' );
cmp_ok( pbkdf2_base64( prf => 'hmac-sha256', %p ), 'eq', pbkdf2_hmac_sha256_base64(%p), 'pbkdf2_hmac_sha256_base64' );
cmp_ok( pbkdf2_base64( prf => 'hmac-sha384', %p ), 'eq', pbkdf2_hmac_sha384_base64(%p), 'pbkdf2_hmac_sha384_base64' );
cmp_ok( pbkdf2_base64( prf => 'hmac-sha512', %p ), 'eq', pbkdf2_hmac_sha512_base64(%p), 'pbkdf2_hmac_sha512_base64' );

# HEX format

cmp_ok( pbkdf2_hex( prf => 'hmac-sha1',   %p ), 'eq', pbkdf2_hmac_sha1_hex(%p),   'pbkdf2_hmac_sha1_hex' );
cmp_ok( pbkdf2_hex( prf => 'hmac-sha224', %p ), 'eq', pbkdf2_hmac_sha224_hex(%p), 'pbkdf2_hmac_sha224_hex' );
cmp_ok( pbkdf2_hex( prf => 'hmac-sha256', %p ), 'eq', pbkdf2_hmac_sha256_hex(%p), 'pbkdf2_hmac_sha256_hex' );
cmp_ok( pbkdf2_hex( prf => 'hmac-sha384', %p ), 'eq', pbkdf2_hmac_sha384_hex(%p), 'pbkdf2_hmac_sha384_hex' );
cmp_ok( pbkdf2_hex( prf => 'hmac-sha512', %p ), 'eq', pbkdf2_hmac_sha512_hex(%p), 'pbkdf2_hmac_sha512_hex' );

# LDAP format

cmp_ok( pbkdf2_ldap( prf => 'hmac-sha1',   %p ), 'eq', pbkdf2_hmac_sha1_ldap(%p),   'pbkdf2_hmac_sha1_ldap' );
cmp_ok( pbkdf2_ldap( prf => 'hmac-sha256', %p ), 'eq', pbkdf2_hmac_sha256_ldap(%p), 'pbkdf2_hmac_sha256_ldap' );
cmp_ok( pbkdf2_ldap( prf => 'hmac-sha512', %p ), 'eq', pbkdf2_hmac_sha512_ldap(%p), 'pbkdf2_hmac_sha512_ldap' );

# Java-style

cmp_ok( pbkdf2( prf => 'hmac-sha1',   %p ), 'eq', PBKDF2WithHmacSHA1(%p),   'PBKDF2WithHmacSHA1' );
cmp_ok( pbkdf2( prf => 'hmac-sha224', %p ), 'eq', PBKDF2WithHmacSHA224(%p), 'PBKDF2WithHmacSHA224' );
cmp_ok( pbkdf2( prf => 'hmac-sha256', %p ), 'eq', PBKDF2WithHmacSHA256(%p), 'PBKDF2WithHmacSHA256' );
cmp_ok( pbkdf2( prf => 'hmac-sha384', %p ), 'eq', PBKDF2WithHmacSHA384(%p), 'PBKDF2WithHmacSHA384' );
cmp_ok( pbkdf2( prf => 'hmac-sha512', %p ), 'eq', PBKDF2WithHmacSHA512(%p), 'PBKDF2WithHmacSH512' );

done_testing();
