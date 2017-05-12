#!perl -w

use strict;
use Test::More tests => 37;

BEGIN{
	use_ok 'Acme::Lambda::Expr', qw(:all);
}

sub power{
	$_[0] ** $_[1];
}

my $f = abs($x) * $y + 2;
my $g = curry \&power, $x, $y;
my $h = $f + $g;

for my $i(10, -10, 100){
	for my $j(2, 4, -6){
		is $f->compile->($i, $j), $f->($i, $j), 'f';
		is $g->compile->($i, $j), $g->($i, $j), 'g';
		is $h->compile->($i, $j), $h->($i, $j), 'h';

		is $h->compile()->($x, $y)->($i, $j), $h->($i, $j), 're-lambdization';
	}
}