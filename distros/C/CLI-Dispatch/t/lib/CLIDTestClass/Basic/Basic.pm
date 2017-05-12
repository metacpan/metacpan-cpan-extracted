package CLIDTestClass::Basic::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use CLI::Dispatch;
use Try::Tiny;

sub simple_dispatch : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( simple ));

  ok $ret eq 'simple', $class->message("dispatch succeeded: $ret");
}

sub simple_with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( with_args one two three ));

  ok $ret eq 'onetwothree', $class->message("dispatch succeeded: $ret");
}

sub simple_with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( WithOptions --hello --target=world ));

  ok $ret eq 'hello world', $class->message("dispatch succeeded: $ret");
}

sub simple_sub_new : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( sub_new ));

  ok $ret eq '/var/tmp/', $class->message("dispatch succeeded: $ret");
}

sub simple_sub_new_with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( sub_new_with_options --path=/tmp/));

  ok $ret =~ /override path by a command argument/, $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLI::Dispatch->run('CLIDTest::Basic') }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

1;
