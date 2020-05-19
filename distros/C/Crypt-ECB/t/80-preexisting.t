#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => (@ciphers-1)*(@padstyles+5) + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (grep {$_ ne 'IDEA'} @ciphers)	# IDEA doesn't work for this test
{
	eval { $ecb->cipher($cipher) };
	SKIP: { skip "$cipher not installed", @padstyles+5 if $@;

		my $cipher_mod = "Crypt::$cipher"; 
		eval "require $cipher_mod";

		my $xkey = substr($key, 0, $cipher_mod->keysize || 56);
		ok($ecb->cipher( $cipher_mod->new($xkey) ), "$cipher: loading pre-existing cipher object");

		ok($ecb->module eq $cipher_mod,			"$cipher: module matching");
		ok($ecb->cipher eq $cipher,			"$cipher: cipher matching");
		ok($ecb->keysize   == $cipher_mod->keysize,	"$cipher: keysize matching");
		ok($ecb->blocksize == $cipher_mod->blocksize,	"$cipher: blocksize matching");

		foreach my $padstyle (@padstyles)
		{
			$ecb->padding($padstyle);
			my $enc = $ecb->encrypt($plaintext);
			ok($ecb->decrypt($enc) eq $plaintext, "$cipher, $padstyle padding: en- and decryption");
		} 
	}
}
