use warnings;
use strict;

use Test::More tests => 11001;

use IO::File 1.03;

BEGIN { use_ok "Data::Entropy::Algorithms", qw(rand_flt); }

sub test_rand_flt($$) {
	my($min, $max) = @_;
	for(my $i = 500; $i--; ) {
		my $v = rand_flt($min, $max);
		ok $v >= $min && $v <= $max;
		$v = rand_flt($max, $min);
		ok $v >= $min && $v <= $max;
	}
}

test_rand_flt(1.0, 2.0);
test_rand_flt(1.0, 2.75);
test_rand_flt(1.25, 2.0);
test_rand_flt(1.25, 2.75);
test_rand_flt(-2.75, -1.25);
test_rand_flt(0.0, 1.0);
test_rand_flt(-1.0, 1.0);
test_rand_flt(-2.0, 1.0);
test_rand_flt(-1.0, 2.0);
test_rand_flt(2.5, 2.5);
test_rand_flt(-0.0, +0.0);

1;
