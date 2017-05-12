#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 2*@ciphers*@padstyles + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 2*@padstyles if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		foreach my $padstyle (@padstyles)
		{
			$ecb->padding($padstyle);
			my $enc = $ecb->encrypt($plaintext);
			ok($ecb->decrypt($enc) eq $plaintext, 				"$cipher, $padstyle padding: en- and decryption");

			$ecb->padding('none');
			ok($ecb->decrypt($enc) eq $plaintext . $padding{$padstyle},	"$cipher, $padstyle padding: padded bytes");
		}
	}
}
