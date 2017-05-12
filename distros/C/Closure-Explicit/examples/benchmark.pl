#!/usr/bin/env perl
use strict;
use warnings;
use Closure::Explicit qw(callback);
use Benchmark qw(:hireswallclock cmpthese);

use constant ITERATIONS => 1_000;

cmpthese -5, {
	'plain sub' => sub {
		for(1..ITERATIONS) {
			my $x = [];
			my $code = sub { $x };
			$code->();
			undef $x;
		}
	},
	'callback' => sub {
		for(1..ITERATIONS) {
			my $x = [];
			my $code = callback { $x } [qw($x)];
			$code->();
			undef $x;
		}
	}
};

