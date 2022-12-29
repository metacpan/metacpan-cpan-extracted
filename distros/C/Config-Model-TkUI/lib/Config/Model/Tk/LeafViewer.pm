#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::LeafViewer 1.376;

use strict;
use warnings;
use 5.10.1;
use Carp;
use Log::Log4perl;
use Text::Diff;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;

Construct Tk::Widget 'ConfigModelLeafViewer';

my @fbe1 = qw/-fill both -expand 1/;
my @fxe1 = qw/-fill x    -expand 1/;
my @fx   = qw/-fill x  /;

my $logger = Log::Log4perl::get_logger("Tk::LeafViewer");

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item}
        || die "LeafViewer: no -item, got ", keys %$args;
    my $path = delete $args->{-path}
        || die "LeafViewer: no -path, got ", keys %$args;
    my $cme_font = delete $args->{-font};

    my $inst = $leaf->instance;

    my $vt = $leaf->value_type;
    $logger->info("Creating leaf viewer for value_type $vt");
    my $v = $leaf->fetch( check => 'no' );

    $cw->add_header( View => $leaf )->pack(@fx);

    my @pack_args = @fx;
    @pack_args = @fbe1 if $vt eq 'string';
    my $lv_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@pack_args);
    $lv_frame->Label( -text => 'Value' )->pack();

    if ( $vt eq 'string') {
        require Tk::ROText;
        $cw->{e_widget} = $lv_frame->Scrolled(
            'ROText',
            -height     => 5,
            -scrollbars => 'ow',
        )->pack(@fbe1);
        $cw->{e_widget}->insert( 'end', $v, 'value' );
        $cw->{e_widget}->tagConfigure(qw/value -lmargin1 2 -lmargin2 2 -rmargin 2/);

        my $std = $cw->{leaf}->fetch_standard ;
        if ($std) {
            $lv_frame->Label( -text => 'Diff compared to standard value' )->pack();
            $cw->{diff_widget} = $lv_frame->Scrolled(
                'ROText',
                -height     => 5,
                -scrollbars => 'ow',
            )->pack(@fbe1);

            # Text::Diff does not handle well files without trailing \n
            $std .= "\n" unless $std =~ /\n$/;
            my $new = $v // '';
            $new .= "\n" unless $new =~ /\n$/;

            my $diff = diff( \$std, \$new , { STYLE => "Unified" } );
            $cw->{diff_widget}->insert( 'end', $diff, 'value' );
            $cw->{diff_widget}->tagConfigure(qw/value -lmargin1 2 -lmargin2 2 -rmargin 2/);
        }
    }
    else {
        my $v_frame = $lv_frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1);
        $v_frame->Label( -text => $v, -anchor => 'w' )->pack( @fxe1, -side => 'left' );
    }

    $cw->add_annotation($leaf)->pack(@fx);
    $cw->add_summary($leaf)->pack(@fx);
    $cw->add_description($leaf)->pack(@fbe1);
    $cw->add_warning( $leaf, 'view' )->pack(@fx);
    $cw->add_help( 'value help' => $leaf->get_help( $cw->{value} ) )->pack(@fx);
    $cw->add_info_button()->pack( @fxe1, -side => 'left', -anchor => 'n' );
    $cw->add_editor_button($path)->pack( @fxe1, -side => 'right', -anchor => 'n' );

    $cw->ConfigSpecs(
        -font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],
        #-fill   => [ qw/SELF fill Fill both/],
        #-expand => [ qw/SELF expand Expand 1/],
        -relief      => [qw/SELF relief Relief groove/],
        -borderwidth => [qw/SELF borderwidth Borderwidth 2/],
        DEFAULT      => [qw/SELF/],
    );

    $cw->SUPER::Populate($args);
}

sub cme_object {
    my $cw = shift;
    return $cw->{leaf};
}

1;
