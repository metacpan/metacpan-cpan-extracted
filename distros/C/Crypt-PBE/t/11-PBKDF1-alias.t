#!perl

use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);

use Crypt::PBE::PBKDF1 qw(
    pbkdf1_md2
    pbkdf1_md2_base64
    pbkdf1_md2_hex

    pbkdf1_md5
    pbkdf1_md5_base64
    pbkdf1_md5_hex

    pbkdf1_sha1
    pbkdf1_sha1_base64
    pbkdf1_sha1_hex
);

my %params = (
    password => 'password',
    salt     => 'salt',
    count    => 1_000
);

cmp_ok( encode_base64( pbkdf1_sha1(%params), '' ), 'eq', pbkdf1_sha1_base64(%params), 'PBKDF1 with SHA1' );
cmp_ok( encode_base64( pbkdf1_md5(%params),  '' ), 'eq', pbkdf1_md5_base64(%params),  'PBKDF1 with MD5' );
cmp_ok( encode_base64( pbkdf1_md2(%params),  '' ), 'eq', pbkdf1_md2_base64(%params),  'PBKDF1 with MD2' );

cmp_ok( pbkdf1_sha1_base64(%params), 'eq', 'So/UjkJu0IG1Nb5XaYkvo5YpPvs=', 'PBKDF1 with SHA1 in Base64' );
cmp_ok( pbkdf1_md5_base64(%params),  'eq', 'hHXGqFMaXSfjhs1JZFeBLA==',     'PBKDF1 with MD5 in Base64' );
cmp_ok( pbkdf1_md2_base64(%params),  'eq', '2gKWHr1EhMMfQOqB7sFK/w==',     'PBKDF1 with MD2 in Base64' );

cmp_ok( pbkdf1_sha1_hex(%params), 'eq', '4a8fd48e426ed081b535be5769892fa396293efb', 'PBKDF1 with SHA1 in Hex' );
cmp_ok( pbkdf1_md5_hex(%params),  'eq', '8475c6a8531a5d27e386cd496457812c',         'PBKDF1 with MD5 in Hex' );
cmp_ok( pbkdf1_md2_hex(%params),  'eq', 'da02961ebd4484c31f40ea81eec14aff',         'PBKDF1 with MD2 in Hex' );

done_testing();
