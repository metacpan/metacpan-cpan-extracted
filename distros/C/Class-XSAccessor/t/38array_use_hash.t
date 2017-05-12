use strict;
use warnings;

# This is a copy of 31array_basic.t with use Class::XSAccessor { ... }

use Test::More tests => 26;
BEGIN { use_ok('Class::XSAccessor::Array') };

package Foo;
use Class::XSAccessor::Array {
  getters => {
    get_foo => 0,
    get_bar => 1,
  },
};
package main;

BEGIN {pass();}

package Foo;
use Class::XSAccessor::Array {
  replace => 1,
  getters => {
    get_foo => 0,
    get_bar => 1,
  },
};
package main;

BEGIN {pass();}

ok( Foo->can('get_foo') );
ok( Foo->can('get_bar') );

my $foo = bless  ['a','b'] => 'Foo';
ok($foo->get_foo() eq 'a');
ok($foo->get_bar() eq 'b');

package Foo;
use Class::XSAccessor::Array {
  setters=> {
    set_foo => 0,
    set_bar => 1,
  },
};

package main;
BEGIN{pass()}

ok( Foo->can('set_foo') );
ok( Foo->can('set_bar') );

$foo->set_foo('1');
pass();
$foo->set_bar('2');
pass();

ok($foo->get_foo() eq '1');
ok($foo->get_bar() eq '2');

# Make sure scalars are copied and not stored by reference (RT 38573)
my $x = 1;
$foo->set_foo($x);
$x++;
is( $foo->get_foo(), 1, 'scalar copied properly' );


# test that multiple methods can point to the same attr.
package Foo;
use Class::XSAccessor::Array {
  getters => {
    get_FOO => 0,
    get_BAR => 10000,
  },
  setters => {
    set_FOO => 0,
  },
};

package main;
BEGIN{pass()}

ok( Foo->can('get_foo') );
ok( Foo->can('get_bar') );

my $FOO = bless  ['a', 'c'] => 'Foo';
$FOO->[10000] = 'wow';

ok( Foo->can('get_FOO') );
ok( Foo->can('set_FOO') );

ok($FOO->get_FOO() eq 'a');
ok($FOO->get_foo() eq 'a');
$FOO->set_FOO('b');
ok($FOO->get_FOO() eq 'b');
ok($FOO->get_foo() eq 'b');

ok($FOO->get_bar() eq 'c');

ok($FOO->get_BAR() eq 'wow');

