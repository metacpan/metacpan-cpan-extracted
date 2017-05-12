use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Class::XSAccessor::Array') };

package Foo;
use Class::XSAccessor::Array
  lvalue_accessors => {
    "bar" => 0,
  };

package main;

BEGIN {pass();}

ok( Foo->can('bar') );

my $foo = bless  ['b'] => 'Foo';
my $x = $foo->bar();
ok($x eq 'b');
$foo->bar = "buz";
ok($x eq 'b');
ok($foo->bar() eq 'buz');

