## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   scalar => 'val',
   scalar => { name => 'val2', default => 'quux' }
  );

################ main ################
package main;

use Test::More tests => 15;

my $tc = TestClass->new();

is($tc->val(), undef, 'Undefined');

$tc->val(42);
is($tc->val(), 42, 'Fourty two');

$tc->val(17);
is($tc->val(), 17, 'Seventeen');

ok(defined $tc->val(), 'Defined');

$tc->clear_val();
ok(!defined $tc->val(), 'Undefined');

$tc->val(17);
is($tc->val(), 17, 'Seventeen again');
ok(defined $tc->val(), 'Defined');

## Append
$tc->val('fred');
is($tc->val(), 'fred', 'Set to scalar');
$tc->append_to_val(' lives');
is($tc->val(), 'fred lives', 'Append OK');

## Defaulted scalar.
is($tc->val2(), 'quux');
$tc->val2('syzygy');
is($tc->val2(), 'syzygy');

## Add to
$tc->val(42);
$tc->add_to_val(5);
is($tc->val(), 47);
$tc->add_to_val(-10);
is($tc->val(), 37);

## Inc/Dec
$tc->val(5);
$tc->inc_val();
$tc->inc_val();
is($tc->val(), 7);

$tc->dec_val();
$tc->dec_val();
$tc->dec_val();
is($tc->val(), 4);
