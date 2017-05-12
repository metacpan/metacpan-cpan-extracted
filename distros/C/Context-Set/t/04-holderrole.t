#!perl -T
use strict;
use warnings;
use Test::More tests => 1;
use Test::Fatal qw/dies_ok lives_ok/;

package My::O;
use Moose;
with qw/Context::Set::Holder/;

sub _build_context{
  ## Returns the universe.
  return Context::Set->new();
}

1;

package main;

my $o = My::O->new();

ok( $o->context() , "Ok can access o context" );

done_testing();
