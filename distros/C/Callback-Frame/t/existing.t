use strict;

use Callback::Frame;
use Test::More tests => 11;

## This test verifies that you can run new code inside existing frames.

our $junkvar = 1;
my ($cb, $cb2);

ok(!$Callback::Frame::top_of_stack);

frame(name => "base frame",
      local => __PACKAGE__ . "::junkvar",
      code => sub {

  $junkvar = 2;

  $cb = frame(code => sub {
    return $junkvar;
  });

  $cb2 = frame(local => __PACKAGE__ . "::junkvar",
              code => sub {

    $junkvar = 10;
    die "BLAH BLAH";

  }, catch => sub {

    my $err = $@;
    die "OMG $@";

  });

}, catch => sub {

  my $err = $@;
  die "HELLO $@";

})->();


is(scalar keys %$Callback::Frame::active_frames, 3);

is($cb->(), 2);

my $val = frame(existing_frame => $cb,
                code => sub {
  return 1 + $junkvar;
})->();

is ($val, 3);

eval {
  frame(existing_frame => $cb,
        code => sub {
    die "WORLD";
  })->();
};

ok($@ =~ /HELLO WORLD/);


## $junkvar binding exists in $cb2 but since $cb2 hasn't been run yet, it hasn't been populated

$val = frame(existing_frame => $cb2,
             code => sub {
  return $junkvar;
})->();

is($val, undef);

eval {
  $cb2->();
};

ok($@ =~ /HELLO OMG BLAH BLAH/);

## now the $junkvar binding has been populated

$val = frame(existing_frame => $cb2,
             code => sub {
  return $junkvar;
})->();

is($val, 10);


eval {
  frame(existing_frame => $cb2,
        code => sub {
    die "EARTH";
  })->();
};

ok($@ =~ /HELLO OMG EARTH/);


$cb = undef;
is(scalar keys %$Callback::Frame::active_frames, 2);
$cb2 = undef;
is(scalar keys %$Callback::Frame::active_frames, 0);
