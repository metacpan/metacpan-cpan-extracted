package CLIDTestClass::Single::Help;

use strict;
use warnings;
use Test::Classy::Base;
use CLIDTest::Single;
use File::Spec;
use Try::Tiny;

sub help_command : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( help ));

  ok $ret eq 'help', $class->message('help command is ignored');
}

sub help_option : Tests(2) {
  my $class = shift;

  my $ret = $class->dispatch(qw( --help ));

  ok $ret =~ /single command test/, $class->message('has description');
  ok $ret !~ /dump me/, $class->message('name section is removed');
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  open my $null, '>', File::Spec->devnull;
  my $stdout = select($null);

  my $ret;
  try   { $ret = CLIDTest::Single->run }
  catch { $ret = $_ || 'Obscure error' };

  select($stdout);

  return $ret;
}

1;
