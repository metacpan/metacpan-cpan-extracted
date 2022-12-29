#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::LeafEditor 1.376;

use strict;
use warnings;
use Carp;
use Log::Log4perl;
use Config::Model::Tk::NoteEditor;
use Config::Model::Tk::CmeDialog;
use Path::Tiny;
use Tk::Balloon;

use base qw/Config::Model::Tk::LeafViewer/;

Construct Tk::Widget 'ConfigModelLeafEditor';

my @fbe1 = qw/-fill both -expand 1/;
my @fxe1 = qw/-fill x    -expand 1/;
my @fx   = qw/-fill x  /;

my $logger = Log::Log4perl::get_logger("Tk::LeafEditor");

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item}
        || die "LeafEditor: no -item, got ", keys %$args;
    delete $args->{-path};
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__, "no -store_cb";
    my $cme_font = delete $args->{-font};

    my $inst = $leaf->instance;
    my $vt   = $leaf->value_type;
    $logger->info("Creating leaf editor for value_type $vt");
    $cw->{value} = $leaf->fetch( check => 'no', mode => 'user' );
    $logger->info( "Creating leaf editor" );

    $cw->add_header( Edit => $leaf )->pack(@fx);

    my $vref = \$cw->{value};

    my @pack_args = @fx;
    @pack_args = @fbe1
        if $vt eq 'string'
        or $vt eq 'enum'
        or $vt eq 'reference';

    my $ed_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@pack_args);
    $ed_frame->Label( -text => 'Edit value' )->pack();

    my $balloon = $cw->Balloon( -state => 'balloon' );

    if ( $vt eq 'string' ) {
        $cw->add_string_editor($leaf, $ed_frame, $balloon);
    }
    elsif ( $vt eq 'boolean' and $leaf->write_as) {
        $cw->add_written_as_boolean_editor($leaf, $ed_frame);
    }
    elsif ( $vt eq 'boolean' ) {
        $ed_frame->Checkbutton(
            -text     => $leaf->element_name,
            -variable => $vref,
            -command  => sub { $cw->try },
        )->pack();
        $cw->add_buttons($ed_frame);
    }
    elsif ( $vt eq 'uniline' or $vt eq 'integer' ) {
        $ed_frame->Entry( -textvariable => $vref )->pack(@fx);
        $cw->add_buttons($ed_frame);
    }
    elsif ( $vt eq 'enum' or $vt eq 'reference' ) {
        my $lb = $ed_frame->Scrolled(
            'Listbox',
            -height     => 5,
            -scrollbars => 'osow',

            #-listvariable => $vref,
            #-selectmode => 'single',
        )->pack(@fbe1);
        my @choice = $leaf->get_choice;
        $lb->insert( 'end', $leaf->get_choice );
        my $idx = 0;
        if ( defined $$vref ) {
            foreach my $c (@choice) {
                $lb->selectionSet($idx) if $c eq $$vref;
                $idx++;
            }
        }
        $lb->bind( '<Button-1>', sub { $cw->try( $lb->get( $lb->curselection() ) ) } );
        $cw->add_buttons($ed_frame);

    }

    $cw->ConfigModelNoteEditor( -object => $leaf )->pack;
    $cw->add_warning( $leaf, 'edit' )->pack(@fx);
    $cw->add_info_button()->pack( @fx, qw/-anchor n/ );
    $cw->add_summary($leaf)->pack(@fx);
    $cw->add_description($leaf)->pack(@fbe1);
    my ( $help_frame, $help_widget ) = $cw->add_help( 'help on value' => '', 1 );
    $help_frame->pack(@fx);

    $cw->Advertise( value_help_widget => $help_widget );
    $cw->Advertise( value_help_frame  => $help_frame );

    $cw->set_value_help;

    $cw->ConfigSpecs(
        -font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],

        #-fill   => [ qw/SELF fill Fill both/],
        #-expand => [ qw/SELF expand Expand 1/],
        -relief      => [qw/SELF relief Relief groove/],
        -borderwidth => [qw/SELF borderwidth Borderwidth 2/],
        DEFAULT      => [qw/SELF/],
    );

    # don't call directly SUPER::Populate as it's LeafViewer's populate
    $cw->Tk::Frame::Populate($args);
}

sub add_string_editor {
    my ($cw, $leaf, $ed_frame, $balloon) = @_;

    $cw->{e_widget} = $ed_frame->Scrolled(
        'Text',
        -height     => 5,
        -scrollbars => 'ow',
    )->pack(@fbe1);
    $cw->{e_widget}->tagConfigure(qw/value -lmargin1 2 -lmargin2 2 -rmargin 2/);
    $cw->reset_value;

    my $bframe = $cw->add_buttons($ed_frame);
    $bframe->Button(
        -text    => 'Cleanup',
        -command => sub { $cw->cleanup },
    )->pack( -side => 'left' );

    my $ext_ed_b = $bframe->Button(
        -text    => 'Ext editor',
        -command => sub { $cw->exec_external_editor },
        -state   => defined $ENV{EDITOR} ? 'normal' : 'disabled',
    )->pack( -side => 'left' );

    $balloon->attach(
        $ext_ed_b,
        -msg => "Run external editor (if EDITOR environment variable is set"
    );
}

sub add_written_as_boolean_editor {
    my ($cw, $leaf, $ed_frame) = @_;

    my $vref = \$cw->{value};

    my $rb_frame = $ed_frame->Frame->pack();
    foreach my $value (@{$leaf->write_as}) {
        $rb_frame->Radiobutton(
            -text     => $value,
            -value    => $value,
            -variable => $vref,
            -command  => sub { $cw->try },
        )->pack(-side => 'left');
    }
    $cw->add_buttons($ed_frame);
}

sub cleanup {
    my ($cw) = @_;
    my $text_widget = $cw->{e_widget} || return;
    my $selected    = $text_widget->getSelected;
    my $text        = $selected || $text_widget->Contents;
    $text =~ s/^\s+//gm;
    $text =~ s/\s+$//gm;
    $text =~ s/\s+/ /g;

    if ($selected) {
        $text_widget->Insert($text);
    }
    else {
        $text_widget->Contents($text);
    }
}

sub add_buttons {
    my ( $cw, $frame ) = @_;
    my $bframe = $frame->Frame->pack();

    my $balloon = $cw->Balloon( -state => 'balloon' );

    my $reset_b = $bframe->Button(
        -text    => 'Reset',
        -command => sub { $cw->reset_value; },
    )->pack( -side => 'left' );
    $balloon->attach( $reset_b, -msg => "reset entry value from tree value" );

    my $del_label = defined $cw->{leaf}->fetch_standard ? 'Back to default' : 'Delete';
    $bframe->Button(
        -text    => $del_label,
        -command => sub { $cw->delete },
    )->pack( -side => 'left' );
    my $store_b = $bframe->Button(
        -text    => 'Store',
        -command => sub { $cw->store },
    )->pack( -side => 'right' );

    $balloon->attach( $store_b, -msg => "store entry value in config tree" );

    return $bframe;
}

# Try is invoked for enum and boolean, where the possible value are
# set in the widget. Hence the user cannot enter a wrong
# value. However there may be side effects (like warp) that trigger
# and error, hence this check.
sub try {
    my $cw = shift;
    my $v  = shift;

    if ( defined $v ) {
        $cw->{value} = $v;
    }
    else {
        my $e_w = $cw->{e_widget};

        # tk widget use a reference
        if (defined $e_w) {
            $v = $e_w->get( '1.0', 'end' );
            chomp $v;
        }
        else {
            $v = $cw->{value};
        }
    }

    $v = '' unless defined $v;

    $logger->debug("try: value $v");

    my @errors = $cw->{leaf}->check( value => $v, quiet => 1 );

    if (@errors) {
        $cw->CmeDialog(
            -title => 'Check value error',
            -text => \@errors,
        )->Show;
        $cw->reset_value;
        return;
    }
    else {
        $cw->set_value_help($v);
        return $v;
    }
}

sub delete {
    my $cw = shift;

    eval { $cw->{leaf}->clear; };

    if ($@) {
        $cw->CmeDialog(
            -title => 'Delete error',
            -text  => "$@",
        )->Show;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->reset_value;
        $cw->update_warning( $cw->{leaf} );
        $cw->{store_cb}->();
    }
}

# can be used without parameters to store value from widget into config tree
sub store {
    my $cw = shift;
    my $arg = shift;
    my $e_w = $cw->{e_widget};

    # tk widget use a reference
    my $v;
    if (defined $arg) {
        $v = $arg;
    }
    elsif (defined $e_w) {
        $v = $e_w->get( '1.0', 'end' );
        chomp $v; # Tk::Text::get always add a "\n";
    }
    else {
        $v = $cw->{value};
    }

    $v = '' unless defined $v;

    my $leaf = $cw->{leaf};

    print "Storing '$v'\n";

    eval { $leaf->store($v); };

    if ($@) {
        $cw->CmeDialog(
            -title => 'Failed to store value',
            -text => "$@",
        )->Show;
        $cw->reset_value;
    }
    elsif ($leaf->has_error) {
        $cw->CmeDialog (
            -title => 'Value error',
            -text  => "Cannot store the value:\n* ".join("\n* ",$leaf->all_errors),
        )->Show;
        $cw->reset_value;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->{store_cb}->();
        $cw->update_warning( $leaf );
    }
}

sub set_value_help {
    my $cw         = shift;
    my $v          = $cw->{value};
    my $value_help = defined $v ? $cw->{leaf}->get_help($v) : '';

    my $w = $cw->Subwidget('value_help_widget');
    my $f = $cw->Subwidget('value_help_frame');

    if ($value_help) {

        #$w->delete( '0.0', 'end' );
        #$w->insert( 'end', $value_help ) ;
        $cw->update_help( $w, $value_help );
        $f->pack(@fbe1);
    }
    else {
        $f->packForget;
    }
}

sub reset_value {
    my $cw = shift;
    $cw->{value} = $cw->{leaf}->fetch( check => 'no' );
    if ( defined $cw->{e_widget} ) {
        $cw->{e_widget}->delete( '1.0', 'end' );
        $cw->{e_widget}->insert( 'end', $cw->{value}, 'value' );
    }
    $cw->set_value_help if defined $cw->{value_help_widget};
}

sub exec_external_editor {
    my $cw = shift;

    my @pt_args;

    # ugly hack to use pod mode only for Model description parameter
    # i.e. for 'cme meta edit;
    my $leaf = $cw->{leaf};
    if ($leaf->parent->config_class_name =~ /^Itself/ and
            $leaf->element_name =~ /description/
        ) {
        # the .pod suffix let the editor use the correct mode
        @pt_args = (SUFFIX => '.pod');
    }

    my $pt = Path::Tiny->tempfile(@pt_args);

    die "Can't create Path::Tiny:$!" unless defined $pt;
    my $orig_data = $cw->{e_widget}->get( '1.0', 'end' );
    chomp $orig_data; # Tk::Text::get always add a "\n";
    $pt->spew_utf8( $orig_data );

    # See mastering Perl/Tk p382
    my $h = $cw->{ed_handle} = IO::Handle->new;
    die "IO::Handle->new failed." unless defined $h;

    my $ed = $ENV{EDITOR} . ' ' . $pt->canonpath;
    $cw->{ed_pid} = open( $h, '|-', $ed );

    if ( not defined $cw->{ed_pid} ) {
        $cw->CmeDialog(
            -title => 'External editor error',
            -text  => "'$ed' : $!",
        )->Show;
        return;
    }
    $h->autoflush(1);
    $cw->fileevent( $h, 'readable' => [ \&_read_stdout, $cw ] );

    # prevent navigation in the tree (and destruction of this widget
    # while the external editor is active). See mastering Perl/Tk p302
    $cw->grab;

    $cw->waitVariable( \$cw->{ed_done} );

    $cw->grabRelease;

    my $new_v = $pt->slurp_utf8();
    print "exec_external_editor done with '$new_v'\n";
    $cw->store($new_v);
    $cw->reset_value;
}

# also from Mastering Perl/Tk
sub _read_stdout {

    # Called when input is available for the output window.  Also checks
    # to see if the user has clicked Cancel.
    print "_read_stdout called\n";
    my ($cw) = @_;

    my $h = $cw->{ed_handle};
    die "External editor handle is udefined!\n" unless defined $h;
    my $stat;

    if ( $stat = sysread $h, $_, 4096 ) {
        print;
    }
    elsif ( $stat == 0 ) {
        print "edition done\n";
        $h->close;
        $cw->{ed_done} = 1;
    }
    else {
        die "External editor sysread error: $!";
    }
}    # end _read_stdout

sub reload {
    my $cw = shift;
    $cw->reset_value;
    $cw->update_warning( $cw->{leaf} );
}
1;
