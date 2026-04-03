#!/usr/bin/perl

use strict;
use warnings;

use Digest::MD5;
use Digest::SHA;
use Crypt::RIPEMD160;

use Benchmark;

my $million_a = "a" x 1000000;

my %hash;
timethese (100, {
    'MD5' =>
	sub { $hash{"MD5"} = Digest::MD5::md5_hex($million_a) },
    'SHA-1' =>
	sub { $hash{"SHA-1"} = Digest::SHA::sha1_hex($million_a) },
    'RIPEMD160' =>
	sub { $hash{"RIPEMD160"} = unpack("H*", Crypt::RIPEMD160->hash($million_a)) },
    });


print "results of \"a\" x 1000000:\n";
foreach my $key (sort keys %hash) {
    print "$key : $hash{$key}\n";
}
