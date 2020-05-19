#!/usr/bin/perl -w

use lib 't';
use Testdata;

my $data =
{
	'0' =>
	{
		'16' => '333619a3ffdcef4e40c94d49d9ebdf7dcc0a0d6c97a5583e231b99230b04f03c',
		'32' => '6e2ca14be43fde47d5d456f8402b2a9c98984293b5cb4bb2b186113044098c03',
		'64' => 'd28b451d537cc731efab14a9b9f67f744e88804239d28b056bb455643378f808',
	},

	'1' =>
	{
		'16' => '98fc6c9fcc5a0426190a18e8e1dbb6e0e6017bda6cda03e7dda953127ccb7fab',
		'32' => '2746146a9a49a7ce15dc95aa5de110ac04107f1b83121754ce5836422c13e236',
		'64' => '42e0bc79a48f96c93b83bb8812f5ee6058c2846dfa3717e4bcf9e09df15cd4eb',
	},
};

use Test::More tests => 2*2*3 + 5;	#  2 * #endiannesses * #rounds + 5

BEGIN { use_ok (Crypt::ECB) }

my $cipher = 'XTEA';
my $cipher_mod = "Crypt::$cipher";

my $ecb = Crypt::ECB->new;

eval { $ecb->cipher($cipher) };
SKIP: { skip "$cipher_mod not installed", (2 * keys(%{$data}) * keys( %{$data->{0}} ) + 4) if $@;

	eval "require $cipher_mod";

	my $xkey = substr($key, 0, $cipher_mod->keysize);
	$ecb->cipher( $cipher_mod->new($xkey, 32, little_endian => 0) );

	ok($ecb->module eq $cipher_mod,			"$cipher: module");
	ok($ecb->cipher eq $cipher,			"$cipher: cipher");
	ok($ecb->keysize   == $cipher_mod->keysize,	"$cipher: keysize");
	ok($ecb->blocksize == $cipher_mod->blocksize,	"$cipher: blocksize");

	foreach my $endianness (sort keys %{$data})
	{
		foreach my $rounds (sort keys %{$data->{$endianness}})
		{
			$ecb->cipher( $cipher_mod->new($xkey, $rounds, little_endian => $endianness) );

			my $enc = $ecb->encrypt_hex($plaintext);
			ok($enc eq $data->{$endianness}->{$rounds},	"$cipher, $rounds rounds, little endian $endianness: encryption");
			ok($ecb->decrypt_hex($enc) eq $plaintext,	"$cipher, $rounds rounds, little endian $endianness: decryption");
		}
	}
}
