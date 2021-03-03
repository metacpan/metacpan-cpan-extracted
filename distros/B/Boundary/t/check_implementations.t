use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Boundary ();

ok(!Boundary->check_implementations('Foo', 'IFoo'), 'IFoo is not yet applied as an interface of Foo.');

ok(!Boundary->check_implementations('Foo', 'IFoo'), 'IFoo is not yet applied as an interface of Foo.');

{
    package Foo;
    sub hello;
}

Boundary->apply_interfaces_to_package('Foo', 'IFoo');

ok(Boundary->check_implementations('Foo', 'IFoo'), 'Foo is an implementation of IFoo');

ok(!Boundary->check_implementations('Foo', 'IBar'), 'Foo is not an implementation of IBar');

done_testing;
