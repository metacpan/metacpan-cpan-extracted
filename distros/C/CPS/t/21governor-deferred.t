#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;

use CPS::Governor::Deferred;

my $gov = CPS::Governor::Deferred->new;

ok( defined $gov, 'defined $gov' );
isa_ok( $gov, "CPS::Governor", '$gov' );

ok( !$gov->is_pending, '$gov not yet pending' );

my $called = 0;
$gov->again( sub { $called = 1 } );

ok( $gov->is_pending, '$gov now pending' );
is( $called, 0, '$called still 0' );

$gov->prod;

ok( !$gov->is_pending, '$gov no longer pending after prod' );
is( $called, 1, '$called is 1 after prod' );

$gov->again( sub {
   $called = 2;
   $gov->again( sub {
      $called = 3;
   } );
} );

$gov->prod;

ok( $gov->is_pending, '$gov is still pending after again-in-again' );
is( $called, 2, '$called is 2 after-in-again' );

$gov->prod;

ok( !$gov->is_pending, '$gov no longer pending after inner again' );
is( $called, 3, '$called is 3 after inner again' );

$gov->again( sub {
   $called = 4;
   $gov->again( sub {
      $called = 5;
   } );
} );

$gov->flush;

ok( !$gov->is_pending, '$gov no longer pending after flush' );
is( $called, 5, '$called is 5 after flush' );

$gov = CPS::Governor::Deferred->new( defer_after => 3 );

$called = 0;
sub more
{
   $called >= 6 and return;
   $called++;

   $gov->again( \&more );
}

more();

is( $called, 3, '$called is 3 after first again' );

$gov->prod;

is( $called, 6, '$called is 6 after poke' );
