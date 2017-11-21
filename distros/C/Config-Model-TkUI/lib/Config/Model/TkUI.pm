#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# copyright at the end of the file in the pod section

package Config::Model::TkUI;
$Config::Model::TkUI::VERSION = '1.365';
use 5.10.1;
use strict;
use warnings;
use Carp;

use base qw/Tk::Toplevel/;
use vars qw/$icon_path $error_img $warn_img/;
use subs qw/menu_struct/;
use Scalar::Util qw/weaken/;
use Log::Log4perl 1.11;
use Path::Tiny;
use YAML qw/LoadFile DumpFile/;
use File::HomeDir;

use Pod::POM;
use Pod::POM::View::Text;

use Tk::DoubleClick;

use Tk::Photo;
use Tk::PNG;    # required for Tk::Photo to be able to load pngs
use Tk::DialogBox;
use Tk::Adjuster;
use Tk::FontDialog;

use Tk::Pod;
use Tk::Pod::Text;    # for findpod

use Config::Model 2.114; # Node::gist

use Config::Model::Tk::LeafEditor;
use Config::Model::Tk::CheckListEditor;

use Config::Model::Tk::LeafViewer;
use Config::Model::Tk::CheckListViewer;

use Config::Model::Tk::ListViewer;
use Config::Model::Tk::ListEditor;

use Config::Model::Tk::HashViewer;
use Config::Model::Tk::HashEditor;

use Config::Model::Tk::NodeViewer;
use Config::Model::Tk::NodeEditor;

use Config::Model::Tk::Wizard;

Construct Tk::Widget 'ConfigModelUI';

my $cust_img;
my $tool_img;
my %gnome_img;

my $mod_file = 'Config/Model/TkUI.pm';
$icon_path = $INC{$mod_file};
$icon_path =~ s/TkUI.pm//;
$icon_path .= 'Tk/icons/';

my $logger = Log::Log4perl::get_logger('TkUI');

no warnings "redefine";

sub Tk::Error {
    my ( $cw, $error, @locations ) = @_;
    my $msg = ( ref($error) && $error->can('as_string') ) ? $error->as_string : $error;
    warn $msg;
    $msg .= "Tk stack: \n@locations\n";
    $cw->Dialog(
        -title => 'Config::Model error',
        -text  => $msg,
    )->Show;
}

use warnings "redefine";

my $default_config = {
    font => { -family =>  'DejaVu Sans', qw/-size -13 -weight normal/ }
};

my $main_window;
my $config_path = path(File::HomeDir->my_home)->child('.cme/config/');
my $config_file = $config_path->child('tkui.yml');

$config_path -> mkpath;

my $config = $config_file->is_file ? LoadFile($config_file) : $default_config ;

# Tk::CmdLine::SetArguments( -font => $config->{font} ) ;

sub ClassInit {
    my ( $class, $mw ) = @_;
    $main_window = $mw;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub set_font {
    my $cw = shift;

    my $tk_font = $main_window->FontDialog->Show;
    if (defined $tk_font) {
        $main_window->RefontTree(-font => $tk_font);
        $config->{font} = {$tk_font->actual} ;
        $cw->ConfigSpecs( -font => ['DESCENDANTS', 'font','Font', $tk_font ]);
        DumpFile($config_file->stringify, $config);
    }
}

sub Populate {
    my ( $cw, $args ) = @_;

    unless ( defined $error_img ) {
        $error_img = $cw->Photo( -file => $icon_path . 'stop.png' );
        $cust_img  = $cw->Photo( -file => $icon_path . 'next.png' );

        # snatched from oxygen-icon-theme
        $warn_img = $cw->Photo( -file => $icon_path . 'dialog-warning.png' );

        # snatched from openclipart-png
        $tool_img            = $cw->Photo( -file => $icon_path . 'tools_nicu_buculei_01.png' );
        $gnome_img{next}     = $cw->Photo( -file => $icon_path . 'gnome-next.png' );
        $gnome_img{previous} = $cw->Photo( -file => $icon_path . 'gnome-previous.png' );
    }

    foreach my $parm (qw/-root/) {
        my $attr = $parm;
        $attr =~ s/^-//;
        $cw->{$attr} = delete $args->{$parm}
            or croak "Missing $parm arg\n";
    }

    foreach my $parm (qw/-store_sub -quit/) {
        my $attr = $parm;
        $attr =~ s/^-//;
        $cw->{$attr} = delete $args->{$parm};
    }

    my $extra_menu = delete $args->{'-extra-menu'} || [];

    my $title = delete $args->{'-title'}
        || $0 . " " . $cw->{root}->config_class_name;

    # check unknown parameters
    croak "Unknown parameter ", join( ' ', keys %$args ) if %$args;

    # initialize internal attributes
    $cw->{location} = '';
    $cw->{current_mode} = 'view';

    $cw->setup_scanner();

    # create top menu
    require Tk::Menubutton;
    my $menubar = $cw->Menu;
    $cw->configure( -menu => $menubar );
    $cw->{my_menu} = $menubar;

    my $file_items = [
        [ qw/command wizard -command/, sub { $cw->wizard } ],
        [ qw/command reload -command/, sub { $cw->reload } ],
        [ command => 'check for errors',     -command => sub { $cw->check(1) } ],
        [ command => 'check for warnings',   -command => sub { $cw->check( 1, 1 ) } ],
        [ command => 'show unsaved changes', -command => sub { $cw->show_changes; } ],
        [ command => 'save (Ctrl-s)', -command => sub { $cw->save } ],
        [
            command  => 'save in dir ...',
            -command => sub { $cw->save_in_dir; }
        ],
        @$extra_menu,
        [
            command  => 'debug ...',
            -command => sub {
                require Tk::ObjScanner;
                Tk::ObjScanner::scan_object( $cw->{root} );
                }
        ],
        [ command => 'quit (Ctrl-q)', -command => sub { $cw->quit } ],
    ];
    $menubar->cascade( -label => 'File', -menuitems => $file_items );

    $cw->add_help_menu($menubar);

    $cw->bind( '<Control-s>', sub { $cw->save } );
    $cw->bind( '<Control-q>', sub { $cw->quit } );
    $cw->bind( '<Control-c>', sub { $cw->edit_copy } );
    $cw->bind( '<Control-v>', sub { $cw->edit_paste } );
    $cw->bind( '<Control-f>', sub { $cw->pack_find_widget } );

    my $edit_items = [

        # [ qw/command cut   -command/, sub{ $cw->edit_cut }],
        [ command => 'copy (Ctrl-c)',  '-command', sub { $cw->edit_copy } ],
        [ command => 'paste (Ctrl-v)', '-command', sub { $cw->edit_paste } ],
        [ command => 'find (Ctrl-f)',  '-command', sub { $cw->pack_find_widget; } ],
    ];
    $menubar->cascade( -label => 'Edit', -menuitems => $edit_items );

    my $option_items = [
        [ command => 'Font',  '-command', sub { $cw->set_font(); } ],
    ];
    $menubar->cascade( -label => 'Options', -menuitems => $option_items );

    # create frame for location entry
    my $loc_frame =
        $cw->Frame( -relief => 'sunken', -borderwidth => 1 )->pack( -pady => 0, -fill => 'x' );
    $loc_frame->Label( -text => 'location :' )->pack( -side => 'left' );
    $loc_frame->Label( -textvariable => \$cw->{location} )->pack( -side => 'left' );

    # create 'show only custom values'
    $cw->{show_only_custom} = 0;
    $loc_frame->Checkbutton(
        -variable => \$cw->{show_only_custom},
        -command  => sub { $cw->reload },
    )->pack( -side => 'right' );
    $loc_frame->Label( -text => 'show only custom values' )->pack( -side => 'right' );

    # create 'hide empty values'
    $cw->{hide_empty_values} = 0;
    $loc_frame->Checkbutton(
        -variable => \$cw->{hide_empty_values},
        -command  => sub { $cw->reload },
    )->pack( -side => 'right' );
    $loc_frame->Label( -text => 'hide empty values' )->pack( -side => 'right' );

    # add bottom frame
    my $bottom_frame = $cw->Frame->pack(qw/-pady 0 -fill both -expand 1/);

    # create the widget for tree navigation
    require Tk::Tree;
    my $tree = $bottom_frame->Scrolled(
        qw/Tree/,
        -columns   => 4,
        -header    => 1,
        -opencmd   => sub { $cw->open_item(@_); },
        -closecmd  => sub { $cw->close_item(@_); },
    )->pack(qw/-fill both -expand 1 -side left/);
    $cw->{tktree} = $tree;

    # add adjuster
    $bottom_frame->Adjuster()->packAfter( $tree, -side => 'left' );

    # add headers
    $tree->headerCreate( 0, -text => "element" );
    $tree->headerCreate( 1, -text => "status" );
    $tree->headerCreate( 2, -text => "value" );
    $tree->headerCreate( 3, -text => "standard value" );

    $cw->reload;

    # add frame on the right for entry and help
    my $eh_frame = $bottom_frame->Frame->pack(qw/-fill both -expand 1 -side right/);

    # add entry frame, filled by call-back
    # should be a composite widget
    my $e_frame = $eh_frame->Frame->pack(qw/-side top -fill both -expand 1/);
    $e_frame->Label(    #-text => "placeholder",
        -image => $tool_img,
        -width => 400,         # width in pixel for image
    )->pack( -side => 'top' );
    $e_frame->Button(
        -text    => "Run Wizard !",
        -command => sub { $cw->wizard } )->pack( -side => 'bottom' );

    my $b1_sub = sub {
        my $item = $tree->nearest( $tree->pointery - $tree->rooty );
        $cw->on_browse($item);
    };
    my $b3_sub = sub {
        my $item = $tree->nearest( $tree->pointery - $tree->rooty );
        $cw->on_select($item);
    };

    $tree->bind( '<Return>', $b3_sub );
    $tree->bind( '<ButtonRelease-3>', $b3_sub );
    bind_clicks($tree,$b1_sub, $b3_sub);

    # bind button2 to get cut buffer content and try to store cut buffer content
    my $b2_sub = sub {
        my $item = $tree->nearest( $tree->pointery - $tree->rooty );
        $cw->on_cut_buffer_dump($item);
    };
    $tree->bind( '<ButtonRelease-2>', $b2_sub );

    $tree->bind( '<Control-c>', sub { $cw->edit_copy } );
    $tree->bind( '<Control-v>', sub { $cw->edit_paste } );
    $tree->bind( '<Control-f>', sub { $cw->pack_find_widget } );

    my $find_frame = $cw->create_find_widget;

    # create frame for message
    my $msg_label = $cw->Label(
        -textvariable => \$cw->{message},
        -relief => 'sunken',
        -borderwidth => 1,
        -anchor =>'w',
    );
    $msg_label->pack( -pady => 0, -fill => 'x' );

    $args->{-title} = $title;
    $cw->SUPER::Populate($args);

    my $tk_font = $cw->Font(%{$config->{font}});
    $cw->ConfigSpecs(
        -font       => ['DESCENDANTS', 'font','Font', $tk_font ],
        #-background => ['DESCENDANTS', 'background', 'Background', $background],
        #-selectbackground => [$hlist, 'selectBackground', 'SelectBackground',
        #                      $selectbackground],
        -tree_width  => [ 'METHOD',  undef,        undef,        80 ],
        -tree_height => [ 'METHOD',  undef,        undef,        30 ],
        -width       => [ $eh_frame, qw/width Width 1280/ ],
        -height      => [ $eh_frame, qw/height Height 1024/ ],
        -selectmode  => [ $tree,     'selectMode', 'SelectMode', 'single' ],    #single',
                #-oldcursor => [$hlist, undef, undef, undef],
        DEFAULT => [$tree] );

    $cw->Advertise( tree        => $tree );
    $cw->Advertise( menubar     => $menubar );
    $cw->Advertise( right_frame => $eh_frame );
    $cw->Advertise( ed_frame    => $e_frame );
    $cw->Advertise( find_frame  => $find_frame );
    $cw->Advertise( msg_label   => $msg_label );

    $cw->OnDestroy(sub {$cw->Parent->destroy if ref($cw->Parent) eq 'MainWindow'} );

    $cw->Delegates;
}

sub show_message {
    my ( $cw, $msg ) = @_;
    # $cw->Subwidget('msg_label')->configure(-background => "red"); # does not work
    $cw->{message} = $msg;

    if (my $id = $cw->{id}) {
        $cw->afterCancel($id) ;
    } ;

    my $unshow = sub {
        delete $cw->{id};
        $cw->{message} = '';
    } ;
    $cw->{id} = $cw->after(5000,$unshow) ;
}

sub tree_width {
    my ( $cw, $value ) = @_;
    $cw->Subwidget('tree')->configure( -width => $value );
}

sub tree_height {
    my ( $cw, $value ) = @_;
    $cw->Subwidget('tree')->configure( -height => $value );
}

my $parser = Pod::POM->new();

# parse from my documentation
my $pom = $parser->parse_file(__FILE__)
    || die $parser->error();

my $help_text;
my $todo_text;
my $info_text;
foreach my $head1 ( $pom->head1() ) {
    $help_text = Pod::POM::View::Text->view_head1($head1)
        if $head1->title eq 'USAGE';
    $info_text = Pod::POM::View::Text->view_head1($head1)
        if $head1->title =~ /more information/i;

}

sub add_help_menu {
    my ( $cw, $menubar ) = @_;

    my $about_sub = sub {
        $cw->Dialog(
            -title => 'About',
            -text  => "Config::Model::TkUI \n"
                . "(c) 2008-2012 Dominique Dumont \n"
                . "Licensed under LGPLv2\n"
        )->Show;
    };

    my $info_sub = sub {
        my $db = $cw->DialogBox( -title => 'TODO' );
        my $text = $db->add( 'Scrolled', 'ROText' )->pack;
        $text->insert( 'end', $info_text );
        $db->Show;
    };

    my $help_sub = sub {
        my $db = $cw->DialogBox( -title => 'help' );
        my $text = $db->add( 'Scrolled', 'ROText' )->pack;
        $text->insert( 'end', $help_text );
        $db->Show;
    };

    my $class   = $cw->{root}->config_class_name;
    my $man_sub = sub {
        $cw->Pod(
            -tree       => 0,
            -file       => "Config::Model::models::" . $class,
            -title      => $class,
            -exitbutton => 0,
        );
    };

    my $help_items = [
        [ qw/command About -command/, $about_sub ],
        [ qw/command Usage -command/, $help_sub ],
        [ command => 'More info',   -command => $info_sub ],
        [ command => "$class help", -command => $man_sub ],
    ];
    $menubar->cascade( -label => 'Help', -menuitems => $help_items );
}

# Note: this callback is called by Tk::Tree *before* changing the
# indicator. And the indicator is used by Tk::Tree to store the
# open/close/none mode. So we can't rely on getmode for path that are
# opening. Hence the parameter passed to the sub stored with each
# Tk::Tree item
sub open_item {
    my ( $cw, $path ) = @_;
    my $tktree = $cw->{tktree};
    $logger->trace("open_item on $path");
    my $data = $tktree->infoData($path);

    # invoke the scanner part (to create children)
    # the parameter indicates that we are opening this path
    $data->[0]->(1);

    $cw->show_single_list_value ($tktree, $data->[1], $path, 0);

    my @children = $tktree->infoChildren($path);
    $logger->trace("open_item show @children");
    map { $tktree->show( -entry => $_ ); } @children;
}

sub close_item {
    my ( $cw, $path ) = @_;
    my $tktree = $cw->{tktree};
    $logger->trace("close_item on $path");
    my $data = $tktree->infoData($path);

    $cw->show_single_list_value ($tktree, $data->[1], $path, 1);

    my @children = $tktree->infoChildren($path);
    $logger->trace("close_item hide @children");
    map { $tktree->hide( -entry => $_ ); } @children;
}

sub save_in_dir {
    my $cw = shift;
    require Tk::DirSelect;
    $cw->{save_dir} = $cw->DirSelect()->Show;

    # chooseDirectory does not work correctly.
    #$cw->{save_dir} = $cw->chooseDirectory(-mustexist => 'no') ;
    $cw->save();
}

sub check {
    my $cw             = shift;
    my $show           = shift || 0;
    my $check_warnings = shift || 0;

    my $wiz = $cw->setup_wizard( sub { $cw->check_end( $show, @_ ); } );

    $wiz->start_wizard( stop_on_warning => $check_warnings );
}

sub check_end {
    my $cw          = shift;
    my $show        = shift;
    my $has_stopped = shift;

    $cw->reload if $has_stopped;

    if ( $show and not $has_stopped ) {
        $cw->Dialog(
            -title => 'Check',
            -text  => "No issue found"
        )->Show;
    }
}

sub save {
    my $cw = shift;
    my $cb = shift || sub {};

    my $dir       = $cw->{save_dir};
    my $trace_dir = defined $dir ? $dir : 'default';
    my @wb_args   = defined $dir ? ( config_dir => $dir ) : ();

    my $save_job = sub {
        $cw->check(); # may be long

        if ( defined $cw->{store_sub} ) {
            $logger->info("Saving data in $trace_dir directory with store call-back");
            eval { $cw->{store_sub}->($dir) };
        }
        else {
            $logger->info("Saving data in $trace_dir directory with instance write_back");
            eval { $cw->{root}->instance->write_back(@wb_args); };
        }

        if ($@) {
            $cw->Dialog(
                -title => 'Save error',
                -text  => ref($@) ? $@->as_string : $@,
            )->Show;
            $cb->($@); # indicate failure
        }
        else {
            $cw->show_message("Save done ...");
            $cb->();
        }
    };

    $cw->show_message("Saving... please wait ...");

    # use a short delay to let tk show the message above and then save
    $cw->after(100, $save_job) ;

}

sub quit {
    my $cw = shift;
    my $text = shift || "Save data ?";

    if ( $cw->{root}->instance->needs_save ) {
        my $answer = $cw->Dialog(
            -title          => "quit",
            -text           => $text,
            -buttons        => [ qw/yes no cancel/, 'show changes' ],
            -default_button => 'yes',
        )->Show;

        if ( $answer eq 'yes' ) {
            $cw->save( sub {$cw->self_destroy;});
        }
        elsif ( $answer eq 'no' ) {
            $cw->self_destroy;
        }
        elsif ( $answer =~ /show/ ) {
            $cw->show_changes( sub { $cw->quit } );
        }
    }
    else {
        $cw->self_destroy;
    }

}


sub self_destroy {
    my $cw = shift;

    if ( defined $cw->{quit} and $cw->{quit} eq 'soft' ) {
        $cw->destroy;
    }
    else {
        # destroy main window to exit Tk Mainloop;
        $cw->parent->destroy;
    }
}

sub show_changes {
    my $cw = shift;
    my $cb = shift;

    my $changes       = $cw->{root}->instance->list_changes;
    my $change_widget = $cw->Toplevel;
    $change_widget->Scrolled('ROText')->pack( -expand => 1, -fill => 'both' )
        ->insert( '1.0', $changes );
    $change_widget->Button(
        -command => sub { $change_widget->destroy; $cb->() if defined $cb; },
        -text => 'ok',
    )->pack;
}

sub reload {
    my $cw = shift;
    carp "reload: too many parameters" if @_ > 1;
    my $force_display_path = shift;    # force open editor on this path

    $logger->trace( "reloading tk tree"
            . ( defined $force_display_path ? " (force display $force_display_path)" : '' ) );

    my $tree = $cw->{tktree};

    my $instance_name = $cw->{root}->instance->name;

    my $new_drawing = not $tree->infoExists($instance_name);

    my $sub =
        sub { $cw->{scanner}->scan_node( [ $instance_name, $cw, @_ ], $cw->{root} ); };

    if ($new_drawing) {
        $tree->add( $instance_name, -data => [ $sub, $cw->{root} ] );
        $tree->itemCreate( $instance_name, 0, -text => $instance_name, );
        $tree->setmode( $instance_name, 'close' );
        $tree->open($instance_name);
    }

    # the first parameter indicates that we are opening the root
    $sub->( 1, $force_display_path );
    $tree->see($force_display_path)
        if ( $force_display_path and $tree->info( exists => $force_display_path ) );
    $cw->{editor}->reload if defined $cw->{editor};
}

# call-back when Tree element is selected
sub on_browse {
    my ( $cw, $path ) = @_;
    $cw->update_loc_bar($path);
    $cw->create_element_widget('view');
}

sub update_loc_bar {
    my ( $cw, $path ) = @_;

    #$cw->{path}=$path ;
    my $datar = $cw->{tktree}->infoData($path);
    my $obj   = $datar->[1];
    $cw->{location} = $obj->location_short;
}

sub on_select {
    my ( $cw, $path ) = @_;
    $cw->update_loc_bar($path);
    $cw->create_element_widget('edit');
}

sub on_cut_buffer_dump {
    my ( $cw, $tree_path ) = @_;
    $cw->update_loc_bar($tree_path);

    # get cut buffer content, See Perl/Tk book p297
    my $sel = eval { $cw->SelectionGet; };

    return if $@;    # no selection

    my $obj = $cw->{tktree}->infoData($tree_path)->[1];

    if ( $obj->isa('Config::Model::Value') ) {

        # if leaf store content
        $obj->store( value => $sel, callback => sub { $cw->reload; } );
    }
    elsif ( $obj->isa('Config::Model::HashId') ) {

        # if hash create keys
        my @keys = ( $sel =~ /\n/m ) ? split( /\n/, $sel ) : ($sel);
        map { $obj->fetch_with_id($_) } @keys;
    }
    elsif ( $obj->isa('Config::Model::ListId') and $obj->get_cargo_type !~ /node/ ) {

        # if array, push values
        my @v =
              ( $sel =~ /\n/m ) ? split( /\n/, $sel )
            : ( $sel =~ /,/ )   ? split( /,/,  $sel )
            :                     ($sel);
        $obj->push(@v);
    }

    # else ignore

    # display result
    $cw->reload;
    $cw->create_element_widget($cw->{current_mode}, $tree_path);
    $cw->open_item($tree_path);
}

# replace dot in str by _|_
sub to_path   { my $str  = shift; $str =~ s/\./_|_/g; return $str; }

sub force_element_display {
    my $cw      = shift;
    my $elt_obj = shift;

    $logger->trace( "force display of " . $elt_obj->location );
    $cw->reload( $elt_obj->location );
}

sub prune {
    my $cw   = shift;
    my $path = shift;
    $logger->trace("prune $path");
    my %list = map { "$path." . to_path($_) => 1 } @_;

    # remove entries that are not part of the list
    my $tkt = $cw->{tktree};

    map { $tkt->deleteEntry($_) if $_ and not defined $list{$_}; } $tkt->infoChildren($path);
    $logger->trace("prune $path done");
}

# Beware: TkTree items store tree object and not tree cds path. These
# object might become irrelevant when warp master values are
# modified. So the whole Tk Tree layout must be redone very time a
# config value is modified. This is a bit heavy, but a smarter
# alternative would need hooks in the configuration tree to
# synchronise the Tk Tree with the configuration tree :-p

my %elt_mode = (
    leaf        => 'none',
    hash        => 'open',
    list        => 'open',
    node        => 'open',
    check_list  => 'none',
    warped_node => 'open',
);

sub disp_obj_elt {
    my ( $scanner, $data_ref, $node,    @element_list ) = @_;
    my ( $path,    $cw,       $opening, $fd_path )      = @$data_ref;
    my $tkt  = $cw->{tktree};
    my $mode = $tkt->getmode($path);

    if ($cw->{show_only_custom} or $cw->{hide_empty_values}) {
        my @new_element_list;
        foreach my $elt ( @element_list ) {
            my $obj = $node->fetch_element($elt);
            if ($cw->{show_only_custom}) {
                push @new_element_list, $elt if $node->fetch_element($elt)->has_data;
            }
            elsif ($cw->{hide_empty_values}) {
                my $elt_type = $obj->get_type;
                my $show
                    = $elt_type eq 'hash'       ? $obj->has_data
                    : $elt_type eq 'list'       ? $obj->has_data
                    : $elt_type eq 'leaf'       ? length($obj->fetch(qw/mode user check no/) // '')
                    : $elt_type eq 'check_list' ? $obj->fetch(mode => 'user')
                    :                             1 ;
                push @new_element_list, $elt if $show;
            }
        }
        @element_list = @new_element_list;
    }
    $logger->trace( "disp_obj_elt path $path mode $mode opening $opening " . "(@element_list)" );

    $cw->prune( $path, @element_list );

    my $node_loc = $node->location;

    my $prevpath = '';
    foreach my $elt (@element_list) {
        my $newpath  = "$path." . to_path($elt);
        my $scan_sub = sub {
            $scanner->scan_element( [ $newpath, $cw, @_ ], $node, $elt );
        };
        my @data = ( $scan_sub, $node->fetch_element($elt) );

        # It's necessary to store a weakened reference of a tree
        # object as these ones tend to disappear when warped out. In
        # this case, the object must be destroyed. This does not
        # happen if a non-weakened reference is kept in Tk Tree.
        weaken( $data[1] );

        my $elt_type = $node->element_type($elt);
        my $eltmode  = $elt_mode{$elt_type};
        if ( $tkt->infoExists($newpath) ) {
            $eltmode = $tkt->getmode($newpath);    # will reuse mode below
        }
        else {
            my @opt = $prevpath ? ( -after => $prevpath ) : ( -at => 0 );
            $logger->trace("disp_obj_elt add $newpath mode $eltmode type $elt_type");
            $tkt->add( $newpath, -data => \@data, @opt );
            $tkt->itemCreate( $newpath, 0, -text => $elt );
            $tkt->setmode( $newpath => $eltmode );
        }

        my $elt_loc = $node_loc ? $node_loc . ' ' . $elt : $elt;

        $cw->setmode( 'node', $newpath, $eltmode, $elt_loc, $fd_path, $opening, $scan_sub );

        my $obj = $node->fetch_element($elt);
        if ( $elt_type eq 'hash' ) {
            $cw->update_hash_image( $obj, $newpath );
        }

        if ($elt_type eq 'hash' or $elt_type eq 'list') {
            my $size = $obj->fetch_size;
            $tkt->entryconfigure($newpath, -text => "$elt [$size]");
        }

        $cw->show_single_list_value ($tkt, $obj, $newpath,  $tkt->getmode($newpath) eq 'open' ? 1 : 0);

        $prevpath = $newpath;
    }
}

# show a list like a leaf value when the list contains *one* item
sub show_single_list_value {
    my ($cw, $tkt, $obj, $path, $show) = @_;
    my $elt_type = $obj->get_type;

    # leave alone element that is not a list of leaf
    return unless $elt_type eq 'list' and $obj->get_cargo_type eq 'leaf';

    $logger->trace("show_single_list_value called on ", $obj->location);
    if ($obj->fetch_size == 1 and $show) {
        disp_leaf(undef,[ $path, $cw ], $obj->parent, $obj->element_name, 0, $obj->fetch_with_id(0));
    }
    else {
        map {$tkt->itemDelete( $path, $_ ) if $tkt->itemExists($path, $_);} qw/1 2 3/;
    }
}

sub disp_hash {
    my ( $scanner, $data_ref, $node, $element_name, @idx ) = @_;
    my ( $path, $cw, $opening, $fd_path ) = @$data_ref;
    my $tkt  = $cw->{tktree};
    my $mode = $tkt->getmode($path);
    $logger->trace("disp_hash    path is $path  mode $mode (@idx)");

    $cw->prune( $path, @idx );

    my $elt      = $node->fetch_element($element_name);
    my $elt_type = $elt->get_cargo_type();

    my $node_loc = $node->location;

    # need to keep track myself of previous sibling as
    # $tkt->entrycget($path,'-after') dies
    # and $tkt->info('prev',$path) return the path above in the displayed tree, which
    # is not necessarily a sibling :-(
    my $prev_sibling = '';
    my %tk_previous_path;
    foreach ( $tkt->info( 'children', $path ) ) {
        $tk_previous_path{$_} = $prev_sibling;
        $prev_sibling = $_;
    }

    my $prevpath = '';
    foreach my $idx (@idx) {
        my $newpath  = $path . '.' . to_path($idx);
        my $scan_sub = sub {
            $scanner->scan_hash( [ $newpath, $cw, @_ ], $node, $element_name, $idx );
        };

        my $eltmode = $elt_mode{$elt_type};
        my $sub_elt = $elt->fetch_with_id($idx);

        # check for display order mismatch
        if ( $tkt->infoExists($newpath) ) {
            if ( $prevpath ne $tk_previous_path{$newpath} ) {
                $logger->trace(
                    "disp_hash deleting mismatching $newpath mode $eltmode cargo_type $elt_type");
                $tkt->delete( entry => $newpath );
            }
        }

        # check for content mismatch
        if ( $tkt->infoExists($newpath) ) {
            my $previous_data = $tkt->info( data => $newpath );

            # $previous_data is an object (or an empty string to avoid warnings)
            my $previous_elt = $previous_data->[1] || '';
            $eltmode = $tkt->getmode($newpath);    # will reuse mode below
            $logger->trace( "disp_hash reuse $newpath mode $eltmode cargo_type $elt_type"
                    . " obj $previous_elt (expect $sub_elt)" );

            # string comparison of objects is intentional to check that the tree
            # refers to the correct Config::Model object
            if ( $sub_elt ne $previous_elt ) {
                $logger->trace( "disp_hash delete $newpath mode $eltmode (got "
                        . "$previous_elt expected $sub_elt)" );

                # wrong order, delete the entry
                $tkt->delete( entry => $newpath );
            }
        }

        if ( not $tkt->infoExists($newpath) ) {
            my @opt = $prevpath ? ( -after => $prevpath ) : ( -at => 0 );
            $logger->trace(
                "disp_hash add $newpath mode $eltmode cargo_type $elt_type" . " elt $sub_elt" );
            my @data = ( $scan_sub, $sub_elt );
            weaken( $data[1] );
            $tkt->add( $newpath, -data => \@data, @opt );
            $tkt->itemCreate( $newpath, 0, -text => $node->shorten_idx($idx) );
            $tkt->setmode( $newpath => $eltmode );
        }

        # update the node gist
        my $gist = $elt_type =~ /node/ ? $elt->fetch_with_id($idx)->fetch_gist : '';
        $tkt->itemCreate( $newpath, 2, -text => $gist );

        my $elt_loc = $node_loc;
        $elt_loc .= ' ' if $elt_loc;

        # need to keep regexp identical to the one from C::M::Anything:composite_name
        # so that force_display_path (aka fd_path may work)
        $elt_loc .= $element_name . ':' . ( $idx =~ /\W/ ? '"' . $idx . '"' : $idx );

        # hide new entry if hash is not yet opened
        $cw->setmode( 'hash', $newpath, $eltmode, $elt_loc, $fd_path, $opening, $scan_sub );

        $prevpath = $newpath;
    }
}

sub update_hash_image {
    my ( $cw, $elt, $path ) = @_;
    my $tkt = $cw->{tktree};

    # check hash status and set warning image if necessary
    my $img;
    {
        no warnings qw/uninitialized/;
        $img = $warn_img if $elt->warning_msg;
    }

    if ( defined $img ) {
        $tkt->itemCreate( $path, 1, -itemtype => 'image', -image => $img );
    }
    else {
        $tkt->itemDelete( $path, 1 ) if $tkt->itemExists( $path, 1 );
    }
}

sub setmode {
    my ( $cw, $type, $newpath, $eltmode, $elt_loc, $fd_path, $opening, $scan_sub ) = @_;
    my $tkt = $cw->{tktree};

    my $force_open = ( $fd_path and index( $fd_path, $elt_loc ) == 0 ) ? 1 : 0;
    my $force_match = ( $fd_path and $fd_path eq $elt_loc ) ? 1 : 0;

    $logger->trace( "$type: elt_loc '$elt_loc', opening $opening "
            . "eltmode $eltmode force_open $force_open "
            . ( $fd_path ? "on '$fd_path' " : '' )
            . "force_match $force_match" );

    if ( $eltmode ne 'open' or $force_open or $opening ) {
        $tkt->show( -entry => $newpath );

        # counter-intuitive: want to display [-] if force opening and not leaf item
        $tkt->setmode( $newpath => 'close' ) if ( $force_open and $eltmode ne 'none' );
    }
    else {
        $tkt->close($newpath);
    }

    # counterintuitive but right: scan will be done when the entry
    # is opened. mode can be open, close, none
    $scan_sub->( $force_open, $fd_path ) if ( ( $eltmode ne 'open' ) or $force_open );

    if ($force_match) {
        $tkt->see($newpath);
        $tkt->selectionSet($newpath);
        $cw->update_loc_bar($newpath);
        $cw->create_element_widget( 'edit', $newpath );
    }
}

sub trim_value {
    my $cw    = shift;
    my $value = shift;

    return undef unless defined $value;

    $value =~ s/\n/ /g;
    $value = substr( $value, 0, 15 ) . '...' if length($value) > 15;
    return $value;
}

sub disp_check_list {
    my ( $scanner, $data_ref, $node, $element_name, $index, $leaf_object ) = @_;
    my ( $path, $cw, $opening, $fd_path ) = @$data_ref;
    $logger->trace("disp_check_list    path is $path");

    my $value = $leaf_object->fetch;

    my $tkt = $cw->{tktree};
    $tkt->itemCreate( $path, 2, -text => $cw->trim_value($value) );

    my $std_v = $leaf_object->fetch('standard');
    $tkt->itemCreate( $path, 3, -text => $cw->trim_value($std_v) );

    if ( $std_v ne $value ) {
        $tkt->itemCreate( $path, 1, -itemtype => 'image', -image => $cust_img );
    }
    else {
        # remove image when value is identical to standard value
        $tkt->itemDelete( $path, 1 ) if $tkt->itemExists( $path, 1 );
    }
}

sub disp_leaf {
    my ( $scanner, $data_ref, $node, $element_name, $index, $leaf_object ) = @_;
    my ( $path, $cw, $opening, $fd_path ) = @$data_ref;
    $logger->trace("disp_leaf    path is $path");

    my $std_v = $leaf_object->fetch(qw/mode standard check no silent 1/);
    my $value = $leaf_object->fetch( check => 'no', silent => 1 );
    my $tkt   = $cw->{tktree};

    my ( $is_customised, $img, $has_error, $has_warning );
    {
        no warnings qw/uninitialized/;
        $is_customised = !!( defined $value and ( $std_v ne $value ) );
        $img         = $cust_img if $is_customised;
        $has_warning = !!$leaf_object->warning_msg;
        $img         = $warn_img if $has_warning;
        $has_error   = !!$leaf_object->error_msg;
        $img         = $error_img if $has_error;
    }

    if ( defined $img ) {
        $tkt->itemCreate(
            $path, 1,
            -itemtype => 'image',
            -image    => $img
        );
    }
    else {
        # remove image when value is identical to standard value
        $tkt->itemDelete( $path, 1 ) if $tkt->itemExists( $path, 1 );
    }

    $tkt->itemCreate( $path, 2, -text => $cw->trim_value($value) );

    $tkt->itemCreate( $path, 3, -text => $cw->trim_value($std_v) );
}

sub disp_node {
    my ( $scanner, $data_ref, $node, $element_name, $key, $contained_node ) = @_;
    my ( $path, $cw, $opening, $fd_path ) = @$data_ref;
    $logger->trace("disp_node    path is $path");
    my $curmode = $cw->{tktree}->getmode($path);
    $cw->{tktree}->setmode( $path, 'open' ) if $curmode eq 'none';

    # explore next node
    $scanner->scan_node( $data_ref, $contained_node );
}

sub setup_scanner {
    my ($cw) = @_;
    require Config::Model::ObjTreeScanner;

    my $scanner = Config::Model::ObjTreeScanner->new(

        fallback => 'node',
        check    => 'no',

        # node callback
        node_content_cb => \&disp_obj_elt,

        # element callback
        list_element_cb       => \&disp_hash,
        check_list_element_cb => \&disp_check_list,
        hash_element_cb       => \&disp_hash,
        node_element_cb       => \&disp_node,

        # leaf callback
        leaf_cb            => \&disp_leaf,
        enum_value_cb      => \&disp_leaf,
        integer_value_cb   => \&disp_leaf,
        number_value_cb    => \&disp_leaf,
        boolean_value_cb   => \&disp_leaf,
        string_value_cb    => \&disp_leaf,
        uniline_value_cb   => \&disp_leaf,
        reference_value_cb => \&disp_leaf,

        # call-back when going up the tree
        up_cb => sub { },
    );

    $cw->{scanner} = $scanner;

}

my %widget_table = (
    edit => {
        leaf       => 'ConfigModelLeafEditor',
        check_list => 'ConfigModelCheckListEditor',
        list       => 'ConfigModelListEditor',
        hash       => 'ConfigModelHashEditor',
        node       => 'ConfigModelNodeEditor',
    },
    view => {
        leaf       => 'ConfigModelLeafViewer',
        check_list => 'ConfigModelCheckListViewer',
        list       => 'ConfigModelListViewer',
        hash       => 'ConfigModelHashViewer',
        node       => 'ConfigModelNodeViewer',
    },
);

sub create_element_widget {
    my $cw        = shift;
    my $mode      = shift;
    my $tree_path = shift;    # optional
    my $obj       = shift;    # optional if tree is not opened to path

    my $tree = $cw->{tktree};

    unless ( defined $tree_path ) {

        # pointery and rooty are common widget method and must called on
        # the right widget to give accurate results
        $tree_path = $tree->nearest( $tree->pointery - $tree->rooty );
    }

    if ( $tree->info( exists => $tree_path ) ) {
        $tree->selectionClear();    # clear all
        $tree->selectionSet($tree_path);
        my $data_ref = $tree->infoData($tree_path);
        unless ( defined $data_ref->[1] ) {
            $cw->reload;
            return;
        }
        $obj = $data_ref->[1];
        weaken($obj);

        #my $loc = $data_ref->[1]->location;

        #$obj = $cw->{root}->grab($loc);
    }

    my $loc  = $obj->location;
    my $type = $obj->get_type;
    $logger->trace("item $loc to $mode (type $type)");

    my $e_frame = $cw->Subwidget('ed_frame');

    # cleanup existing widget contained in this frame
    delete $cw->{editor};
    map { $_->destroy if Tk::Exists($_) } $e_frame->children;

    my $widget = $widget_table{$mode}{$type}
        || die "Cannot find $mode widget for type $type";
    my @store = $mode eq 'edit' ? ( -store_cb => sub { $cw->reload(@_) } ) : ();
    $cw->{current_mode} = $mode;

    my $tk_font = $cw->cget('-font');
    $cw->{editor} = $e_frame->$widget(
        -item => $obj,
        -path => $tree_path,
        -font => $tk_font,
        @store,
    );

    $cw->{editor}->ConfigSpecs( -font => ['DESCENDANTS', 'font','Font', $tk_font ]);

    $cw->{editor}->pack( -expand => 1, -fill => 'both' );
    return $cw->{editor};
}

sub edit_copy {
    my $cw  = shift;
    my $tkt = $cw->{tktree};

    my @selected = @_ ? @_ : $tkt->info('selection');

    #print "edit_copy @selected\n";
    my @res;

    foreach my $selection (@selected) {
        my $data_ref = $tkt->infoData($selection);

        my $cfg_elt   = $data_ref->[1];
        my $type      = $cfg_elt->get_type;
        my $cfg_class = $type eq 'node' ? $cfg_elt->config_class_name : '';

        #print "edit_copy '",$cfg_elt->location, "' type '$type' class '$cfg_class'\n";

        push @res,
            [
            $cfg_elt->element_name, $cfg_elt->index_value, $cfg_elt->composite_name,
            $type,                  $cfg_class,            $cfg_elt->dump_as_data() ];
    }

    $cw->{cut_buffer} = \@res;

    #use Data::Dumper; print "cut_buffer: ", Dumper( \@res ) ,"\n";

    return \@res;    # for tests
}

sub edit_paste {
    my $cw  = shift;
    my $tkt = $cw->{tktree};

    my @selected = @_ ? @_ : $tkt->info('selection');

    return unless @selected;

    #print "edit_paste in @selected\n";
    my @res;

    my $selection = $selected[0];

    my $data_ref = $tkt->infoData($selection);

    my $cfg_elt = $data_ref->[1];

    #print "edit_paste '",$cfg_elt->location, "' type '", $cfg_elt->get_type,"'\n";
    my $t_type  = $cfg_elt->get_type;
    my $t_class = $t_type eq 'node' ? $cfg_elt->config_class_name : '';
    my $t_name  = $cfg_elt->element_name;
    my $cut_buf = $cw->{cut_buffer} || [];

    foreach my $data (@$cut_buf) {
        my ( $name, $index, $composite, $type, $cfg_class, $dump ) = @$data;

        #print "from composite name '$composite' type $type\n";
        #print "t_name '$t_name' t_type '$t_type'  class '$t_class'\n";
        if ( ( $name eq $t_name and $type eq $t_type )
            or $t_class eq $cfg_class ) {
            $cfg_elt->load_data($dump);
        }
        elsif ( ( $t_type eq 'hash' or $t_type eq 'list' ) and defined $index ) {
            $cfg_elt->fetch_with_id($index)->load_data($dump);
        }
        elsif ( $t_type eq 'hash' or $t_type eq 'list' or $t_type eq 'leaf' ) {
            $cfg_elt->load_data($dump);
        }
        else {
            $cfg_elt->grab($composite)->load_data($dump);
        }
    }

    $cw->reload() if @$cut_buf;
    $cw->create_element_widget($cw->{current_mode}, $selection);
}

sub wizard {
    my $cw = shift;

    my $wiz = $cw->setup_wizard( sub { $cw->deiconify; $cw->raise; $cw->reload; } );

    # hide main window while wizard is running
    # end_cb callback will raise the main window
    $cw->withdraw;

    $wiz->prepare_wizard();
}

sub setup_wizard {
    my $cw      = shift;
    my $end_sub = shift;

    # when wizard is run, there's no need to update editor window in
    # main widget
    my $tk_font = $cw->cget('-font');
    return $cw->ConfigModelWizard(
        -root   => $cw->{root},
        -end_cb => $end_sub,
        -font => $tk_font,
    );
}

# FIXME: need to be able to search different types.
# 2 choices
# - destroy and re-create the searcher when it's modified
# - change the searcher (TreeSearcher) to accept type modif
# For the latter: it would be better to accept a set of types instead of
# all or just one type (to implement a set of check buttons)

sub create_find_widget {
    my $cw         = shift;
    my $f          = $cw->Frame( -relief => 'ridge', -borderwidth => 1, );
    my $remove_img = $cw->Photo( -file => $icon_path . 'remove.png' );

    $f->Button(
        -image   => $remove_img,
        -command => sub { $f->packForget(); },
        -relief  => 'flat',
    )->pack( -side => 'left' );

    my $searcher = $cw->{root}->tree_searcher( type => 'all' );

    my $search = '';
    my @result;
    $f->Label( -text => 'Find: ' )->pack( -side => 'left' );
    my $e = $f->Entry(
        -textvariable => \$search,
        -validate     => 'key',

        # ditch the search results when find entry is modified.
        -validatecommand => sub { @result = (); return 1; },
    )->pack( -side => 'left' );

    $cw->Advertise( find_entry => $e );

    foreach my $direction (qw/previous next/) {
        my $s = sub { $cw->find_item( $direction, $searcher, \$search, \@result ); };
        $f->Button(
            -compound => 'left',
            -image    => $gnome_img{$direction},
            -text     => ucfirst($direction),
            -command  => $s,
            -relief   => 'flat',
        )->pack( -side => 'left' );
    }

    # bind Return (or Enter) key
    $e->bind( '<Key-Return>', sub { $cw->find_item( 'next', $searcher, \$search, \@result ); } );

    return $f;
}

sub pack_find_widget {
    my $cw = shift;
    $cw->Subwidget('find_frame')->pack( -anchor => 'w', -fill => 'x' );
    $cw->Subwidget('find_entry')->focus;
}

sub find_item {
    my ( $cw, $direction, $searcher, $search_ref, $result ) = @_;

    my $find_frame = $cw->Subwidget('find_frame');

    # search the tree, store the result
    @$result = $searcher->search($$search_ref) unless @$result;

    # and jump in the list widget any time next is hit.
    if (@$result) {
        if ( defined $cw->{old_path} and $direction eq 'next' ) {
            push @$result, shift @$result;
        }
        elsif ( defined $cw->{old_path} ) {
            unshift @$result, pop @$result;
        }
        my $path = $result->[0];
        $cw->{old_path} = $path;

        $cw->force_element_display( $cw->{root}->grab($path) );
    }
}
1;

__END__

=head1 NAME

Config::Model::TkUI - Tk GUI to edit config data through Config::Model

=head1 SYNOPSIS

 use Config::Model::TkUI;

 # init trace
 Log::Log4perl->easy_init($WARN);

 # create configuration instance
 my $model = Config::Model -> new ;
 my $inst = $model->instance (root_class_name => 'a_config_class',
                              instance_name   => 'test');
 my $root = $inst -> config_root ;

 # Tk part
 my $mw = MainWindow-> new ;
 $mw->withdraw ;
 $mw->ConfigModelUI (-root => $root) ;

 MainLoop ;

=head1 DESCRIPTION

This class provides a GUI for L<Config::Model>.

With this class, L<Config::Model> and an actual configuration
model (like L<Config::Model::Xorg>), you get a tool to
edit configuration files (e.g. C</etc/X11/xorg.conf>).

=head1 USAGE

=head2 Left side tree

=over

=item *

Click on '+' and '-' boxes to open or close content

=item *

Left-click on item to open a viewer widget.

=item *

Double-click or hit "return" on any item to open an editor widget

=item *

Use Ctrl-C to copy configuration data in an internal buffer

=item *

Use Ctrl-V to copy configuration data from the internal buffer to the
configuration tree. Beware, there's no "undo" operation.

=item *

Before saving your modifications, you can review the change list with the 
menu entry C<< File -> show unsaved changes >>. This list is cleared after 
performing a C<< File -> save >>.

=item *

Pasting cut buffer into:

=over

=item *

a leaf element will store the content of the
buffer into the element.

=item *

a list element will split the content of the
buffer with /\n/ or /,/ and push the resulting array at the 
end of the list element. 

=item *

a hash element will use the content of the cut buffer to create a new key 
in the hash element. 

=back

=back

=head2 Font size and big screens

Font type and size can be adjusted using menu: "Options -> Font" menu. This setup is saved in file
C<~/.cme/config/tkui.yml>.

=head2 Search

Hit C<Ctrl-F> or use menu C<< Edit -> Search >> to open a search widget at the bottom 
of the window.

Enter a keyword in the entry widget and click on C<Next> button.

The keyword will be searched in the configuration tree, in element name, in element value and 
in documentation.

=head2 Editor widget

The right side of the widget is either a viewer or an editor. When
clicking on store in the editor, the new data is stored in the tree
represented on the left side of TkUI. The new data will be stored in
the configuration file only when C<File->save> menu is invoked.

=head2 Wizard

A wizard can be launched either with C<< File -> Wizard >> menu entry
or with C<Run Wizard> button.

The wizard will scan the configuration tree and stop on all items
flagged as important in the model. It will also stop on all erroneous
items (mostly missing mandatory values).

=head1 Methods

=head2 save(callback)

Save modified data in configuration file. The callback function is
called only if the save was done without error. The callback is called
with C<$@> in case of failed save.

=head1 TODO

- add tabular view ?
- expand the whole tree at once
- add plug-in mechanism so that dedicated widget
  can be used for some config Class (Could be handy for
  Xorg::ServerLayout)

=head1 More information

=over

=item *

See L<Config::Model home page|https://github.com/dod38fr/config-model/wiki>

=item *

Or L<Author's blog|http://ddumont.wordpress.com> where you can find many post about L<Config::Model>.

=item *

Send a mail to Config::Model user mailing list: config-model-users at lists.sourceforge.net

=back

=head1 FEEDBACK and HELP wanted

This project needs feedback from its users. Please send your
feedbacks, comments and ideas to :

  config-mode-users at lists.sourceforge.net


This projects also needs help to improve its user interfaces:

=over

=item *

Look and feel of Perl/Tk interface can be improved

=item *

A nicer logo (maybe a penguin with a wrench...) would be welcomed

=item *

Config::Model could use a web interface

=item *

May be also an interface based on Gtk or Wx for better integration in
Desktop

=back

If you want to help, please send a mail to:

  config-mode-devel at lists.sourceforge.net

=head1 SEE ALSO

=over

=item *

L<Config::Model>, L<cme>

=item *

https://github.com/dod38fr/config-model-tkui/wiki

=item *

Config::Model mailing lists on http://sourceforge.net/mail/?group_id=155650

=back



