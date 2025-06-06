#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use App::sdview::Output::Tickit;

# Testing is simpler with a smaller window
my $term = mk_term lines => 10, cols => 30;

my $str = String::Tagged->new( "Some plain and " )
   ->append_tagged( "bold", bold => 1 )
   ->append_tagged( " text" );

my $rb = Tickit::RenderBuffer->new( lines => 10, cols => 30 );

{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => $str,
      indent => 0,
      margin_left => 4,
      margin_right => 2,
   );

   is( $item->height_for_width( 30 ), 1,
      'item is 1 line tall at width=30' );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4), TEXT("Some plain and "), TEXT("bold",b=>1), TEXT(" text")],
      ],
      'Display contains item initially' );

   clear_term;

   is( $item->height_for_width( 25 ), 2,
      'item is 2 lines tall at width=25' );

   $item->render( $rb,
      firstline => 0,
      lastline => 1,

      width => 25,
      height => 2,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4), TEXT("Some plain and "), TEXT("bold",b=>1)],
         [BLANK(4), TEXT("text")],
      ],
      'Display contains reflowed item' );
}

clear_term;

# RT150015
{
   use String::Tagged 0.23;  # bugfix

   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => String::Tagged->new( "A " )
         ->append_tagged( "B C", bold => 1 )
         ->append_tagged( " D E" ),
      indent => 0,
      margin_left => 0,
      margin_right => 0,
   );

   $item->height_for_width( 30 );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [TEXT("A "), TEXT("B C",b=>1), TEXT(" D E")],
      ],
      'Display contains correct formatting' );
}

clear_term;

# multiple spaces
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => String::Tagged->new( "A  B   C       D              E" ),
      indent => 0,
      margin_left => 1,
      margin_right => 1,
   );

   is( $item->height_for_width( 20 ), 1,
      'item is 1 line tall at width=20' );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 20,
      height => 1,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(1), TEXT("A B C D E")],
      ],
      'Display squashes multiple spaces' );
}

clear_term;

# nbsp
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => String::Tagged->new( "ABC DEF GHI\xA0JKL" ),
      indent => 0,
      margin_left => 4,
      margin_right => 2,
   );

   is( $item->height_for_width( 20 ), 2,
      'item is 2 lines tall at width=20' );

   $item->render( $rb,
      firstline => 0,
      lastline => 1,

      width => 20,
      height => 2,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4), TEXT("ABC DEF")],
         [BLANK(4), TEXT("GHI JKL")],
      ],
      'Display wraps item without breaking NBSP' );
}

clear_term;

# soft-hyphen
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => String::Tagged->new( "Here is a longly\xADhyphenated" ),
      indent => 0,
      margin_left => 0,
      margin_right => 0,
   );

   is( $item->height_for_width( 18 ), 2,
      'item is 2 lines tall at width=18' );

   $item->render( $rb,
      firstline => 0,
      lastline => 1,

      width => 18,
      height => 2,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [TEXT("Here is a longly-")],
         [TEXT("hyphenated")],
      ],
      'Display wraps item at soft-hyphen' );

   clear_term;

   is( $item->height_for_width( 30 ), 1,
      'item is 1 line tall at width=30' );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [TEXT("Here is a longlyhyphenated")],
      ],
      'Display hides soft-hyphen inline' );
}

clear_term;

# highlighting
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => $str,
      indent => 0,
      margin_left => 0,
      margin_right => 0,
   );

   $item->height_for_width( 30 );

   my @matches = $item->apply_highlight( qr/e/ );

   is( scalar @matches, 2, '->apply_highlight yields 2 matches' );
   my $match = $matches[0];
   ref_is( $match->[0], $item, 'match [0] is $item' );
   my $e = $match->[1];
   is( $e->start,  3,   '$e->start' );
   is( $e->length, 1,   '$e->length' );
   is( $e->substr, "e", '$e->substr' );

   is( $item->line_for_pos( $e ), 0,
      'match[0] is on line 0' );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   my @HLPEN = ( b=>1,bg=>5,fg=>16 );

   is_display( [
         [TEXT("Som"), TEXT("e",@HLPEN), TEXT(" plain and "), TEXT("bold",b=>1), TEXT(" t"), TEXT("e",@HLPEN), TEXT("xt")],
      ],
      'Display contains highlights' );

   $match->[2]++;

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   my @SELPEN = ( b=>1,bg=>2,fg=>16 );

   is_display( [
         [TEXT("Som"), TEXT("e",@SELPEN), TEXT(" plain and "), TEXT("bold",b=>1), TEXT(" t"), TEXT("e",@HLPEN), TEXT("xt")],
      ],
      'Display highlight selected' );
}

clear_term;

# indent
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      text => String::Tagged->new( "AAAAA " x 12 ),
      indent => 6,
      margin_left => 4,
      margin_right => 2,
   );

   is( $item->height_for_width( 30 ), 4, 'item is 4 lines tall at width=30' );

   $item->render( $rb,
      firstline => 0,
      lastline => 3,

      width => 30,
      height => 4,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4+6), TEXT("AAAAA AAAAA AAAAA")],
         [BLANK(4+6), TEXT("AAAAA AAAAA AAAAA")],
         [BLANK(4+6), TEXT("AAAAA AAAAA AAAAA")],
         [BLANK(4+6), TEXT("AAAAA AAAAA AAAAA")],
      ],
      'Display contains item indented' );
}

clear_term;

# leader (compact)
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      leader => String::Tagged->new( "*" ),
      text => String::Tagged->new( "the line contents" ),
      indent => 4,
      margin_left => 4,
      margin_right => 2,
   );

   is( $item->height_for_width( 30 ), 1, 'item is 1 lines tall at width=30' );

   $item->render( $rb,
      firstline => 0,
      lastline => 0,

      width => 30,
      height => 1,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4), TEXT("*   the line contents")],
      ],
      'Display contains item with leader (compact)' );
}

clear_term;

# leader (split)
{
   my $item = App::sdview::Output::Tickit::_ParagraphItem->new(
      leader => String::Tagged->new( "<===>" ),
      text => String::Tagged->new( "the line contents" ),
      indent => 4,
      margin_left => 4,
      margin_right => 2,
   );

   is( $item->height_for_width( 30 ), 2, 'item is 2 lines tall at width=30' );

   $item->render( $rb,
      firstline => 0,
      lastline => 1,

      width => 30,
      height => 2,
   );
   $rb->flush_to_term( $term );

   is_display( [
         [BLANK(4), TEXT("<===>")],
         [BLANK(4), TEXT("    the line contents")],
      ],
      'Display contains item with leader (split)' );
}

done_testing;
