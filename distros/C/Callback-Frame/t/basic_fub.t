use strict;

use Callback::Frame;
use Test::More tests => 5;

## This test verifies basic functionality using the "fub" interface.

our $junkvar = 1;

ok(!$Callback::Frame::top_of_stack);

my $frame = fub {

  die "ERROR" if $_[0] && $_[0] eq 'die';

  return $junkvar;

} name => "base frame",
  local => __PACKAGE__ . "::junkvar",
  catch => sub {

    my $err = $@;
    die "NEW ERROR";

};


is(scalar keys %$Callback::Frame::active_frames, 1);

is($frame->(), undef);

eval {
  $frame->('die');
};

ok($@ =~ /NEW ERROR/);

$frame = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
