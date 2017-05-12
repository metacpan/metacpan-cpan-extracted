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

{
	is( Crypt::ARIA->blocksize(),  16, 'blocksize is 16' );
	is( Crypt::ARIA->keysize(),    32, 'keysize is 32' );
	is( Crypt::ARIA->max_keysize(), 32, 'maxkeysize is 32' );
	is( Crypt::ARIA->min_keysize(), 16, 'minkeysize is 16' );
}

{
    my $obj = Crypt::ARIA->new();
    is( ref($obj), 'Crypt::ARIA', "creating new object" );
}

{
    eval { my $obj = Crypt::ARIA->new( '12345' ) };
    isnt( $@, '', 'Invalid keysize with new()' );
}

{
    my $obj;
    eval { $obj = Crypt::ARIA->new( pack('H*', '000102030405060708090a0b0c0d0e0f') ) };
    is( $@, '', "Valid keysize - 128" );
    eval { $obj = Crypt::ARIA->new( pack('H*', '000102030405060708090a0b0c0d0e0f0001020304050607') ) };
    is( $@, '', "Valid keysize - 192" );
    eval { $obj = Crypt::ARIA->new( pack('H*', '000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f') ) };
    is( $@, '', "Valid keysize - 256" );
}

{
    my $obj = Crypt::ARIA->new();
    my $key = "00112233 44556677 8899aabb ccddeeff 00112233 44556677";
    eval { $obj->set_key_hexstring( $key ) };
    is( $@, '', "set_key_hexstring() : valid keysize" );
}

{
    my $obj = Crypt::ARIA->new();
    my $key = pack('H*', "00112233445566778899aabbccddeeff");
	my $keylen = 8 * length $key;
    $obj->set_key( $key );

	my $ret;
	$ret = Crypt::ARIA::_crypt( pack('H*', '00112233445566778899aabbccddeeff' ), $obj->{enc_round}, $obj->{enc_roundkey} );
	ok( defined $ret, '16 byte data' );
	$ret = Crypt::ARIA::_crypt( pack('H*', '00112233445566778899aabbccddee' ), $obj->{enc_round}, $obj->{enc_roundkey} );
	ok( ! defined $ret, '15 byte data' );
	$ret = Crypt::ARIA::_crypt( pack('H*', '00112233445566778899aabbccddeeff00' ), $obj->{enc_round}, $obj->{enc_roundkey} );
	ok( ! defined $ret, '17 byte data' );
}




done_testing();
