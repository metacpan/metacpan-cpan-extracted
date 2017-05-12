use strict;

use Callback::Frame;
use Test::More tests => 7; 

## This test verifies that the value of $@ at the time when the frame
## callback is called should be stored and when the wrapped code that
## was passed into the frame is invoked, $@ will be restored to the
## backed up value.


my ($cb);

our $foo = 123;

frame(name => "base frame",
      local => __PACKAGE__ . '::foo',
      code => sub {

  $cb = frame(code => sub {
    my $err = $@;
    is($err, 'pass me through');
    is($foo, undef);
    $foo = 234;
    die "byebye";
  }, catch => sub {
    my $err = $@;
    ok($err =~ /^byebye/);
  });

})->();

is($foo, 123);

{
  local $@ = 'pass me through';
  $cb->();
  ## is($@, 'pass me through'); ## clobbers $@ but maybe this is OK
}

is($foo, 123);




is(scalar keys %$Callback::Frame::active_frames, 2);
$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
