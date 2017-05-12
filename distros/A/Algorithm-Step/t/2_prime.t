#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;
use Test::More tests=>1;

use integer;
use Algorithm::Step;

prime();
statistics("prime_stat.txt");
ok(1, 'Algorithm::Step works');

sub prime {
	my @PRIME = ();
	my ($m,$n,$j,$k,$q,$r);

algorithm "P", "Print table of 500 primes";

step 1, "Start table, PRIME[1] <- 2, PRIME[2] <- 3";

	$PRIME[1] = 2;
	$n = 3;
	$j = 1;
	$PRIME[++$j] = $n;

	while ($j < 500) {

step 2, "Advance n by 2";
    		$n += 2; 

step 3, "k <- 1";
		$k = 1;

		do {

step 4, "Increase k";
			++$k;

step 5, "Divide n by PRIME[k]";
			$q = $n / $PRIME[$k]; 
			$r = $n % $PRIME[$k];

step 6, "Remainder zero?";
			next if $r == 0;

step 7, "PRIME[k] large?";
		} while ($q > $PRIME[$k]);

step 8, "n is prime";
		$PRIME[++$j] = $n;
	}

step 9, "Print result";
    	print "FIRST FIVE HUNDRED PRIMES\n";

	$m = 1;
	do {
		for (0,50,100,150,200,250,300,350,400) {
			print $PRIME[$_+$m], "\t";
		}
		print $PRIME[450+$m], "\n";
		$m++;
	} while ($m <= 50);

end_algorithm "P";
}
