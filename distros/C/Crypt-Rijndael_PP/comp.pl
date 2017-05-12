#!/usr/bin/perl -w
# $Id: comp.pl,v 1.6 2001/08/12 20:05:02 lackas Exp $

# Compare results from Crypt::Rijndael_PP with Crypt::Rijndael
# Press Ctrl-C to stop the test (on Unix)
# prints '.' for every correct calculation and dies
# if the results are different

use strict;
use blib qw'./blib';
use Crypt::Rijndael_PP;
use Crypt::Rijndael;

my ($count,$bytes) = 0;

my $mult = 10;

sub result { print "\n$count rounds\n$bytes Bytes\n"; exit; };

$SIG{INT} = \&result;

my $mode = shift || 'CBC';
my $key_size = 256;
my $plain_size = 128;

my %MODE = (
	ECB => {
		c_xs => Crypt::Rijndael::MODE_ECB,
		c_pl => Crypt::Rijndael_PP::MODE_ECB
	},
	CBC => {
		c_xs => Crypt::Rijndael::MODE_CBC,
		c_pl => Crypt::Rijndael_PP::MODE_CBC
	}
);

$|++;
while(1) {
	my $key = gen($key_size);
	my $c_xs = Crypt::Rijndael->new($key, $MODE{$mode}{c_xs});
	my $c_pl = Crypt::Rijndael_PP->new($key, $MODE{$mode}{c_pl});
			
	for (1..10) {
		my $plain = gen($plain_size * (int(rand 16) +1 ));
		my $t_xs = $c_xs->encrypt($plain);
		my $t_pl = $c_pl->encrypt($plain);
		my $p_pl = $c_pl->decrypt($t_pl);
		my $p_xs = $c_xs->decrypt($t_pl);
		if ($t_xs ne $t_pl) {
			print "Ciphertext differs.\n";
			print "Input: ", unpack('H*',$plain),"\n";
			print "XS   : ", unpack('H*',$t_xs),"\n";
			print "PL   : ", unpack('H*',$t_pl),"\n";
			exit;
		} elsif ($p_pl ne $plain) {
			print "Plaintext differs.\n";
			print "Input: ", unpack('H*',$plain),"\n";
			print "PL   : ", unpack('H*',$t_pl),"\n";
			print "Out  : ", unpack('H*',$p_pl),"\n";
			exit;
		} elsif ($p_xs ne $plain) {
			print "XS decode failed.\n";
			print "Input: ", unpack('H*',$plain),"\n";
			print "PL   : ", unpack('H*',$t_pl),"\n";
			print "o-pl : ", unpack('H*',$p_pl),"\n";
			print "o-xs : ", unpack('H*',$p_xs),"\n";
		} else {
			print '.'
		}
		$count++; $bytes+=length $plain;
	}
	print ':';
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

