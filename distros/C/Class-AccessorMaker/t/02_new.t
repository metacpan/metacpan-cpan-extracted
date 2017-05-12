package TestNew;

use Class::AccessorMaker {
  hash   => { key => "value" },
  array  => [ 0, 1 ],
  scalar => "scalar",
  object => "" };

1;

package TestNew::Priv;

use Class::AccessorMaker::Private {
  hash   => { key => "priv_value" },
  array  => [ "priv", 1 ],
  scalar => "priv",
  object => "" };


package Object;

use Class::AccessorMaker {
  foo => "bar" };

1;

package main;

use Test::More tests => 7;
use strict;

# construct 'em
ok(my $obj = Object->new(), "Mock object new - OK");
ok(my $test = TestNew->new(object => $obj, 
			hash => {key => "value2"},
			array => [ 1, 0 ] ), "Test object - OK");

# object storage testing
isa_ok($test->object(), "Object");
is($test->object()->foo, "bar", "Double object calling - OK");

# add stuff to the references
push @{$test->array}, "2";
$test->hash()->{new_key} = "test";

# reference default testing
ok(eq_hash($test->hash, { key => "value2", new_key => "test" }),"hash - OK");
ok(eq_array($test->array, [ 1, 0, 2 ]), "array - OK");
is($test->scalar, "scalar", "scalar - OK");
