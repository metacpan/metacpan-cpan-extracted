#!/usr/bin/perl

use MD5;
use SHA;
use RIPEMD160;

use Benchmark;

$million_a = "a" x 1000000;

timethese (100, {
    'MD5' => 
	'$hash{"MD5"} = MD5->hexhash($million_a)."\n";',
    'SHA' => 
	'$hash{"SHA"} =  SHA->hexhash($million_a)."\n";',
    'RIPEMD160' => 
	'$hash{"RIPEMD160"} =  RIPEMD160->hexhash($million_a)."\n";'
    });


print "results of \"a\" x 1000000:\n";
foreach $key (sort keys %hash) {
    print "$key : $hash{$key}\n";
}
