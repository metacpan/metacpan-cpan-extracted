use strict;
use warnings;

use Test::More tests => 39;
BEGIN { use_ok('Class::XSAccessor') };

package Foo;
use Class::XSAccessor
  getters => {
    get_foo => 'foo',
    get_bar => 'bar',
  };

# test run-time generation, too
Class::XSAccessor->import(
  getters => {
    get_c => 'c',
  }
);

package main;

BEGIN {pass();}

package Foo;
use Class::XSAccessor
  replace => 1,
  getters => {
    get_foo => 'foo',
    get_bar => "bar\0baz",
  };
package main;

BEGIN {pass();}

ok( Foo->can('get_foo') );
ok( Foo->can('get_bar') );

my $foo = bless  {foo => 'a', "bar\0baz" => 'b', c => 'd'} => 'Foo';
ok($foo->get_foo() eq 'a');
ok($foo->get_bar() eq 'b');
can_ok($foo, 'get_c');
is($foo->get_c(), 'd');

package Foo;
use Class::XSAccessor
  setters => {
    set_foo => 'foo',
    set_bar => "bar\0baz",
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
use Class::XSAccessor
  getters => {
    get_FOO => 'foo',
  },
  setters => {
    set_FOO => 'foo',
  };


# test shorthand syntax
package Foo;
use Class::XSAccessor
  getters => 'barfle',
  setters => {set_barfle => 'barfle'};

use Class::XSAccessor
  getters => [qw/a b/],
  setters  => 'c';

package main;
BEGIN{pass()}

ok( Foo->can('get_foo') );
ok( Foo->can('get_bar') );

my $FOO = bless {
  foo => 'a', bar => 'c',
  barfle => 'works',
  a => 'a1',
  b => 'b1',
  c => 'c1',
} => 'Foo';
ok( $FOO->can('get_FOO') );
ok( $FOO->can('set_FOO') );

ok($FOO->get_FOO() eq 'a');
ok($FOO->get_foo() eq 'a');
$FOO->set_FOO('b');
ok($FOO->get_FOO() eq 'b');
ok($FOO->get_foo() eq 'b');


# tests for shorthand
foreach my $name (qw(barfle a b c)) {
  ok($FOO->can($name));
}

is($FOO->a(), 'a1');
is($FOO->b(), 'b1');
$FOO->c("1c");
is($FOO->{c}, '1c');
$FOO->{a} = '1a';
$FOO->{b} = '1b';
is($FOO->a(), '1a');
is($FOO->b(), '1b');

is($FOO->barfle(), 'works');
$FOO->set_barfle("elfrab");
is($FOO->barfle(), "elfrab");


# test fully qualified name in other class
Class::XSAccessor->import(
  getters => {
    "Foo::also_get_c" => 'c'
  },
);

can_ok($FOO, 'also_get_c');
is($FOO->also_get_c(), $FOO->{c});

