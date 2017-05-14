## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   hash_of_lists => 'h_of_l'
  );

################ main ################
package main;

use Test::More tests => 10;
use Test::Exception;

my $tc = TestClass->new();
isa_ok($tc, 'TestClass');
can_ok($tc, 'new');
can_ok($tc, 'h_of_l');
can_ok($tc, 'h_of_l_keys');
can_ok($tc, 'h_of_l_push');

$tc->h_of_l_push(alpha => 11, 92);
$tc->h_of_l_push(beta => 21);
$tc->h_of_l_push(beta => 22);
$tc->h_of_l_push(alpha => 12);
$tc->h_of_l_push(beta => 23);
$tc->h_of_l_push(alpha => 13);
$tc->h_of_l_push(beta => 24);

my @arr = $tc->h_of_l('alpha');
ok(eq_array(\@arr, [11, 92, 12, 13]), 'Alpha');

@arr = $tc->h_of_l('beta');
ok(eq_array(\@arr, [21, 22, 23, 24]), 'Beta');

@arr = $tc->h_of_l_keys();
ok(eq_set(\@arr, [ qw/alpha beta/ ]), 'Keys');

@arr = $tc->h_of_l();
ok(eq_set(\@arr, [11, 92, 12, 13, 21, 22, 23, 24]), 'All');

dies_ok { $tc->h_of_l(1, 2, 3) } 'Too many arguments';
