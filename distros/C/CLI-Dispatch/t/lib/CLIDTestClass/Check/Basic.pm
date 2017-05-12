package CLIDTestClass::Check::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use CLI::Dispatch;
use Try::Tiny;

sub simple_dispatch : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( simple ));

  ok $ret =~ /for some reasons/, $class->message("dispatch succeeded: $ret");
}

sub simple_with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( with_args one two three ));

  ok $ret =~ /for some reasons/, $class->message("dispatch succeeded: $ret");
}

sub simple_with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( WithOptions --hello --target=world ));

  ok $ret =~ /for some reasons/, $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLI::Dispatch->run('CLIDTest::Check') }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

1;
