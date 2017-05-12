#! /usr/local/bin/perl -w

use strict;

eval 'use Crypt::Rijndael';
use Crypt::Rijndael_PP;

print "1..101\n";

$|++;

if ($@) {
	print "ok # skipped in absence of Crypt:Rijndael\n" for 1..101;
	exit 0;
} else {
	print "ok 1\n";
}

my %MODE = (
	ECB => {
		c_xs => &Crypt::Rijndael::MODE_ECB,
		c_pl => Crypt::Rijndael_PP::MODE_ECB
	},
	CBC => {
		c_xs => &Crypt::Rijndael::MODE_CBC,
		c_pl => Crypt::Rijndael_PP::MODE_CBC
	}
);

my $mode = 'ECB';
my $keysize = 256;
my $plainsize = 128;

for my $a (0..9) {
	my $key = gen($keysize);
	my $c_xs = Crypt::Rijndael->new($key, $MODE{$mode}{c_xs});
	my $c_pl = Crypt::Rijndael_PP->new($key, $MODE{$mode}{c_pl});
			
	for (0..9) {
		my $x = $a*10 + $_ + 2;
		my $plain = gen($plainsize * (int(rand 16) +1 ));
		my $t_xs = $c_xs->encrypt($plain);
		my $t_pl = $c_pl->encrypt($plain);
		my $p_pl = $c_pl->decrypt($t_pl);
		my $p_xs = $c_xs->decrypt($t_pl);
		if ($t_xs ne $t_pl) {
			print "not ok $x # Ciphertext differs.\n";
		} elsif ($p_pl ne $plain) {
			print "not ok $x # Plaintext differs.\n";
		} elsif ($p_xs ne $plain) {
			print "not ok $x # XS decode failed.\n";
		} else {
			print "ok $x\n";
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

