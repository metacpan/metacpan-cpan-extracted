use strict;

use Callback::Frame;
use Test::More tests => 1;

## This test verifies the frame_try/frame_catch convenience interface.

my $callback;

frame_try {
  $callback = fub {
                die "some error";
              };
} frame_catch {
   my $err = $@;
   ok($err =~ /some error/);
   exit;
};

$callback->();

die "shouldn't get here";
