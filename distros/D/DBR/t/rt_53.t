#!/usr/bin/perl

use strict;

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 8;
use DBR::Config::Scope;

my $dbr = setup_schema_ok( 'rt_53' );

my $dbrh = $dbr->connect( 'rt_53' );
ok($dbrh, 'dbr connect');

# 2 tests so far, plus tests below

for my $pass (1..2) {      # 2x tests
  diag( "pass $pass:" );

  ok( my $all = $dbrh->a->all, "got all records" );

  my $next = $all->next;
  ok( ! $next->b->someval,   "Record 1, FK test value should be null" ); # Because there should be no record
  diag "ref: " . $next->b . " id: " . $next->b->id;

  $next = $all->next;
  ok(  $next->b->someval == 222 , "Record 2, FK test value should be 222" );
  diag "ref: " . $next->b . " id: " . $next->b->id;
}

1;

