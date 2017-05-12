#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Future qw( as_future as_future_cb );

{
   my $future = AnyEvent::Future->new;

   AnyEvent::postpone { $future->done( "result" ) };

   is_deeply( [ $future->get ], [ "result" ], '$future->get on AnyEvent::Future' );
}

# as_future
{
   my $future = as_future {
      my $f = shift;
      AnyEvent::postpone { $f->done( "another result" ) };
   };

   is_deeply( [ $future->get ], [ "another result" ], '$future->get on as_future' );
}

# as_future cancellation
{
   my $called;
   my $future = as_future {
      my $f = shift;
      return AnyEvent->timer(
         after => 0.01,
         cb => sub { $called++; $f->done; },
      );
   };

   $future->cancel;

   my $cv = AnyEvent->condvar;
   my $tmp = AnyEvent->timer( after => 0.03, cb => sub { $cv->send } );
   $cv->recv;

   ok( !$called, '$future->cancel cancels a pending watch' );
}

# as_future_cb done
{
   my $future = as_future_cb {
      my ( $done ) = @_;
      AnyEvent::postpone { $done->( "success" ) };
   };

   is_deeply( [ $future->get ], [ "success" ], '$future->get on as_future_cb done' );
}

# as_future fail
{
   my $future = as_future_cb {
      my ( $done, $fail ) = @_;
      AnyEvent::postpone { $fail->( "It failed!" ) };
   };

   $future->await;
   is_deeply( [ $future->failure ], [ "It failed!" ], '$future->failure on as_future_cb fail' );
}

done_testing;
