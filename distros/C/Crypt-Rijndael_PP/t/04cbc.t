#! /usr/local/bin/perl -w

use strict;
use Crypt::Rijndael_PP;


print "1..100\n";

$|++;

for my $a (0..9) {
	my $key = gen(256);
	my $c = new Crypt::Rijndael_PP($key, Crypt::Rijndael_PP::MODE_CBC);
	for (0..9) {
		my $x = $a*10 + $_ + 1;
		my $data = gen($Crypt::Rijndael_PP::DEFAULT_BLOCKSIZE * int(rand(16)+1));
		my $cipher = $c->encrypt($data);
		my $plain = $c->decrypt($cipher);
		print $plain eq $data ? "ok $x\n" : "not ok $x\n";
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


# vi:filetype=perl
