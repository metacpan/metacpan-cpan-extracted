#!/sw/bin/perl

use strict;
use warnings;
use Test::More;

eval 'use IO::Scalar';
plan(skip_all => 'IO::Scalar required for test') if $@;

Test::Class->runtests;

package Test::DebugPrint;

use base qw(Test::Class);
use Test::More;
use Config::Validate;

sub debug_print :Test {
  my $buffer;
  my $sh = IO::Scalar->new(\$buffer);

  my $cv = Config::Validate->new;

  my $oldfh = select;
  select($sh);
  $cv->_debug_print("Test", " Message");
  select($oldfh);
  is($buffer, "Test Message\n", "debug_print printed the right message");

  return;
}
