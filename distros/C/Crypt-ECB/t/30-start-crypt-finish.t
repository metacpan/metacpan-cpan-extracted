#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 2*@ciphers + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 2 if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		my ($enc, $dec);

		$ecb->start('encryption');
		$enc .= $ecb->crypt foreach split(//, $plaintext);
		$enc .= $ecb->finish;

		ok(unpack('H*', $enc) eq $ciphertext{$cipher}, "$cipher: encryption using start/crypt/finish");

		$ecb->start('decryption');
		$dec .= $ecb->crypt($1) while $enc =~ /(.)/gs;
		$dec .= $ecb->finish;

		ok($dec eq $plaintext, "$cipher: decryption using start/crypt/finish");
	}
}
