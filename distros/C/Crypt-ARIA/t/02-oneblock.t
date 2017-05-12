# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-ARIA.t'

#########################

use strict;
use warnings;

use Test::More;
use Crypt::ARIA;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# no key
{
    my $key = '000102030405060708090a0b0c0d0e0f';
    my $plain = '00112233445566778899aabbccddeeff';
    my $expected = 'd718fbd6ab644c739da95f3be6451778';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new();
    my $cipher_pack = $obj->encrypt( $plain_pack );
    is ( $cipher_pack, undef, 'without key' );

    $obj->set_key( pack 'H*', $key );
    $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'after setting key' );

	$obj->unset_key();
    $cipher_pack = $obj->encrypt( $plain_pack );
    is ( $cipher_pack, undef, 'after unsetting key' );
}

# 128 bit key
{
    my $key = '000102030405060708090a0b0c0d0e0f';
    my $plain = '00112233445566778899aabbccddeeff';
    my $expected = 'd718fbd6ab644c739da95f3be6451778';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'encryption with keysize 128' );
}

{
    my $key = '000102030405060708090a0b0c0d0e0f';
    my $cipher = 'd718fbd6ab644c739da95f3be6451778';
    my $expected = '00112233445566778899aabbccddeeff';

    my $cipher_pack = pack 'H*', $cipher;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $plain_pack = $obj->decrypt( $cipher_pack );
    my $plain = unpack 'H*', $plain_pack;
    is ( $plain, $expected, 'decryption with keysize 128' );
}

# 192 bit key
{
    my $key = '000102030405060708090a0b0c0d0e0f1011121314151617';
    my $plain = '00112233445566778899aabbccddeeff';
    my $expected = '26449c1805dbe7aa25a468ce263a9e79';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'encryption with keysize 192' );
}

{
    my $key = '000102030405060708090a0b0c0d0e0f1011121314151617';
    my $cipher = '26449c1805dbe7aa25a468ce263a9e79';
    my $expected = '00112233445566778899aabbccddeeff';

    my $cipher_pack = pack 'H*', $cipher;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $plain_pack = $obj->decrypt( $cipher_pack );
    my $plain = unpack 'H*', $plain_pack;
    is ( $plain, $expected, 'decryption with keysize 192' );
}

# 256 bit key
{
    my $key = '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
    my $plain = '00112233445566778899aabbccddeeff';
    my $expected = 'f92bd7c79fb72e2f2b8f80c1972d24fc';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'encryption with keysize 256' );
}

{
    my $key = '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
    my $cipher = 'f92bd7c79fb72e2f2b8f80c1972d24fc';
    my $expected = '00112233445566778899aabbccddeeff';

    my $cipher_pack = pack 'H*', $cipher;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $plain_pack = $obj->decrypt( $cipher_pack );
    my $plain = unpack 'H*', $plain_pack;
    is ( $plain, $expected, 'decryption with keysize 256' );
}

# recover
{
    my $key = '00112233445566778899aabbccddeeff';
    my $plain = '11111111aaaaaaaa11111111bbbbbbbb';
    my $expected = 'c6ecd08e22c30abdb215cf74e2075e6e';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'test vector. keysize 128' );

    my $decrypt_pack = $obj->decrypt( $cipher_pack );
    my $decrypt = unpack 'H*', $decrypt_pack;
    cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext. keysize 128' );
}

{
    my $key = '000000000000000000000000000000000000000000000000';
    my $plain = '00000000000000000000000000000000';
    my $expected = 'd5526b5e6a1e3df23ad8ecaf20f281d0';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'encryption with keysize 192' );

    my $decrypt_pack = $obj->decrypt( $cipher_pack );
    my $decrypt = unpack 'H*', $decrypt_pack;
    cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext. keysize 192' );
}

{
    my $key = '0000000000000000000000000000000000000000000000000000000000000000';
    my $plain = '00000000000000000000000000000000';
    my $expected = 'c20857dd9106ddde286ec59fa98d77cc';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'encryption with keysize 256' );

    my $decrypt_pack = $obj->decrypt( $cipher_pack );
    my $decrypt = unpack 'H*', $decrypt_pack;
    cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext. keysize 256' );
}

# test vector
{
    my $key = '00112233445566778899aabbccddeeff0011223344556677';
    my $plain = '11111111aaaaaaaa11111111bbbbbbbb';
    my $expected = '8d1470625f59ebacb0e55b534b3e462b';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'test vector. keysize 192' );

    my $decrypt_pack = $obj->decrypt( $cipher_pack );
    my $decrypt = unpack 'H*', $decrypt_pack;
    cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext. keysize 192' );
}

{
    my $key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
    my $plain = '11111111aaaaaaaa11111111bbbbbbbb';
    my $expected = '58a875e6044ad7fffa4f58420f7f442d';

    my $plain_pack = pack 'H*', $plain;
    my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
    my $cipher_pack = $obj->encrypt( $plain_pack );
    my $cipher = unpack 'H*', $cipher_pack;
    is ( $cipher, $expected, 'test vector. keysize 256' );

    my $decrypt_pack = $obj->decrypt( $cipher_pack );
    my $decrypt = unpack 'H*', $decrypt_pack;
    cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext. keysize 256' );
}




done_testing();
