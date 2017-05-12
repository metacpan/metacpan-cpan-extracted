#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => @ciphers-1 + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (grep {$_ ne 'NULL'} @ciphers)	# NULL cipher doesn't work for this test
{
	eval { $ecb->cipher($cipher) };
	SKIP: { skip "$cipher not installed", 1 if $@;

		my $ks = $ecb->keysize || 56;

		$ecb->key( substr($key, 0, $ks) );
		$ecb->padding('standard');
		my $enc = $ecb->encrypt($plaintext);

		$ecb->key( substr(reverse($key), 0, $ks) );
		$ecb->padding('none');
		ok($ecb->decrypt($enc) ne $plaintext.$padding{'standard'}, "key change recognized ($cipher)");
	}
}
