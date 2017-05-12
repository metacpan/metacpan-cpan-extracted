package junkpackage;

use strict;

use Callback::Frame;
use Test::More tests => 22; 


## This test verifies local bindings in the frame are backed up and
## restored properly. Also, it verifies local variable shadowing
## works OK and that you can install multiple local bindings in the
## same frame. 



our $junkvar = 1;
our $junkvar2;

sub global_junkvar_returner {
  return $junkvar;
}

my ($cb, $cb2, $cb3);

frame(local => 'junkpackage::junkvar',
      local => __PACKAGE__ . '::junkvar2',
      code => sub {

  is($junkvar, undef);
  is(global_junkvar_returner(), undef);
  is($junkvar2, undef);

  $junkvar = 5;
  $junkvar2 = 999;

  $cb = frame(local => 'junkpackage::junkvar2',
              code => sub {
    is($junkvar, 5);
    is($junkvar2, undef);

    $junkvar2 = 888;

    $cb2 = frame(code => sub {
      is($junkvar2, 234);

      undef $junkvar2;

      $cb3 = frame(code => sub {
        is($junkvar2, undef);
      });
    });

    $junkvar2 = 234;

    return 9876;
  });

  is($junkvar, 5);
  is($junkvar2, 999);

})->();


is($junkvar, 1);
is($junkvar2, undef);

is($cb->(), 9876);

is($junkvar, 1);
is($junkvar2, undef);

$cb2->();

is($junkvar, 1);
is($junkvar2, undef);

$cb3->();

is($junkvar, 1);
is($junkvar2, undef);




is(scalar keys %$Callback::Frame::active_frames, 4);
$cb2 = undef;
is(scalar keys %$Callback::Frame::active_frames, 4);
$cb3 = undef;
is(scalar keys %$Callback::Frame::active_frames, 2);
$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
