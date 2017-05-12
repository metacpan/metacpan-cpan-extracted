use strict;

use Callback::Frame;
use Test::More tests => 16; 

## This test verifies that you can catch an error, then throw
## another error. The next deepest error handler will then be
## found and invoked, up until the point where there are no more
## handlers, then an unhandled die will be invoked.


my $cb;
my $counter = 0;


frame(code => sub {
  $cb = frame(code => sub {
    is($counter++, 1);
    die "ERR1";
  }, catch => sub {
    my $err = $@;
    is($counter++, 2);
    ok($err =~ /^ERR1/);
    die "ERR2 $@";
  })
}, catch => sub {
  my $err = $@;
  is($counter++, 3);
  ok($err =~ /^ERR2 ERR1/);
  die "ERR3 $@";
})->();


is($counter++, 0);
eval {
  $cb->();
};
my $err = $@;
ok($err =~ /^ERR3 ERR2 ERR1/);



frame(code => sub {
  $cb = frame(code => sub {
    is($counter++, 5);
    die "ERR1";
  }, catch => sub {
    my $err = $@;
    is($counter++, 6);
    ok($err =~ /^ERR1/);
    die "ERR2 $@";
  })
}, catch => sub {
  my $err = $@;
  is($counter++, 7);
  ok($err =~ /^ERR2 ERR1/);
})->();


is($counter++, 4);
$cb->();
is($counter++, 8);




is(scalar keys %$Callback::Frame::active_frames, 2);
$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
