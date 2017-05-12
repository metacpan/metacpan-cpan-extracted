#!/usr/bin/perl -w

use strict;

use blib;

use Test::More  tests => 1;
# Check we can load module
BEGIN { use_ok( 'Acme::WalkMethods' ); }

# Test directly
#my $auto = Acme::WalkMethods->new();
#is(5,$auto->foo('5'),'set foo');
#is(5,$auto->foo(),'get foo');

# Test as part of package
#my $foo = Acme::WalkMethods::Tester->new();
#$foo->bar('5');
#$foo->foo('5');
#print "Foo: " . $foo->foo() . "\n" if $foo->foo();
#print "Bar: " . $foo->bar() . "\n" if $foo->bar();

package Acme::WalkMethods::Tester;
use base qw(Acme::WalkMethods);
1;

