#! /usr/local/bin/perl -w

use strict;
use Crypt::DES_PP;

use constant TESTS => 5000;
use constant UINT_MAX => 0xffffffff;

my $key = pack "NN", (rand UINT_MAX), (rand UINT_MAX);
my $cipher = Crypt::DES_PP->new ($key);

unless ($cipher) {
	print "1..1\nnot ok 1\n";
	exit 1;
}

print "1..", TESTS, "\n";
my $count = 1;
foreach (1 .. TESTS) {
	my $plain = pack "NN", (rand UINT_MAX), (rand UINT_MAX);

	$@ = '';
	eval {
		my $ciphertext = $cipher->encrypt ($plain);
		die if $cipher->decrypt ($ciphertext) ne $plain;
	};
	print $@ ? "not ok $count\n" : "ok $count\n";
	++$count;
}
