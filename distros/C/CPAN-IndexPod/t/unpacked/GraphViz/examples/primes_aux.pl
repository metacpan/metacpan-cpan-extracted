#!/usr/local/bin/perl -w
# badly written program in the hopes it would sound nice
# - Greg McCarroll
#
# This was used to test Devel::GraphVizProf, providing
# primes.dot and thus primes.png

@known=qw(2 3 5 7);

for (1..100) {
    if (check_prime($_)) {
	warn "$_ is prime\n";
    }
}

sub check_prime {
    my ($n)=@_;
    if ($n < 2) {
	return 0;
    }

    for (1..scalar(@known)) {
	if ($n==$known[$_-1]) {
	    return 1;
	}
	if (($n/$known[$_-1]) == int($n/$known[$_-1])) {
	    return 0;
	}
    }


    for ($known[-1]..int(sqrt($n))) {
	if (($n/$_) == int($n/$_)) {
	    return 0;
	}
    }
    push(@known,$n);
    return 1;
}



