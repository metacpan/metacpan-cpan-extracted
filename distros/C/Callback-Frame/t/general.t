use strict;

use Callback::Frame;
use Test::More tests => 29; 


## This test exercises general functionality related to
## exception handlers.
##   * errors can be caught
##   * stack traces are generated correctly
##   * is_frame can identify frames
##   * resources are cleaned up
##   * Callback::Frame::top_of_stack mainained correctly



my ($cb, $cb2, $cb3);
my $counter = 0;
my $tos_at_error_site;


ok(!$Callback::Frame::top_of_stack);

frame(name => "base frame", code => sub {
  ok($Callback::Frame::top_of_stack);
  is($counter++, 0);

  $cb = frame(name => "frame 1", code => sub {
    is($counter++, 2);
    ok($_[0] == 123);

    $cb2 = frame(code => sub {
      is($counter++, 4);
      $cb3 = frame(name => "frame 3", code => sub {
        is($counter++, 6);
        $tos_at_error_site = $Callback::Frame::top_of_stack;
        die "OUCH";
      });
    });
  }, catch => sub {
    my $err = $@;
    my $stack_trace = shift;

    is($counter++, 7);
    ok($tos_at_error_site == $Callback::Frame::top_of_stack);

    ok($err =~ /^OUCH(?!.*ANONYMOUS)/);
    ok($stack_trace =~ /^OUCH.*?frame 3.*?ANONYMOUS FRAME.*?frame 1.*?base frame/s);
  })
})->();

ok(!$Callback::Frame::top_of_stack);

is($counter++, 1);
$cb->(123);
is($counter++, 3);
$cb2->();
is($counter++, 5);
$cb3->();
is($counter++, 8);

ok(!$Callback::Frame::top_of_stack);


## is_frame

ok(!Callback::Frame::is_frame($tos_at_error_site));
ok(Callback::Frame::is_frame($cb));
ok(Callback::Frame::is_frame($cb2));
ok(Callback::Frame::is_frame($cb3));
ok(!Callback::Frame::is_frame("$cb"));
ok(!Callback::Frame::is_frame($cb + 0));
ok(!Callback::Frame::is_frame(sub { }));

## Verify resource cleanup

is(scalar keys %$Callback::Frame::active_frames, 4);
$tos_at_error_site = undef;
is(scalar keys %$Callback::Frame::active_frames, 4);
$cb3 = undef;
is(scalar keys %$Callback::Frame::active_frames, 3);
$cb2 = undef;
is(scalar keys %$Callback::Frame::active_frames, 2);
$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
