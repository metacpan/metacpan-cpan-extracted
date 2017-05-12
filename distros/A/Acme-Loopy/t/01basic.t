use v5.14;
use strict;
use Test::More tests => 3;
use Acme::Loopy;

my $sum = 0;
loop {
	next unless ${^LOOP};
	$sum += ${^LOOP};
	
	loop {
		next unless ${^LOOP};
		$sum += ${^LOOP};
		loop {
			next unless ${^LOOP};
			$sum *= ${^LOOP} if ${^LOOP};
			last if ${^LOOP} > 2;
		}
		last if ${^LOOP} > 2;
	}
	
	loop {
		next unless ${^LOOP};
		$sum += ${^LOOP};
		last if ${^LOOP} > 3;
	}

	$sum += ${^LOOP};
	last if ${^LOOP} > 3;
}

is $sum, 5406614024;

loop {
	ok not ${^LOOP};
	last;
};

is ${^LOOP}, undef;
