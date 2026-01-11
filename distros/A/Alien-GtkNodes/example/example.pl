#!/usr/bin/env perl

use strict;
use warnings;

# Simple example ported from GtkNodes example.vala

BEGIN {
    if ( eval { require Alien::GtkNodes } ) {
        Alien::GtkNodes->init;
    }
}

use Gtk3 -init;
use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
    basename => 'GtkNodes',
    version => '0.1',
    package => 'GtkNodes',
);

my $window = Gtk3::Window->new('toplevel');
$window->set_title('Nodes demo');
$window->set_border_width( 10 );
$window->set_position('center');
$window->set_default_size( 300, 300 );
$window->signal_connect( destroy => sub { Gtk3::main_quit });

my $node_view = GtkNodes::NodeView->new;
my $node = GtkNodes::Node->new;
$node->set_label('Demo');

my $ilabel = Gtk3::Label->new('Input');
$ilabel->set_xalign( 0 );
my $input = $node->item_add( $ilabel, 'sink' );
$input->signal_connect( socket_connect => sub { $ilabel->set_label('connected') } );
$input->signal_connect( socket_disconnect => sub { $ilabel->set_label('disconnected') } );

my $olabel = Gtk3::Label->new('Output');
$olabel->set_xalign( 1 );
$node->item_add( $olabel, 'source' );

$node_view->add( $node );
$node->show;
$window->add( $node_view );

$window->show_all;
Gtk3::main;

