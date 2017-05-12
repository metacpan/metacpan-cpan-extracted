#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use AnyEvent;
use AnyEvent::Util qw( portable_pipe );

use AnyEvent::Tickit;

my $loop = AE::cv;

my ( $my_rd, $term_wr ) = portable_pipe or die "Cannot pipepair - $!";

my $tickit = AnyEvent::Tickit->new(
   term_out => $term_wr,
);

isa_ok( $tickit, 'AnyEvent::Tickit', '$tickit' );

done_testing;
exit;

{
   my $later;
   $tickit->later( sub { $later++ } );

   AnyEvent->_poll;

   is( $later, 1, '$later 1 after ->later' );
}

{
   my $sigwinch;

   no warnings 'redefine';
   local *Tickit::_SIGWINCH = sub {
      $sigwinch++;
   };

   kill SIGWINCH => $$;

   AnyEvent->_poll;

   is( $sigwinch, 1, '$sigwinch 1 after raise SIGWINCH' );
}

done_testing;
