# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-ARIA.t'

#########################

use strict;
use warnings;

use Test::More;
use Crypt::ARIA;

#########################

SKIP: {
	eval { require Crypt::CBC; Crypt::CBC->VERSION(2.31); 1 };

	skip "Crypt::CBC >= 2.31 not installed", 8 if $@;

# CBC
{

	my $key = '00112233445566778899aabbccddeeff';
	my $iv  = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

	my $plain = <<'END';
11 11 11 11 aa aa aa aa 11 11 11 11 bb bb bb bb
11 11 11 11 cc cc cc cc 11 11 11 11 dd dd dd dd
22 22 22 22 aa aa aa aa 22 22 22 22 bb bb bb bb
22 22 22 22 cc cc cc cc 22 22 22 22 dd dd dd dd
33 33 33 33 aa aa aa aa 33 33 33 33 bb bb bb bb
33 33 33 33 cc cc cc cc 33 33 33 33 dd dd dd dd
44 44 44 44 aa aa aa aa 44 44 44 44 bb bb bb bb
44 44 44 44 cc cc cc cc 44 44 44 44 dd dd dd dd
55 55 55 55 aa aa aa aa 55 55 55 55 bb bb bb bb
55 55 55 55 cc cc cc cc 55 55 55 55 dd dd dd dd
END
	$plain =~ s/\s+//g;

	my $expected = <<'END';
49 d6 18 60 b1 49 09 10 9c ef 0d 22 a9 26 81 34
fa df 9f b2 31 51 e9 64 5f ba 75 01 8b db 15 38
b5 33 34 63 4b bf 7d 4c d4 b5 37 70 33 06 0c 15
5f e3 94 8c a7 5d e1 03 1e 1d 85 61 9e 0a d6 1e
b4 19 a8 66 b3 c2 db fd 10 a4 ed 18 b2 21 49 f7
58 97 f0 b8 66 8b 0c 1c 54 2c 68 77 78 83 5f b7
cd 46 e4 5f 85 ea a7 07 24 37 dd 9f a6 79 3d 6f
8d 4c ce fc 4e b1 ac 64 1a c1 bd 30 b1 8c 6d 64
c4 9b ca 13 7e b2 1c 2e 04 da 62 71 2c a2 b4 f5
40 c5 71 12 c3 87 91 85 2c fa c7 a5 d1 9e d8 3a
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );

	my $cbc = Crypt::CBC->new(-cipher => $obj,
							  -iv => pack('H*', $iv),
							  -header => 'none',
							  -padding => 'none',
						     );

	my $cipher_pack = $cbc->encrypt( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with CBC mode. keysize 128' );

	my $decrypt_pack = $cbc->decrypt( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with CBC mode. keysize 128' );
}

{
	my $key = '00112233445566778899aabbccddeeff0011223344556677';
	my $iv  = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

	my $plain = <<'END';
11 11 11 11 aa aa aa aa 11 11 11 11 bb bb bb bb
11 11 11 11 cc cc cc cc 11 11 11 11 dd dd dd dd
22 22 22 22 aa aa aa aa 22 22 22 22 bb bb bb bb
22 22 22 22 cc cc cc cc 22 22 22 22 dd dd dd dd
33 33 33 33 aa aa aa aa 33 33 33 33 bb bb bb bb
33 33 33 33 cc cc cc cc 33 33 33 33 dd dd dd dd
44 44 44 44 aa aa aa aa 44 44 44 44 bb bb bb bb
44 44 44 44 cc cc cc cc 44 44 44 44 dd dd dd dd
55 55 55 55 aa aa aa aa 55 55 55 55 bb bb bb bb
55 55 55 55 cc cc cc cc 55 55 55 55 dd dd dd dd
END
	$plain =~ s/\s+//g;

	my $expected = <<'END';
af e6 cf 23 97 4b 53 3c 67 2a 82 62 64 ea 78 5f
4e 4f 7f 78 0d c7 f3 f1 e0 96 2b 80 90 23 86 d5
14 e9 c3 e7 72 59 de 92 dd 11 02 ff ab 08 6c 1e
a5 2a 71 26 0d b5 92 0a 83 29 5c 25 32 0e 42 11
47 ca 45 d5 32 f3 27 b8 56 ea 94 7c d2 19 6a e2
e0 40 82 65 48 b4 c8 91 b0 ed 0c a6 e7 14 db c4
63 19 98 d5 48 11 0d 66 6b 3d 54 c2 a0 91 95 5c
6f 05 be b4 f6 23 09 36 86 96 c9 79 1f c4 c5 51
56 4a 26 37 f1 94 34 6e c4 5f bc a6 c7 2a 5b 46
12 e2 08 d5 31 d6 c3 4c c5 c6 4e ac 6b d0 cf 8c
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );

	my $cbc = Crypt::CBC->new(-cipher => $obj,
							  -iv => pack('H*', $iv),
							  -header => 'none',
							  -padding => 'none',
						     );

	my $cipher_pack = $cbc->encrypt( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with CBC mode. keysize 192' );

	my $decrypt_pack = $cbc->decrypt( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with CBC mode. keysize 192' );
}

{
	my $key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
	my $iv  = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

	my $plain = <<'END';
11 11 11 11 aa aa aa aa 11 11 11 11 bb bb bb bb
11 11 11 11 cc cc cc cc 11 11 11 11 dd dd dd dd
22 22 22 22 aa aa aa aa 22 22 22 22 bb bb bb bb
22 22 22 22 cc cc cc cc 22 22 22 22 dd dd dd dd
33 33 33 33 aa aa aa aa 33 33 33 33 bb bb bb bb
33 33 33 33 cc cc cc cc 33 33 33 33 dd dd dd dd
44 44 44 44 aa aa aa aa 44 44 44 44 bb bb bb bb
44 44 44 44 cc cc cc cc 44 44 44 44 dd dd dd dd
55 55 55 55 aa aa aa aa 55 55 55 55 bb bb bb bb
55 55 55 55 cc cc cc cc 55 55 55 55 dd dd dd dd
END
	$plain =~ s/\s+//g;

	my $expected = <<'END';
52 3a 8a 80 6a e6 21 f1 55 fd d2 8d bc 34 e1 ab
7b 9b 42 43 2a d8 b2 ef b9 6e 23 b1 3f 0a 6e 52
f3 61 85 d5 0a d0 02 c5 f6 01 be e5 49 3f 11 8b
24 3e e2 e3 13 64 2b ff c3 90 2e 7b 2e fd 9a 12
fa 68 2e dd 2d 23 c8 b9 c5 f0 43 c1 8b 17 c1 ec
4b 58 67 91 82 70 fb ec 10 27 c1 9e d6 af 83 3d
a5 d6 20 99 46 68 ca 22 f5 99 79 1d 29 2d d6 27
3b 29 59 08 2a af b7 a9 96 16 7c ce 1e ec 5f 0c
fd 15 f6 10 d8 7e 2d da 9b a6 8c e1 26 0c a5 4b
22 24 91 41 83 74 29 4e 79 09 b1 e8 55 1c d8 de
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );

	my $cbc = Crypt::CBC->new(-cipher => $obj,
							  -iv => pack('H*', $iv),
							  -header => 'none',
							  -padding => 'none',
						     );

	my $cipher_pack = $cbc->encrypt( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with CBC mode. keysize 256' );

	my $decrypt_pack = $cbc->decrypt( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with CBC mode. keysize 256' );
}

# arbitrary string
{
	my $key = '00112233445566778899aabbccddeeff';
	my $iv  = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

	my $plain = "short";

	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
	my $cbc = Crypt::CBC->new(-cipher => $obj,
							  -iv => pack('H*', $iv),
							  -header => 'none',
							  -padding => 'standard',
						     );

	my $cipher_pack = $cbc->encrypt( $plain );
	my $decrypt = $cbc->decrypt( $cipher_pack );

	cmp_ok( $decrypt, 'eq', $plain, 'encrypt and recover short string' );
}

{
	my $key = '00112233445566778899aabbccddeeff';
	my $iv  = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

	my $plain = <<'END';
In cryptography, ARIA is a block cipher designed in 2003 by a large group of
South Korean researchers. In 2004, the Korean Agency for Technology and Standards
selected it as a standard cryptographic technique.

The algorithm uses a substitution-permutation network structure based on AES.
The interface is the same as AES: 128-bit block size with key size of 128, 192, or 256 bits.
The number of rounds is 12, 14, or 16, depending on the key size.
ARIA uses two 8×8-bit S-boxes and their inverses in alternate rounds; one of these
is the Rijndael S-box.

The key schedule processes the key using a 3-round 256-bit Feistel cipher, with
the binary expansion of 1/π as a source of "nothing up my sleeve numbers".
END

	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
	my $cbc = Crypt::CBC->new(-cipher => $obj,
							  -iv => pack('H*', $iv),
							  -header => 'none',
							  -padding => 'standard',
						     );

	my $cipher_pack = $cbc->encrypt( $plain );
	my $decrypt = $cbc->decrypt( $cipher_pack );

	cmp_ok( $decrypt, 'eq', $plain, 'encrypt and recover long string' );
}



}


done_testing();
