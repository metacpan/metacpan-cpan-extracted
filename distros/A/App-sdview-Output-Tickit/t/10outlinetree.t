#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use App::sdview::Output::Tickit;

# Testing is simpler with a smaller window
mk_term lines => 10, cols => 30;
my $win = mk_window;

my $outlinetree = App::sdview::Output::Tickit::_OutlineTree->new;

# Some testing items
$outlinetree->add_item( "HEAD1",       1,  0 );
$outlinetree->add_item( "Subhead 1.1", 2,  3 );
$outlinetree->add_item( "Subhead 1.2", 2,  6 );
$outlinetree->add_item( "HEAD2",       1, 10 );
$outlinetree->add_item( "Subhead 2.1", 2, 15 );
$outlinetree->add_item( "HEAD3",       1, 20 );

$outlinetree->set_current_itemidx( 0 );
$outlinetree->set_window( $win );

my %selected_args;
$outlinetree->set_on_select_item( sub { %selected_args = @_ } );

# initial
{
   flush_tickit;

   is_display( [ [TEXT(">HEAD1        ",b=>1,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 1.1",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 1.2",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT(" HEAD2        ",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 2.1",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT(" HEAD3        ",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 ([BLANK(29,bg=>4), TEXT("│",bg=>4)]) x 3,
                 [TEXT("Type to search",i=>1,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
              ], 'Display initially' );
}

# current position marker
{
   $outlinetree->set_current_itemidx( 10 );
   flush_tickit;

   is_display( [ [TEXT(" HEAD1        ",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 1.1",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 1.2",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT(">HEAD2        ",b=>1,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT("   Subhead 2.1",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 [TEXT(" HEAD3        ",b=>0,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
                 ([BLANK(29,bg=>4), TEXT("│",bg=>4)]) x 3,
                 [TEXT("Type to search",i=>1,bg=>4), BLANK(15,bg=>4), TEXT("│",bg=>4)],
              ], 'Display after ->set_current_itemidx' );
}

# click to select
{
   pressmouse press => 1, 2, 4;
   is( \%selected_args, { itemidx => 6 }, 'mouse event invokes on_select_item' );
}

# type to filter/highlight
{
   $outlinetree->take_focus;
   presskey text => "3";
   flush_tickit;

   is_display( [ [TEXT(" HEAD",bg=>4), TEXT("3",bg=>3,fg=>0), BLANK(23,bg=>4), TEXT("│",bg=>4)],
                 ([BLANK(29,bg=>4), TEXT("│",bg=>4)]) x 8,
                 [TEXT("Search: 3",bg=>4), BLANK(20,bg=>4), TEXT("│",bg=>4)],
              ], 'Display after filtering keypress' );

   presskey key => "Enter";
   flush_tickit;

   is( \%selected_args, { itemidx => 20 }, 'Enter key invokes on_select_item' );
}

done_testing;
