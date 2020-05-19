#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => @ciphers + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new(-padding => 'none');

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 1 if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		my $dec = $ecb->decrypt_hex($ciphertext{$cipher});
		ok($dec eq $plaintext.$padding{'standard'}, "$cipher: decryption");
	}
}
