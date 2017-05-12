package TestChain;

use Class::AccessorMaker {
  one => "",
  two => {},
  three => [] };

1;

package TestChain::Priv;

use Class::AccessorMaker {
  one => "",
  two => {},
  three => [] };

1;

package main;

use Test::More tests => 8;
use strict;

my $test = TestChain->new();
ok($test->one(1)
	->two({key => "value"})
	->three([1,2]), 
	"chaining - OK");
is($test->one, 1, "1st value - OK");
is($test->two()->{key}, "value", "2nd value - OK");
is($test->three()->[1], 2, "3rd value - OK");

$test = TestChain::Priv->new();
ok($test->one(1)
	->two({key => "value"})
	->three([1,2]), 
	"Private chaining - OK");
is($test->one, 1, "1st private value - OK");
is($test->two()->{key}, "value", "2nd private value - OK");
is($test->three()->[1], 2, "3rd private value - OK");