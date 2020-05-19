#!/usr/bin/perl -w

use lib 't';
use Testdata;

my @w_extra_block  = qw(standard zeroes oneandzeroes null);
my @wo_extra_block = qw(rijndael_compat space none);

use Test::More tests => 2*@ciphers*(4+3) + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 2 * (@w_extra_block + @wo_extra_block) if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		my $bs = $ecb->blocksize;
		my $text = "x" x $bs;

		my %padding = (
			'standard'		=> chr($bs) x $bs,
			'zeroes'		=> "\x00" x ($bs-1) . chr($bs),
			'oneandzeroes'		=> "\x80" . "\x00" x ($bs-1),
			'null'			=> "\x00" x $bs,
		);

		foreach my $padstyle (@w_extra_block)
		{
			$ecb->padding($padstyle);
			my $enc = $ecb->encrypt($text);
			ok($ecb->decrypt($enc) eq $text,			"$cipher, $padstyle padding: en-/decrypting one block ($bs bytes)");

			$ecb->padding('none');
			ok($ecb->decrypt($enc) eq $text . $padding{$padstyle},	"$cipher, $padstyle padding: extra block added");
		}

		foreach my $padstyle (@wo_extra_block)
		{
			$ecb->padding($padstyle);
			my $enc = $ecb->encrypt($text);
			ok($ecb->decrypt($enc) eq $text,			"$cipher, $padstyle padding: en-/decrypting one block ($bs bytes)");

			$ecb->padding('none');
			ok($ecb->decrypt($enc) eq $text,			"$cipher, $padstyle padding: no extra block added");
		}
	}
}
