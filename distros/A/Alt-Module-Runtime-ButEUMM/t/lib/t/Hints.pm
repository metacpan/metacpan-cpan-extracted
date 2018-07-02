package t::Hints;

use warnings;
use strict;

use Test::More;

BEGIN { is $^H{"Module::Runtime/test_a"}, undef; }
main::test_runtime_hint_hash "Module::Runtime/test_a", undef;

sub import {
	is $^H{"Module::Runtime/test_a"}, 1;
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Module::Runtime/test_b"} = 1;
}

1;
