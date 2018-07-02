use warnings;
no warnings "void";
use strict;

BEGIN {
	eval {
		require Data::Alias;
		Data::Alias->VERSION(1.13);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "good Data::Alias unavailable");
	}
}

use Test::More tests => 2;

use Devel::CallParser ();

use Data::Alias;

is alias(42), 42;
is alias{42}, 42;

1;
