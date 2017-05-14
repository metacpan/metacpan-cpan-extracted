## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   object => 'obj1',
   object => { name => 'obj2',
	       class => 'TestClassTwo' },
   object => { name => 'obj3',
	       class => 'TestClassThree',
	       delegate => [ qw/the_answer smallest_random_number/ ] }
  );

################ TestClassTwo ################
package TestClassTwo;

sub new { bless { }, $_[0] }

sub set { $_[0]->{val} = $_[1] }
sub get { $_[0]->{val} }

################ TestClassThree ################
package TestClassThree;

sub new { bless { }, $_[0] }

sub the_answer { 42 }
sub smallest_random_number { 17 }

################ main ################
package main;

use Test::More tests => 15;
use Test::Exception;

my $tc = TestClass->new();
isa_ok($tc, 'TestClass');
can_ok($tc, 'obj1');
can_ok($tc, 'obj2');

my $tc2 = TestClassTwo->new();
$tc->obj1($tc2);
isa_ok($tc->obj1(), 'TestClassTwo');

$tc2->set(42);
is($tc2->get(), 42, 'Get TC2');

my $tc2_test = $tc->obj1();
isa_ok($tc2_test, 'TestClassTwo');
is($tc2_test->get(), 42, 'Get TC2 Test');

$tc->obj2($tc2);
isa_ok($tc->obj2(), 'TestClassTwo');

my $tc3 = TestClassThree->new();
$tc->obj1($tc3);
isa_ok($tc->obj1(), 'TestClassThree');
dies_ok { $tc->obj2($tc3) } 'Type violation';

lives_ok { $tc->obj3($tc3) } 'TestClassTree properly';
can_ok($tc, 'the_answer');
can_ok($tc, 'smallest_random_number');
is($tc->the_answer(), 42, 'The Answer');
is($tc->smallest_random_number(), 17, 'Smallest');
