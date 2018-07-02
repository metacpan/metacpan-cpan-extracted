use warnings;
no warnings "void";
use strict;

BEGIN {
	eval {
		require indirect;
		indirect->VERSION(0.27);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "good indirect unavailable");
	}
}

use Test::More tests => 1;

use Devel::CallParser ();

no indirect;

ok 1;

1;
