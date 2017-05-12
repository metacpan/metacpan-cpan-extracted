#!/usr/bin/perl

use Test;
BEGIN { plan tests => 4 }

use Benchmark::Forking 'cmpthese';
ok( 1 );

########################################################################

@global = qw( foo );
cmpthese( 100, {
  "test_1" => sub { push @global, 'bar' },
  "test_2" => sub { push @global, 'baz' },
}, 'none' );

ok( scalar @global == 1 );

########################################################################

Benchmark::Forking->disable();

@global = qw( foo );
cmpthese( 100, {
  "test_1" => sub { push @global, 'bar' },
  "test_2" => sub { push @global, 'baz' },
}, 'none' );

ok( scalar @global == 201 );

########################################################################

Benchmark::Forking->enable();

@global = qw( foo );
cmpthese( 100, {
  "test_1" => sub { push @global, 'bar' },
  "test_2" => sub { push @global, 'baz' },
}, 'none' );

ok( scalar @global == 1 );
