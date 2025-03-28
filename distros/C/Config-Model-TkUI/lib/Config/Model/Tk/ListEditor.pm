#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::ListEditor 1.379;

use strict;
use warnings;
use Carp;
use Log::Log4perl;

use base qw/Config::Model::Tk::ListViewer/;
use subs qw/menu_struct/;
use vars qw/$icon_path/;
use Config::Model::Tk::NoteEditor;
use Config::Model::Tk::CmeDialog;

Construct Tk::Widget 'ConfigModelListEditor';

my @fbe1   = qw/-fill both -expand 1/;
my @fxe1   = qw/-fill x    -expand 1/;
my @fx     = qw/-fill    x /;
my $logger = Log::Log4perl::get_logger("Tk::ListEditor");

my ( $up_img, $down_img, $eraser_img, $remove_img, $sort_img );
*icon_path = *Config::Model::TkUI::icon_path;

my $entry_width = 20;

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.
    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;

    my $list = $cw->{list} = delete $args->{-item}
        || die "ListEditor: no -item, got ", keys %$args;

    delete $args->{-path};
    my $cme_font = delete $args->{-font};

    $cw->{store_cb} = delete $args->{-store_cb}
        or die __PACKAGE__, "no -store_cb";

    unless ( defined $up_img ) {
        $up_img     = $cw->Photo( -file => $icon_path . 'up.png' );
        $down_img   = $cw->Photo( -file => $icon_path . 'down.png' );
        $eraser_img = $cw->Photo( -file => $icon_path . 'eraser.png' );
        $remove_img = $cw->Photo( -file => $icon_path . 'remove.png' );
        $sort_img   = $cw->Photo( -file => $icon_path . 'dbgrun.png' );
    }

    $cw->add_header( Edit => $list )->pack(@fx);

    my $balloon = $cw->Balloon( -state => 'balloon' );

    my $inst = $list->instance;

    my $value_type = $list->get_cargo_info('value_type');    # may be undef

    my $elt_button_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fbe1);
    my $frame_title      = $list->element_name;
    $frame_title .= ( defined $value_type and $value_type =~ /node/ ) ? ' elements' : ' list';
    $elt_button_frame->Label( -text => $frame_title )->pack();

    my $tklist = $elt_button_frame->Scrolled(
        'Listbox',
        -selectmode => 'single',
        -scrollbars => 'oe',
        -height     => 8,
    )->pack(@fbe1);

    $balloon->attach(
        $tklist,
        -msg => 'select an element and perform an action with one of the buttons below'
    );

    my $right_frame = $elt_button_frame->Frame->pack( @fxe1, qw/-side right -anchor n/ );

    $cw->ConfigModelNoteEditor( -object => $list )->pack;
    $cw->add_summary($list)->pack(@fx);
    $cw->add_description($list)->pack(@fbe1);
    $cw->add_warning( $list, 'edit' )->pack(@fx);
    $cw->add_info_button($cw)->pack(@fx);

    my $mv_rm_frame = $right_frame->Frame->pack(@fx);

    my $move_up_b = $mv_rm_frame->Button(
        -image   => $up_img,
        -command => sub { $cw->move_up; },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $move_up_b, -msg => 'Move selected element up the list' );

    my $move_down_b = $mv_rm_frame->Button(
        -image   => $down_img,
        -command => sub { $cw->move_down; },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $move_down_b, -msg => 'Move selected element down the list' );

    my $eraser_b = $mv_rm_frame->Button(
        -image   => $eraser_img,
        -command => sub { $cw->remove_selection; },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $eraser_b, -msg => 'Remove selected element from the list' );

    my $rm_all_b = $mv_rm_frame->Button(
        -image   => $remove_img,
        -command => sub {
            $list->clear;
            $tklist->delete( 0, 'end' );
            $cw->{store_cb}->();
        },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $rm_all_b, -msg => 'Remove all elements from the list' );

    my $cargo_type = $list->cargo_type;

    if ( $cargo_type eq 'leaf' ) {
        my $sort_b = $mv_rm_frame->Button(
            -image   => $sort_img,
            -command => sub { $cw->sort_content } )->pack( -side => 'left', @fxe1 );
        $balloon->attach( $sort_b, -msg => 'Sort all elements in the list' );
    }

    if (    $cargo_type eq 'leaf'
        and $value_type ne 'enum'
        and $value_type ne 'reference' ) {
        my $set_push_b_entry_frame =
            $right_frame->Frame( -borderwidth => 2, -relief => 'groove' )->pack(@fxe1);
        my $user_value;
        my $value_entry = $set_push_b_entry_frame->Entry(
            -textvariable => \$user_value,
            -width        => $entry_width
        );

        my $set_push_b_frame = $set_push_b_entry_frame->Frame->pack(@fxe1);

        $cw->add_set_entry( $set_push_b_frame, $balloon, $tklist, \$user_value )->pack(@fxe1);
        $cw->add_insort_entry( $set_push_b_frame, $balloon, \$user_value )->pack(@fxe1);
        $cw->add_insert_entry( $set_push_b_frame, $balloon, \$user_value )->pack(@fxe1);
        $cw->add_set_all_b( $set_push_b_entry_frame, $set_push_b_frame, $balloon, \$user_value )
            ->pack(@fxe1);

        $value_entry->pack(@fxe1);
        $cw->add_warning( $list, 'edit' )->pack(@fx);
    }
    else {
        my $elt_name = $list->element_name;
        my $disp     = "$elt_name ( $cargo_type ";
        $disp .= $list->config_class_name . ' )' if $cargo_type eq 'node';
        $disp .= " $value_type )" if defined $value_type;
        my $b = $right_frame->Button(
            -text    => "Push new $disp",
            -command => sub { $cw->push_entry(''); },
        )->pack(@fxe1);
        $balloon->attach( $b, -msg => "add a new $elt_name at the end of the list" );
    }

    $cw->{tklist} = $tklist;
    $cw->reset_value;

    $cw->ConfigSpecs(-font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],);

    $cw->Tk::Frame::Populate($args);
}

#
# New subroutine "reset_value" extracted - Wed Sep 21 11:33:51 2011.
#
sub reset_value {
    my $cw   = shift;
    my $list = $cw->{list};

    my $cargo_type = $list->cargo_type;
    $cw->{tklist}->delete( 0, 'end' );
    my @insert =
          $cargo_type eq 'leaf'
        ? $list->fetch_all_values( check => 'no' )
        : $list->fetch_all_indexes;
    $cw->{tklist}->insert( end => @insert );

    return ( $cargo_type, \@insert );
}

sub add_set_entry {
    my ( $cw, $frame, $balloon, $tklist, $user_value_r ) = @_;

    my $set_sub = sub { $cw->set_entry($$user_value_r); };

    my $set_b = $frame->Button(
        -text    => "set selected",
        -command => $set_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $set_b,
              -msg => 'enter a value, select an element on the left '
            . 'and click the button to replace the selected '
            . 'element with this value.' );

    my $b_sub = sub {
        my $idx = $tklist->curselection;
        $$user_value_r = $tklist->get($idx) if $idx;
    };

    $tklist->bind( '<<ListboxSelect>>', $b_sub );

    return $set_b;
}

sub add_push_entry {
    my ( $cw, $frame, $balloon, $user_value_r ) = @_;

    my $push_sub = sub { $cw->push_entry($$user_value_r); $$user_value_r = ''; };
    my $push_b = $frame->Button(
        -text    => "push item",
        -command => $push_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $push_b,
        -msg => 'enter a value, and click the push button to add '
            . 'this value at the end of the list' );
    return $push_b;
}

sub push_entry {
    my $cw     = shift;
    my $add    = shift;
    my $tklist = $cw->{tklist};
    my $list   = $cw->{list};

    $logger->debug("push_entry: $add");

    # create new item in list (may auto create node object)
    my @idx = $list->fetch_all_indexes;
    eval { $list->fetch_with_id( scalar @idx ) };

    if ($@) {
        $cw->CmeDialog(
            -title => "List index error",
            -text  => $@->as_string,
        )->Show;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->{store_cb}->();

        my @new_idx = $list->fetch_all_indexes;
        $logger->debug( "new list idx: " . join( ',', @new_idx ) );

        my $insert = length($add) ? $add : $#new_idx;
        $tklist->insert( 'end', $insert );
    }

    return 1;
}

sub add_insert_entry {
    my ( $cw, $frame, $balloon, $user_value_r ) = @_;

    my $insert_sub = sub { $cw->insert_entry($$user_value_r); $$user_value_r = ''; };
    my $insert_b = $frame->Button(
        -text    => "insert item",
        -command => $insert_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $insert_b,
        -msg => 'enter a value, and click the insert button to add '
            . 'this value before the selected item or at the end of the list (push)' );
    return $insert_b;
}

sub insert_entry {
    my $cw     = shift;
    my $add    = shift;
    my $tklist = $cw->{tklist};
    my $list   = $cw->{list};

    my $idx_ref = $tklist->curselection || [];
    my $idx = $idx_ref->[0];

    $logger->debug( "insert_entry: $add insert at index ", $idx || 'end' );
    print( "insert_entry: $add insert at index ", $idx || 'end', "\n" );

    return unless length($add);
    my $try_sub =
        defined $idx ? sub { $list->insert_at( $idx, $add ); } : sub { $list->push($add) };
    $cw->try_and_redraw($try_sub);

}

sub set_entry {
    my $cw   = shift;
    my $data = shift;

    my $tklist  = $cw->{tklist};
    my $idx_ref = $tklist->curselection();
    return unless defined $idx_ref;
    return unless @$idx_ref;

    my $idx = $idx_ref->[0];
    return unless $idx;
    $tklist->delete($idx);
    $tklist->insert( $idx, $data );
    $tklist->selectionSet($idx);
    $cw->{list}->fetch_with_id($idx)->store($data);
    $cw->{store_cb}->();
}

sub add_insort_entry {
    my ( $cw, $frame, $balloon, $user_value_r ) = @_;

    my $insort_sub = sub { $cw->insort_entry($$user_value_r); $$user_value_r = ''; };
    my $insort_b = $frame->Button(
        -text    => "insort",
        -command => $insort_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $insort_b,
        -msg => 'enter a value, and click the insort button to insert '
            . 'this value while keeping the list sorted' );
    return $insort_b;
}

sub insort_entry {
    my $cw  = shift;
    my $add = shift;

    $logger->debug("insort_entry: $add");

    return unless length($add);
    $cw->try_and_redraw( sub { $cw->{list}->insort($add); } );
}

sub try_and_redraw {
    my $cw     = shift;
    my $to_try = shift;
    my $tklist = $cw->{tklist};
    my $list   = $cw->{list};

    eval { $to_try->(); };

    if ($@) {
        $cw->CmeDialog(
            -title => "List index error",
            -text  => $@->as_string,
        )->Show;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->{store_cb}->();

        my @list = $list->fetch_all_values;

        $tklist->delete( 0, 'end' );
        $tklist->insert( 0, @list );
    }

    return 1;
}

sub add_set_all_b {
    my ( $cw, $frame, $b_frame, $balloon, $user_value_r ) = @_;

    my $regexp = '\s*,\s*';
    my $set_all_sub = sub { $cw->set_all_items( $$user_value_r, $regexp ); };

    #my $set_all_frame = $frame->Frame;
    #my $set_top       = $set_all_frame->Frame->pack(@fxe1);
    my $set_bottom = $frame->Frame->pack( @fxe1, -side => 'bottom' );

    my $set_b = $b_frame->Button(
        -text    => "set all",
        -command => $set_all_sub,
    )->pack( -side => 'left', @fx );

    $balloon->attach( $set_b,
        -msg => 'set all elements with a single string that '
            . 'will be split by the regexp displayed below' );

    my $split_lb = $set_bottom->Label( -text => 'split regexp' )->pack( -side => 'left', @fxe1 );
    $set_bottom->Entry( -textvariable => \$regexp )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $split_lb,
        -msg => 'regexp used to split the entry above when "set all" button is pressed' );

    return $set_bottom;
}

sub set_all_items {
    my $cw     = shift;
    my $data   = shift;
    my $regexp = shift;

    return unless $data;
    my $tklist = $cw->{tklist};

    my @list = split /$regexp/, $data;

    $tklist->delete( 0, 'end' );
    $tklist->insert( 0, @list );
    $cw->{list}->load_data( \@list );
    $cw->{store_cb}->();
}

sub sort_content {
    my $cw = shift;

    my $tklist = $cw->{tklist};
    my $list   = $cw->{list};
    $list->sort;

    my @list = $list->fetch_all_values;

    $tklist->delete( 0, 'end' );
    $tklist->insert( 0, @list );
    $cw->{store_cb}->();
}

sub move_up {
    my $cw = shift;

    my $tklist       = $cw->{tklist};
    my $from_idx_ref = $tklist->curselection();

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref;

    my $from_idx = $from_idx_ref->[0];
    return unless $from_idx;
    return unless $from_idx > 0;

    $cw->swap( $from_idx, $from_idx - 1 );
}

sub move_down {
    my $cw = shift;

    my $tklist       = $cw->{tklist};
    my $from_idx_ref = $tklist->curselection();

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref;

    my $from_idx = $from_idx_ref->[0];
    my $max_idx  = $cw->{list}->fetch_size - 1;
    return unless $from_idx < $max_idx;

    $cw->swap( $from_idx, $from_idx + 1 );
}

sub swap {
    my ( $cw, $ida, $idb ) = @_;

    my $tklist = $cw->{tklist};

    my $list = $cw->{list};
    $list->swap( $ida, $idb );

    my $cargo_type = $list->cargo_type;

    $tklist->selectionClear($ida);

    if ( $cargo_type ne 'node' ) {
        my $old = $tklist->get($ida);
        $tklist->delete($ida);

        while ( $idb > $tklist->size ) {
            $tklist->insert( 'end', '<undef>' );
        }
        $tklist->insert( $idb, $old );
    }

    $tklist->selectionSet($idb);
    $cw->{store_cb}->();
}

sub remove_selection {
    my $cw     = shift;
    my $tklist = $cw->{tklist};
    my $list   = $cw->{list};

    foreach ( $tklist->curselection() ) {
        $logger->debug("remove_selection: removing index $_");
        $list->remove($_);
    }
    $cw->{store_cb}->();

    # redraw the list content
    $cw->reset_value;

    $cw->update_warning($list);
}

1;
