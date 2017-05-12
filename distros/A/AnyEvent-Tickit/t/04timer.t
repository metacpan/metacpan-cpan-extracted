#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw( time );

use AnyEvent;
use AnyEvent::Util qw( portable_pipe );

use AnyEvent::Tickit;

my $loop = AE::cv;

my ( $my_rd, $term_wr ) = portable_pipe or die "Cannot pipepair - $!";

my $tickit = AnyEvent::Tickit->new(
   cv => $loop,
   term_out => $term_wr,
);

{
   my $tick;
   $tickit->timer( after => 0.1, sub { $tick++ } );

   do { AnyEvent->_poll } until $tick;
   is( $tick, 1, '$tick 1 after "after" timer' );

   $tickit->timer( at => time() + 0.1, sub { $tick++ } );

   do { AnyEvent->_poll } until $tick == 2;
   is( $tick, 2, '$tick 2 after "at" timer' );
}

done_testing;
