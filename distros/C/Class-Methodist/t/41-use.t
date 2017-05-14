## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new'
  );

################ main ################
package main;

use Test::More tests => 2;

can_ok('TestClass', 'new');
my $tc1 = TestClass->new();
isa_ok($tc1, 'TestClass');
