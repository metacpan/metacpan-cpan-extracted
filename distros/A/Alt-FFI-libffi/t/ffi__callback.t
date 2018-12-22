use strict;
use warnings;
use Test::More skip_all => 'borked';
use FFI;

sub callback1
{
  return $_[0] + $_[1];
}

my $callback1 = FFI::callback("ciii", \&callback1);
is(FFI::call($callback1->addr, "ciii", 1,2), 3, 'callback1(1,2) = 3');

sub callback2
{
  my($address, $a, $b) = @_;
  return FFI::call($address, "ciii", $a, $b);
}

my $callback2 = FFI::callback("ciLii", \&callback2);
is(FFI::call($callback2->addr, "ciLii", $callback1->addr, 3, 4), 7, 'callback2(\&callback1, 3,4) = 7');

done_testing;
