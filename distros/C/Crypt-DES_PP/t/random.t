#! /usr/local/bin/perl -w

use strict;
use Crypt::DES_PP;

use constant TESTS => 5000;
use constant UINT_MAX => 0xffffffff;

print "1..", TESTS, "\n";
my $count = 1;
foreach (1 .. TESTS) {
	my $key = pack "NN", (rand UINT_MAX), (rand UINT_MAX);
	my $plain = pack "NN", (rand UINT_MAX), (rand UINT_MAX);

	$@ = '';
	eval {
		my $cipher = Crypt::DES_PP->new ($key);
		my $ciphertext = $cipher->encrypt ($plain);
		die if $cipher->decrypt ($ciphertext) ne $plain;
	};
	print $@ ? "not ok $count\n" : "ok $count\n";
	++$count;
}
