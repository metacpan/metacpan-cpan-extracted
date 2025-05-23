#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::CheckListEditor 1.379;

use strict;
use warnings;
use Carp;
use 5.10.1;

use base qw/ Tk::Frame Config::Model::Tk::CheckListViewer/;
use vars qw/$icon_path/;
use subs qw/menu_struct/;

use Tk::NoteBook;
use Config::Model::Tk::NoteEditor;
use Log::Log4perl;

Construct Tk::Widget 'ConfigModelCheckListEditor';

my $up_img;
my $down_img;
my $logger = Log::Log4perl::get_logger("Tk::CheckListEditor");

*icon_path = *Config::Model::TkUI::icon_path;

my @fbe1 = qw/-fill both -expand 1/;
my @fxe1 = qw/-fill    x -expand 1/;
my @fx   = qw/-fill    x /;

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item}
        || die "CheckListEditor: no -item, got ", keys %$args;
    delete $args->{-path};
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__, "no -store_cb";
    my $cme_font = delete $args->{-font};

    my $inst = $leaf->instance;

    $cw->add_header( Edit => $leaf )->pack(@fx);

    my $nb = $cw->Component( 'NoteBook', 'notebook' )->pack(@fbe1);

    my $lb;
    my @choice    = $leaf->get_choice;
    my $raise_cmd = sub {
        $lb->selectionClear( 0, 'end' );
        my %h = $leaf->get_checked_list_as_hash;
        for ( my $i = 0 ; $i < @choice ; $i++ ) {
            $lb->selectionSet( $i, $i ) if $h{ $choice[$i] };
        }
    };

    my $ed_frame = $nb->add(
        'content',
        -label    => 'Change content',
        -raisecmd => $raise_cmd,
    );

    $lb = $ed_frame->Scrolled(
        qw/Listbox -selectmode multiple/,
        -scrollbars => 'osoe',
        -height     => 5,
    )->pack(@fbe1);
    $lb->insert( 'end', @choice );

    # setup item help change when mouse hovers listbox items
    my $b_sub = sub {
        my $index = $lb->nearest($lb->pointery - $lb->rooty);
        state $selected;
        $selected //= '';
        if ($selected ne $choice[$index]) {
            $selected = $choice[$index];
            $cw->set_value_help($selected);
        }
    };
    $lb->bind( '<Motion>', $b_sub );

    my $bframe = $ed_frame->Frame->pack;
    $bframe->Button(
        -text    => 'Clear all',
        -command => sub { $lb->selectionClear( 0, 'end' ); },
    )->pack( -side => 'left' );
    $bframe->Button(
        -text    => 'Set all',
        -command => sub { $lb->selectionSet( 0, 'end' ); },
    )->pack( -side => 'left' );
    $bframe->Button(
        -text    => 'Reset',
        -command => sub { $cw->reset_value; },
    )->pack( -side => 'left' );
    $bframe->Button(
        -text    => 'Store',
        -command => sub { $cw->store() },
    )->pack( -side => 'left' );

    $cw->ConfigModelNoteEditor( -object => $leaf )->pack(@fbe1);
    $cw->add_summary($leaf)->pack(@fx);
    $cw->add_description($leaf)->pack(@fbe1);
    my ( $help_frame, $help_widget ) = $cw->add_help( value => '', 1 );
    $help_frame->pack(@fx);
    $cw->{value_help_widget} = $help_widget;
    $cw->add_info_button()->pack(@fxe1);

    # Add a second page to edit the list order for ordered check list
    if ( $leaf->ordered ) {
        $cw->add_change_order_page( $nb, $leaf );
    }

    $cw->Advertise( 'listbox' => $lb );
    $cw->ConfigSpecs(-font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],);

    # don't call directly SUPER::Populate as it's CheckListViewer's populate
    $cw->Tk::Frame::Populate($args);
}

sub add_change_order_page {
    my ( $cw, $nb, $leaf ) = @_;

    my $order_list;
    my $raise_cmd = sub {
        $order_list->delete( 0, 'end' );
        $order_list->insert( end => $leaf->get_checked_list );
    };

    my $order_frame = $nb->add(
        'order',
        -label    => 'Change order',
        -raisecmd => $raise_cmd,
    );

    $order_list = $order_frame->Scrolled(
        'Listbox',
        -selectmode => 'single',
        -scrollbars => 'oe',
        -height     => 6,
    )->pack(@fbe1);

    $cw->{order_list} = $order_list;

    unless ( defined $up_img ) {
        $up_img   = $cw->Photo( -file => $icon_path . 'up.png' );
        $down_img = $cw->Photo( -file => $icon_path . 'down.png' );
    }

    my $mv_up_down_frame = $order_frame->Frame->pack( -fill => 'x' );
    $mv_up_down_frame->Button(
        -image   => $up_img,
        -command => sub { $cw->move_selected_up; },
    )->pack( -side => 'left', @fxe1 );

    $mv_up_down_frame->Button(
        -image   => $down_img,
        -command => sub { $cw->move_selected_down; },
    )->pack( -side => 'left', @fxe1 );
}

sub move_selected_up {
    my $cw         = shift;
    my $order_list = $cw->{order_list};
    my @idx        = $order_list->curselection();

    return unless @idx and $idx[0] > 0;

    my $name = $order_list->get(@idx);

    $order_list->delete(@idx);
    my $new_idx = $idx[0] - 1;
    $order_list->insert( $new_idx, $name );
    $order_list->selectionSet($new_idx);
    $order_list->see($new_idx);

    $cw->{leaf}->move_up($name);

    $cw->{store_cb}->();
}

sub move_selected_down {
    my $cw         = shift;
    my $order_list = $cw->{order_list};
    my @idx        = $order_list->curselection();
    my $leaf       = $cw->{leaf};
    my @h_idx      = $leaf->get_checked_list;

    return unless @idx and $idx[0] < $#h_idx;

    my $name = $order_list->get(@idx);
    $logger->debug("move_selected_down: $name (@idx)");

    $order_list->delete(@idx);
    my $new_idx = $idx[0] + 1;
    $order_list->insert( $new_idx, $name );
    $order_list->selectionSet($new_idx);
    $order_list->see($new_idx);

    $cw->{leaf}->move_down($name);

    $cw->{store_cb}->();
}

sub store {
    my $cw = shift;

    my $lb     = $cw->Subwidget('listbox');
    my @choice = $cw->{leaf}->get_choice;

    my %set = map { $_ => 1; } map { $choice[$_] } $lb->curselection;
    my $cl = $cw->{leaf};

    foreach my $c (@choice) {
        if ( $set{$c} and not $cl->is_checked($c) ) {
            $cl->check($c);
        }
        elsif ( not $set{$c} and $cl->is_checked($c) ) {
            $cl->uncheck($c);
        }
    }

    $cw->{store_cb}->();
}

sub reset_value {
    my $cw = shift;

    my $h_ref = $cw->{leaf}->get_checked_list_as_hash;

    # reset also the content of the listbox
    # weird behavior of tied Listbox :-/
    ${ $cw->{tied} } = $cw->{leaf}->get_checked_list;

    # the CheckButtons have stored the reference of the hash *values*
    # so we must preserve them.
    map { $cw->{check_list}{$_} = $h_ref->{$_} } keys %$h_ref;
    $cw->{help} = '';
}


1;
