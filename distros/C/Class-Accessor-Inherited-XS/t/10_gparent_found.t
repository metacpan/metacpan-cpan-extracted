use strict;
use Test::More;

package Test;

use Class::Accessor::Inherited::XS {
    inherited => [qw/foo/],
};

package TestC;
our @ISA=qw/Test/;

package Child;
our @ISA = qw/TestC/;

package main;

is(Test->foo(42), 42);
is(Child->foo, 42);

done_testing;
