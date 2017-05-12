use strict;

use Callback::Frame;
use Test::More tests => 9; 

## This test throws an exception after a local binding has been modified
## but before it has had a chance to be copied into the locals element
## of the frame. The guard is used to detect this and copy them anyways.


my ($cb, $cb2);

our $foo = 123;

ok(!$Callback::Frame::top_of_stack);

frame(name => "base frame",
      local => __PACKAGE__ . '::foo',
      code => sub {

  $cb = frame(code => sub {
    $foo = 234;
    die "bye";
  }, catch => sub {
    is($foo, 123);
  });

  $cb2 = frame(code => sub {
    return $foo;
  });

})->();

is($foo, 123);
$cb->();
is($foo, 123);
is($cb2->(), 234);
is($foo, 123);


is(scalar keys %$Callback::Frame::active_frames, 3);
$cb2 = undef;
is(scalar keys %$Callback::Frame::active_frames, 2);
$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
