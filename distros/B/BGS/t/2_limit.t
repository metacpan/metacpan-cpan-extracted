use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('BGS::Limit') };

foreach my $i (1 .. 3) {
	bgs_call {
		return "sub $i";
	} bgs_back {
		my $r = shift;
		is($r, "sub $i", "sub $i");
	};
}
bgs_wait(2);
