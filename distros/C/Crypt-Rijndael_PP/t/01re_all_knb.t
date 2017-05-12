#! /usr/local/bin/perl -w

use strict;
use Crypt::Rijndael_PP qw(rijndael_decrypt rijndael_encrypt MODE_ECB);

print "1..9\n";

# Simple test with all blocksizes and all keysizes
#		         1         2         3
#               12345678901234567890123456789012
my %data = (
	128 => 'abcdefghijklmnop',
	192 => 'qrstuvwxyzabcdefghijklmn',
	256 => 'opqrstuvwxyzabcdefghijklmnopqrst'
);

my %key = (
	128  => '1234567890ABCDEF1234567890ABCDEF',
	192  => 'DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF',
	256  => 'DEADBEEF1234567890ABCDEFDEADBEEFDEADBEEF1234567890ABCDEFDEADBEEF'
);


my $i;
for my $ks (128,192,256) { # keysize
	for my $bs (128,192,256) { # blocksize
		++$i;
		my $cipher = rijndael_encrypt($key{$ks},MODE_ECB,$data{$bs},$ks,$bs);
		my $plain  = rijndael_decrypt($key{$ks},MODE_ECB,$cipher,$ks,$bs);
		print $plain eq $data{$bs} ? "ok $i\n" : "not ok $i # ($ks/$bs)\n";
	}
}
