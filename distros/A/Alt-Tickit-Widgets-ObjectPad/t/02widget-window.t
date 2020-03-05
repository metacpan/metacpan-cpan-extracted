#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

use Tickit::Widget;

my $win = mk_window;

my $gained_window;
my $lost_window;
my $render_rect;
my $widget = TestWidget->new;

is_oneref( $widget, '$widget has refcount 1 initially' );

identical( $widget->window, undef, '$widget->window initally' );

$widget->set_window( $win );

flush_tickit;

identical( $widget->window, $win, '$widget->window after set_window' );

identical( $gained_window, $win, '$widget->window_gained called' );

is( $render_rect,
    Tickit::Rect->new( top => 0, left => 0, lines => 25, cols => 80 ),
    '$rect to ->render_to_rb method' );

is_display( [ [TEXT("Hello")] ],
            'Display initially' );

$widget->set_window( undef );

identical( $lost_window, $win, '$widget->window_lost called' );

is_oneref( $widget, '$widget has refcount 1 at EOF' );

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub render_to_rb
{
   my $self = shift;
   ( my $rb, $render_rect ) = @_;

   $rb->text_at( 0, 0, "Hello" );
}

sub lines { 1 }
sub cols  { 5 }

sub window_gained
{
   my $self = shift;
   ( $gained_window ) = @_;
   $self->SUPER::window_gained( @_ );
}

sub window_lost
{
   my $self = shift;
   ( $lost_window ) = @_;
   $self->SUPER::window_lost( @_ );
}
