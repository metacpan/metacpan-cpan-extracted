use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('BGS') };

foreach my $i (1 .. 2) {
	bgs_call {
		return "sub $i";
	} bgs_back {
		my $r = shift;
		is($r, "sub $i", "sub $i");
	};
}
bgs_wait();
