#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Future;

# $cv->send
{
   my $f = AnyEvent::Future->from_cv( my $cv = AnyEvent->condvar );

   ok( !$f->is_ready, '$future not yet ready before $cv->send' );

   $cv->send( result => "here" );

   ok( $f->is_ready, '$future is now ready after $cv->send' );
   is_deeply( [ $f->get ], [ result => "here" ], '$future->get' );
}

# $cv->croak
{
   my $f = AnyEvent::Future->from_cv( my $cv = AnyEvent->condvar );

   $cv->croak( "It has failed" );

   ok( $f->is_ready, '$future is now ready after $cv->send' );

   # AnyEvent::CondVar->croak always seems to append file/line even with \n
   like( scalar $f->failure, qr/^It has failed at .* line \d+\.?$/,
      '$future->failure' );
}

# existing cb is undisturbed
{
   my $called = 0;
   my $cv = AnyEvent->condvar( cb => sub { $called++ } );

   my $f = AnyEvent::Future->from_cv( $cv );

   $cv->send;

   is( $called, 1, '$called now 1 after ->send' );
   ok( $f->is_ready, '$future now ready after ->send with cb replacement' );
}

# $f->as_cv done
{
   my $f = AnyEvent::Future->new;
   my $cv = $f->as_cv;

   $f->done( result => "here" );

   is_deeply( [ $cv->recv ], [ result => "here" ], '$cv->recv after $f->done' );
}

# $f->as_cv fail
{
   my $f = AnyEvent::Future->new;
   my $cv = $f->as_cv;

   $f->fail( "The failure message here" );

   ok( !eval { $cv->recv; 1 }, '$cv->recv dies' );
   like( $@, qr/The failure message here at .* line \d+\.?$/, '$cv->recv exception' );
}

done_testing;
