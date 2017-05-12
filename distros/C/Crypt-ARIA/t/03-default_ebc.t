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

# default ECB - null padding
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
c6 ec d0 8e 22 c3 0a bd b2 15 cf 74 e2 07 5e 6e
29 cc aa c6 34 48 70 8d 33 1b 2f 81 6c 51 b1 7d
9e 13 3d 15 28 db f0 af 57 87 c7 f3 a3 f5 c2 bf
6b 6f 34 59 07 a3 05 56 12 ce 07 2f f5 4d e7 d7
88 42 4d a6 e8 cc fe 81 72 b3 91 be 49 93 54 16
56 65 ba 78 64 91 70 00 a6 ee b2 ec b4 a6 98 ed
fc 78 87 e7 f5 56 37 76 14 ab 0a 28 22 93 e6 d8
84 db b8 42 06 cd b1 6e d1 75 4e 77 a1 f2 43 fd
08 69 53 f7 52 cc 1e 46 c7 c7 94 ae 85 53 7d ca
ec 8d d7 21 f5 5c 93 b6 ed fe 2a de a4 38 73 e8
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
	my $cipher_pack = $obj->encrypt_ecb( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with ECB mode. keysize 128' );

	my $decrypt_pack = $obj->decrypt_ecb( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with ECB mode. keysize 128' );
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
8d 14 70 62 5f 59 eb ac b0 e5 5b 53 4b 3e 46 2b
5f 23 d3 3b ff 78 f4 6c 3c 15 91 1f 4a 21 80 9a
ac ca d8 0b 4b da 91 5a a9 da e6 bc eb e0 6a 6c
83 f7 7f d5 39 1a cf e6 1d e2 f6 46 b5 d4 47 ed
bf d5 bb 49 b1 2f bb 91 45 b2 27 89 5a 75 7b 2a
f1 f7 18 87 34 86 3d 7b 8b 6e de 5a 5b 2f 06 a0
a2 33 c8 52 3d 2d b7 78 fb 31 b0 e3 11 f3 27 00
15 2f 33 86 1e 9d 04 0c 83 b5 eb 40 cd 88 ea 49
97 57 09 dc 62 93 65 a1 89 f7 8a 3e c4 03 45 fc
6a 5a 30 7a 8f 9a 44 13 09 1e 00 7e ca 56 45 a0
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
	my $cipher_pack = $obj->encrypt_ecb( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with ECB mode. keysize 192' );

	my $decrypt_pack = $obj->decrypt_ecb( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with ECB mode. keysize 192' );
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
58 a8 75 e6 04 4a d7 ff fa 4f 58 42 0f 7f 44 2d
8e 19 10 16 f2 8e 79 ae fc 01 e2 04 77 32 80 d7
01 8e 5f 7a 93 8e c3 07 11 71 99 53 ba e8 65 42
cd 7e bc 75 24 74 c1 a5 f6 ea aa ce 2a 7e 29 46
2e e7 df a5 af db 84 17 7e ad 95 cc d4 b4 bb 6e
1e d1 7b 95 34 cf f0 a5 fc 29 41 42 9c fe e2 ee
49 c7 ad be b7 e9 d1 b0 d2 a8 53 1d 94 20 79 59
6a 27 ed 79 f5 b1 dd 13 ec d6 04 b0 7a 48 88 5a
3a fa 06 27 a0 e4 e6 0a 3c 70 3a f2 92 f1 ba a7
7b 70 2f 16 c5 4a a7 4b c7 27 ea 95 c7 46 8b 00
END
	$expected =~ s/\s+//g;

	my $plain_pack = pack 'H*', $plain;
	my $obj = Crypt::ARIA->new()->set_key_hexstring( $key );
	my $cipher_pack = $obj->encrypt_ecb( $plain_pack );
	my $cipher = unpack 'H*', $cipher_pack;
	is ( $cipher, $expected, 'encryption with ECB mode. keysize 256' );

	my $decrypt_pack = $obj->decrypt_ecb( $cipher_pack );
	my $decrypt = unpack 'H*', $decrypt_pack;
	cmp_ok( $decrypt, 'eq', $plain, 'recover plaintext with ECB mode. keysize 256' );
}

done_testing();
