#!/usr/bin/perl -T
use strict;
use warnings;
use Test::More tests=> 2;

my @arr = (1..10);
my $answer = '1:27:125:343:729';
my $x;

use Acme::BottomsUp;
@arr			# start w/ numbers
    grep { $_ % 2 }	# get the odd ones
    map { $_**3 }	# cube each one
    join ":",		# glue together
    $x =		# store result
;
is($x, $answer);
no Acme::BottomsUp;

$x = join ":",
	map { $_**3 }
	grep { $_ % 2 }
	@arr
;
is($x, $answer);

