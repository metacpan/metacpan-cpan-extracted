package CLIDTestClass::Sub::Subcmd;

use strict;
use warnings;
use Test::Classy::Base;
use CLI::Dispatch;
use Try::Tiny;

sub simple_dispatch : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( cmd simple_sub ));

  ok $ret eq 'simple subcommand', $class->message("dispatch succeeded: $ret");
}

sub simple_with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( cmd with_args_sub one two three four));

  ok $ret eq 'onetwothreefour', $class->message("dispatch succeeded: $ret");
}

sub simple_with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( cmd WithOptionsSub --subcommand --works=great ));

  ok $ret eq 'great subcommand', $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLI::Dispatch->run('CLIDTest::Sub') }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

1;
