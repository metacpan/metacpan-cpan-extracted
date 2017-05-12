use strict;

use Callback::Frame;
use Test::More tests => 3;

## This test verifies the frame_local convenience interface.

our $foo = 1;
my $cb;

sub global_foo_getter {
  return $foo;
}

frame_local __PACKAGE__.'::foo', sub {
  $foo = 2;
  $cb = fub {
    return global_foo_getter();
  };
};

is($foo, 1, 'starts as 1');
is($cb->(), 2, 'new binding stores 2');
is($foo, 1, 'old binding restored');
