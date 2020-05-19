#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 3*@ciphers*(@padstyles-1)*(length($plaintext)+1) + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

$plaintext =~ s/ /_/g;				# spaces clash with 'space' padding
@padstyles = grep {$_ ne 'null'} @padstyles;	# testing "\0" clashes with 'null' padding

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 3*@padstyles*(length($plaintext)+1) if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		foreach my $padstyle (@padstyles)
		{
			$ecb->padding($padstyle);

			foreach my $len (0 .. length $plaintext)
			{
				my $plain = substr($plaintext, 0, $len);
				my $enc = $ecb->encrypt_hex($plain);
				my $dec = $ecb->decrypt_hex($enc);
				ok($dec eq $plain, "$cipher, $padstyle padding: en-/decrypting $len bytes plaintext");

				$plain = substr($plaintext, 0, $len) . "0";
				$enc = $ecb->encrypt_hex($plain);
				$dec = $ecb->decrypt_hex($enc);
				ok($dec eq $plain, "$cipher, $padstyle padding: en-/decrypting $len bytes plaintext plus '0'");

				$plain = substr($plaintext, 0, $len) . "\0";
				$enc = $ecb->encrypt_hex($plain);
				$dec = $ecb->decrypt_hex($enc);
				ok($dec eq $plain, "$cipher, $padstyle padding: en-/decrypting $len bytes plaintext plus '\\0'");
			}
		}
	}
}
