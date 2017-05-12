#!/usr/bin/perl

use strict;

use Test::More tests => 1;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use CPS::Future;

# Callable
{
   my $future = CPS::Future->new;

   my @on_done_args;
   $future->on_done( sub { @on_done_args = @_ } );

   $future->( another => "result" );

   is_deeply( \@on_done_args, [ another => "result" ], '$future is directly callable' );
}
