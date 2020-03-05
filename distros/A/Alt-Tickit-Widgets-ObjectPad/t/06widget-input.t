#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Tickit::Test;

use Tickit::Widget;

my ( $term, $win ) = mk_term_and_window;

my @key_events;
my @mouse_events;
my $do_something_counter = 0;
my $widget = TestWidget->new;

is_oneref( $widget, '$widget has refcount 1 initially' );

$widget->set_window( $win );
$widget->take_focus;

flush_tickit;

ok( $term->cursorvis, 'Cursor visible on window' );

presskey( text => "A" );

is_deeply( \@key_events, [ [ text => "A" ] ], 'on_key A' );

pressmouse( press => 1, 4, 3 );

is_deeply( \@mouse_events, [ [ press => 1, 4, 3 ] ], 'on_mouse abs@3,4' );

presskey( key => "Enter" );

is( $do_something_counter, 1, '$do_something_counter after <Enter>' );

is_oneref( $widget, '$widget has refcount 1 at EOF' );

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use Tickit::Style;

use constant WIDGET_PEN_FROM_STYLE => 1;

use constant CAN_FOCUS => 1;

sub lines  { 1 }
sub cols   { 1 }

sub render_to_rb {}

sub window_gained
{
   my $self = shift;
   my ( $win ) = @_;
   $self->SUPER::window_gained( $win );

   $win->cursor_at( 0, 0 );
}

use constant KEYPRESSES_FROM_STYLE => 1;

BEGIN {
   style_definition base =>
      '<Enter>' => 'do_thing';
}

sub key_do_thing { $do_something_counter++ }

sub on_key
{
   my $self = shift;
   my ( $args ) = @_;
   push @key_events, [ $args->type => $args->str ];
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;
   push @mouse_events, [ $args->type => $args->button, $args->line, $args->col ];
}
