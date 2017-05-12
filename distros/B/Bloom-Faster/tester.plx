#!/usr/bin/env perl
use Bloom::Faster;
use Getopt::Std;


my $n = 60000000;
my %args;
getopts("n:e:",\%args);

if ($args{n}) {
	$n = $args{n};
}

my $bloom = new Bloom::Faster({n=>$n, e=>0.000001});

while (<>) {
	chomp;
	if ($bloom->add($_)) {
		print "dup $_\n";
	}
}
