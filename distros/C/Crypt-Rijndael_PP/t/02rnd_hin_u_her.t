#! /usr/local/bin/perl -w

use strict;
use Crypt::Rijndael_PP;

print "1..200\n";

$|++;
for my $i (0..9) {
	my $key = unpack 'H*', gen(256);
	for (1..10) {
		my $block = gen(128 * $_);
		my $x = $i*20 + 2*$_ -1;
		{
			my $cipher = rijndael_encrypt($key, Crypt::Rijndael_PP::MODE_ECB, $block, 256, 128);
			my $plain  = rijndael_decrypt($key, Crypt::Rijndael_PP::MODE_ECB, $cipher, 256, 128);
			print $block eq $plain ? "ok $x\n" : "not ok $x # random data\n";
		}
		{
			++$x;
			my $cipher = rijndael_encrypt($key, Crypt::Rijndael_PP::MODE_CBC, $block, 256, 128);
			my $plain  = rijndael_decrypt($key, Crypt::Rijndael_PP::MODE_CBC, $cipher, 256, 128);
			print $block eq $plain ? "ok $x\n" : "not ok $x # random data\n";
		}
	}
}

sub gen {
	my $size = shift;
	my $res;
	while ($size > 0) {
		$size -= 8;
		$res .= pack 'C', rand 256;
	}
	$res;
}


