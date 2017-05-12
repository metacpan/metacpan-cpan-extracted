package CLIDTestClass::Single::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use CLIDTest::Single;
use Try::Tiny;

sub no_args : Test {
  my $class = shift;

  my $ret = $class->dispatch();

  ok $ret eq 'no args', $class->message("dispatch succeeded: $ret");
}

sub with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( one two three ));

  ok $ret eq 'onetwothree', $class->message("dispatch succeeded: $ret");
}

sub with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( --option=hello ));

  ok $ret eq 'hello', $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLIDTest::Single->run }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

1;
