#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 11*@ciphers + 3;

BEGIN { use_ok (Crypt::ECB) }

my $crypt = Crypt::ECB->new(-key => $key);

# cipher loadable?
eval { $crypt->cipher('Unknown') };
ok($@ =~ /^Couldn't load/, 'cipher: module could not be loaded');

# check cipher is set
eval { $crypt->start('decryption') };
ok($@ =~ /^Can't start/, 'start: cipher not set');

foreach my $cipher (@ciphers)
{
	eval { $crypt->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 11 if $@;

		$crypt = Crypt::ECB->new(-cipher => $cipher);

		# custom padding works as expected?
		eval { $crypt->padding(sub {}) };
		ok($@ =~ /^Provided/, "custom padding not sensible ($cipher)");

		# check start is called before crypt
		eval { $crypt->crypt };
		ok($@ =~ /^You tried/, "crypt: start not called ($cipher)");

		# check start is called before finish
		eval { $crypt->finish };
		ok($@ =~ /^You tried/, "finish: start not called ($cipher)");

		# check mode is [^de]
		eval { $crypt->start('nonsense') };
		ok($@ =~ /^Mode has/, "start: mode not recognized ($cipher)");

		# check key is set
		eval { $crypt->start('decryption') };
		ok($@ =~ /^Key not set/, "start: key not set ($cipher)");

		# check start w/o finish before
		$crypt->key( substr($key, 0, $crypt->keysize || 56) );
		$crypt->start('encryption');
		$crypt->crypt($plaintext);
		eval { $crypt->start('decryption') };
		ok($@ =~ /^Not yet/, "start: finish not called ($cipher)");
		$crypt->finish;

		# check padding is set when data % $bs
		$crypt->padding('none');
		eval { $crypt->encrypt($plaintext) };
		ok($@ =~ /^Your message/, "_pad: no padding and no full block ($cipher)");

		# check padding is known
		$crypt->padding('unknown');
		eval { $crypt->encrypt($plaintext) };
		ok($@ =~ /^Padding/, "_pad: padding not defined ($cipher)");

		#  same for truncating
		$crypt->padding('unknown');
		eval { $crypt->decrypt_hex( $ciphertext{$cipher} ) };
		ok($@ =~ /^Padding/, "_truncate: padding not defined ($cipher)");

		#  check inconsistent standard padding is detected
		$crypt->padding('space');
		my $enc = $crypt->encrypt($plaintext);
		$crypt->padding('standard');
		eval { $crypt->decrypt($enc) };
		ok($@ =~ /^Asked to/, "_truncate: inconsistent standard padding ($cipher)");

		#  check inconsistent zeroes padding is detected
		$crypt->padding('zeroes');
		eval { $crypt->decrypt_hex( $ciphertext{$cipher} ) };
		ok($@ =~ /^Block doesn't/, "_truncate: inconsistent zeroes padding ($cipher)");
	}
}
