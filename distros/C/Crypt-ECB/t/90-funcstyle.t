#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 3*4*@ciphers*(@padstyles-1)*(length($plaintext)+1) + 1;

BEGIN { use_ok (Crypt::ECB, qw(encrypt decrypt encrypt_hex decrypt_hex)) }

my $ecb = Crypt::ECB->new;

$plaintext =~ s/ /_/g;				# spaces clash with 'space' padding
@padstyles = grep {$_ ne 'null'} @padstyles;	# testing "\0" clashes with 'null' padding

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 3*4*@padstyles*(length($plaintext)+1) if $@;

		my $ks = $ecb->keysize || 56;
		my $xkey = substr($key, 0, $ks);
		$ecb->key($xkey);

		foreach my $padstyle (@padstyles)
		{
			$ecb->padding($padstyle);

			foreach my $len (0 .. length $plaintext)
			{
				my $plain = substr($plaintext, 0, $len);

				my $enc1 = $ecb->encrypt($plain);
				my $enc2 = encrypt($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes: encryption function style");
				my $dec = decrypt($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes: decryption function style");

				$enc1 = $ecb->encrypt_hex($plain);
				$enc2 = encrypt_hex($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes: hex encryption function style");
				$dec = decrypt_hex($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes: hex decryption function style");

				$plain = substr($plaintext, 0, $len) . "0";

				$enc1 = $ecb->encrypt($plain);
				$enc2 = encrypt($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes plus '0': encryption function style");
				$dec = decrypt($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes plus '0': decryption function style");

				$enc1 = $ecb->encrypt_hex($plain);
				$enc2 = encrypt_hex($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes plus '0': hex encryption function style");
				$dec = decrypt_hex($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes plus '0': hex decryption function style");

				$plain = substr($plaintext, 0, $len) . "\0";

				$enc1 = $ecb->encrypt($plain);
				$enc2 = encrypt($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes plus '\\0': encryption function style");
				$dec = decrypt($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes plus '\\0': decryption function style");

				$enc1 = $ecb->encrypt_hex($plain);
				$enc2 = encrypt_hex($xkey, $cipher, $plain, $padstyle);
				ok($enc1 eq $enc2, "$cipher, $padstyle padding, $len bytes plus '\\0': hex encryption function style");
				$dec = decrypt_hex($xkey, $cipher, $enc2, $padstyle);
				ok($dec eq $plain, "$cipher, $padstyle padding, $len bytes plus '\\0': hex decryption function style");
			}
		}
	}
}
