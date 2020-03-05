#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

my $lines = 1;
my $cols  = 5;
my $widget = TestWidget->new;
my $container = TestContainer->new;

my $changed = 0;
my $resized = 0;

ok( defined $container, 'defined $container' );

is_oneref( $widget, '$widget has refcount 1 initially' );
is_oneref( $container, '$container has refcount 1 initially' );

is( scalar $container->children, 0, 'scalar $container->children is 0' );
is_deeply( [ $container->children ], [], '$container->children empty' );

$container->add( $widget, foo => "bar" );

is_refcount( $widget, 2, '$widget has refcount 2 after add' );
is_oneref( $container, '$container has refcount 1 after add' );

is( $widget->parent, $container, '$widget->parent is container' );

is_deeply( { $container->child_opts( $widget ) }, { foo => "bar" }, 'child_opts in list context' );

is_deeply( scalar $container->child_opts( $widget ), { foo => "bar" }, 'child_opts in scalar context' );

is( $changed, 1, '$changed is 1' );

$container->set_child_opts( $widget, foo => "splot" );

is_deeply( { $container->child_opts( $widget ) }, { foo => "splot" }, 'child_opts after change' );

is( $changed, 2, '$changed is 2' );

is( scalar $container->children, 1, 'scalar $container->children is 1' );
is_deeply( [ $container->children ], [ $widget ], '$container->children contains widget' );

{
   $cols = 10;
   $widget->resized;

   is( $resized, 1, '$resized is 1 after child ->resized' );

   $widget->resized;

   is( $resized, 1, '$resized still 1 after no-op child ->resized' );

   $widget->set_requested_size( 2, 15 );

   is( $resized, 2, '$resized is 2 after child ->set_requested_size' );
}

$container->remove( $widget );

is( scalar $container->children, 0, 'scalar $container->children is 0' );
is_deeply( [ $container->children ], [], '$container->children empty' );

is( $widget->parent, undef, '$widget->parent is undef' );

is( $changed, 3, '$changed is 3' );

# child search
{
   my @widgets = map { TestWidget->new } 1 .. 4;

   $container->add( $_ ) for @widgets;

   identical( $container->find_child( first  => undef       ), $widgets[0], '->find_child first' );

   identical( $container->find_child( before => $widgets[2] ), $widgets[1], '->find_child before' );
   identical( $container->find_child( before => $widgets[0] ), undef,       '->find_child before first' );

   identical( $container->find_child( after  => $widgets[1] ), $widgets[2], '->find_child after' );
   identical( $container->find_child( after  => $widgets[3] ), undef,       '->find_child after last' );

   identical( $container->find_child( last   => undef       ), $widgets[3], '->find_child last' );

   identical( $container->find_child( after => $widgets[1], where => sub { $_ != $widgets[2] } ),
              $widgets[3],
              '->find_child where filter' );
}

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub render_to_rb {}

sub lines { $lines }
sub cols  { $cols  }

package TestContainer;

use base qw( Tickit::ContainerWidget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );
   $self->{children} = [];
   return $self;
}

sub render_to_rb {}

sub lines { 2 }
sub cols  { 10 }

sub children
{
   my $self = shift;
   return @{ $self->{children} }
}

sub add
{
   my $self = shift;
   my ( $child ) = @_;
   push @{ $self->{children} }, $child;
   $self->SUPER::add( @_ );
}

sub remove
{
   my $self = shift;
   my ( $child ) = @_;
   @{ $self->{children} } = grep { $_ != $child } @{ $self->{children} };
   $self->SUPER::remove( @_ );
}

sub child_resized { $resized++ }

sub children_changed { $changed++ }
