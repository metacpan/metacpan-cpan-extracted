package CLIDTestClass::Error::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use CLIDTest::Error;
use Try::Tiny;

sub simple_dispatch : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( simple ));

  return $class->abort_this_test('obscure error') if $ret eq 'Obscure error';

  ok $ret =~ /Compilation failed/, $class->message("dispatch succeeded: $ret");
}

sub simple_with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( with_args one two three ));

  return $class->abort_this_test('obscure error') if $ret eq 'Obscure error';

  ok $ret =~ /Compilation failed/, $class->message("dispatch succeeded: $ret");
}

sub simple_with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( WithOptions --hello --target=world ));

  return $class->abort_this_test('obscure error') if $ret eq 'Obscure error';

  ok $ret =~ /Compilation failed/, $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLIDTest::Error->run }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

1;
