#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

use IO::Async::Loop;

use CPS::Governor::IOAsync;

my $loop = IO::Async::Loop->new;

my $gov = CPS::Governor::IOAsync->new( loop => $loop );

my $called = 0;
$gov->again( sub { $called = 1 } );

ok( $gov->is_pending, '$gov now pending' );
is( $called, 0, '$called still 0' );

$loop->loop_once( 0 );

ok( !$gov->is_pending, '$gov no longer pending after loop_once' );
is( $called, 1, '$called is 1 after loop_once' );

$gov->again( sub {
   $called = 2;
   $gov->again( sub {
      $called = 3;
   } );
} );

$loop->loop_once( 0 );

ok( $gov->is_pending, '$gov is still pending after again-in-again' );
is( $called, 2, '$called is 2 after-in-again' );

$loop->loop_once( 0 );

ok( !$gov->is_pending, '$gov no longer pending after inner again' );
is( $called, 3, '$called is 3 after inner again' );
