use warnings;
no warnings "void";
use strict;

BEGIN {
	eval { require Devel::CallParser };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Devel::CallParser unavailable");
	}
}

use Test::More tests => 2;

use Devel::CallParser ();

use Data::Alias;

is alias(42), 42;
is alias{42}, 42;

1;
