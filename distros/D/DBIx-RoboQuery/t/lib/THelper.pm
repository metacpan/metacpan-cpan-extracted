# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
package THelper;

# NOTE: Would use Test::Fatal if we were already using Try::Tiny

our $ExModule = 'Test::Exception';

sub no_ex_module (&@) {
  SKIP: {
    package main;
    skip("$THelper::ExModule required to test exceptions", 1);
  }
}

{
  my @subs = qw(
    throws_ok
  );
  package main;
  eval "require $THelper::ExModule; $THelper::ExModule->import(); 1";
  if( $@ ){
    no strict 'refs';
    *$_ = *THelper::no_ex_module for @subs;
  }
}

1;
