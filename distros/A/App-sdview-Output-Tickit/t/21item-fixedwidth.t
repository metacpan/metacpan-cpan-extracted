#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use App::sdview::Output::Tickit;

# Testing is simpler with a smaller window
my $term = mk_term lines => 10, cols => 30;

my $rb = Tickit::RenderBuffer->new( lines => 10, cols => 30 );

{
   my $item = App::sdview::Output::Tickit::_FixedWidthItem->new(
      text => String::Tagged->new( "Here are\nthree lines\nof content" ),
   );

   is( $item->height_for_width( 30 ), 3, 'item is 3 lines tall' );

   is( $item->line_for_char( 5 ), 0,
      'char 5 is on line 0' );
   is( $item->line_for_char( 15 ), 1,
      'char 15 is on line 1' );

   $item->render( $rb,
      firstline => 0,
      lastline => 2,

      width => 30,
      height => 3,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [TEXT("Here are")],
         [TEXT("three lines")],
         [TEXT("of content")],
      ],
      'Display contains item initially' );
}

clear_term;

# highlighting
{
   my $item = App::sdview::Output::Tickit::_FixedWidthItem->new(
      text => String::Tagged->new( "abcd\nefgh\nabcd\nefgh" ),
   );

   my @matches = $item->apply_highlight( qr/e/ );

   is( scalar @matches, 2, '->apply_highlight yields 2 matches' );
   my $match = $matches[0];
   ref_is( $match->[0], $item, 'match [0] is $item' );
   my $e = $match->[1];
   is( $e->start,  5,   '$e->start' );
   is( $e->length, 1,   '$e->length' );
   is( $e->substr, "e", '$e->substr' );

   $item->render( $rb,
      firstline => 0,
      lastline => 3,

      width => 30,
      height => 4,
   );
   $rb->flush_to_term( $term );

   my @HLPEN = ( b=>1,bg=>5,fg=>16 );

   is_display( [
         [TEXT("abcd")],
         [TEXT("e", @HLPEN), TEXT("fgh")],
         [TEXT("abcd")],
         [TEXT("e", @HLPEN), TEXT("fgh")],
      ],
      'Display contains highlights' );

   $match->[2]++;

   $item->render( $rb,
      firstline => 0,
      lastline => 3,

      width => 30,
      height => 4,
   );
   $rb->flush_to_term( $term );

   my @SELPEN = ( b=>1,bg=>2,fg=>16 );

   is_display( [
         [TEXT("abcd")],
         [TEXT("e", @SELPEN), TEXT("fgh")],
         [TEXT("abcd")],
         [TEXT("e", @HLPEN), TEXT("fgh")],
      ],
      'Display highlight selected' );
}

done_testing;
