#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => @ciphers + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: { skip "$cipher not installed", 1 if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		my $enc = $ecb->encrypt_hex($plaintext);
		ok($enc eq $ciphertext{$cipher}, "$cipher: encryption");
	}
}
