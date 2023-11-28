#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::NodeViewer 1.377;

use strict;
use warnings;
use Carp;
use 5.10.1;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/;

Construct Tk::Widget 'ConfigModelNodeViewer';

my @fbe1 = qw/-fill both -expand 1/;
my @fxe1 = qw/-fill x    -expand 1/;
my @fx   = qw/-fill    x /;

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;
    my $node = $cw->{node} = delete $args->{-item}
        || die "NodeViewer: no -item, got ", keys %$args;
    my $path = delete $args->{-path};
    my $cme_font = delete $args->{-font};

    $cw->add_header( View => $node )->pack(@fx);

    my $inst = $node->instance;

    my $elt_frame = $cw->Frame(qw/-relief flat/)->pack(@fbe1);

    $elt_frame->Label( -text => $node->composite_name_short . ' node elements' )->pack();

    my $hl = $elt_frame->Scrolled(
        'HList',
        -scrollbars => 'osow',
        -columns    => 3,
        -header     => 1,
        -height     => 8,
    )->pack(@fbe1);
    $hl->headerCreate( 0, -text => 'name' );
    $hl->headerCreate( 1, -text => 'type' );
    $hl->headerCreate( 2, -text => 'value' );
    $cw->{hlist} = $hl;
    $cw->reload;

    # add adjuster. Buggy behavior on destroy...
    #require Tk::Adjuster;
    #$cw->{adjust} = $cw -> Adjuster();
    #$cw->{adjust}->packAfter($hl, -side => 'top') ;

    $cw->add_annotation($node)->pack(@fx);

    if ( $node->parent ) {
        $cw->add_summary($node)->pack(@fx);
        $cw->add_description($node)->pack(@fbe1);
    }
    else {
        $cw->add_help( class => $node->get_help )->pack(@fx);
    }

    $cw->add_info_button()->pack( @fxe1, -side => 'left' );
    $cw->add_editor_button($path)->pack( @fxe1, -side => 'right' );

    $cw->ConfigSpecs(-font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],);

    $cw->SUPER::Populate($args);
}

#sub DESTROY {
#    my $cw = shift ;
#    $cw->{adjust}->packForget(1);
#}

sub reload {
    my $cw = shift;

    my $node = $cw->{node};
    my $hl   = $cw->{hlist};

    my %old_elt = %{ $cw->{elt_path} || {} };

    foreach my $elt_name ( $node->get_element_name() ) {
        my $hl_name = $elt_name;
        $hl_name =~ s/\./__/g; # make elt name compatible with Tk::HList

        my $type = $node->element_type($elt_name);

        unless ( delete $old_elt{$hl_name} ) {
            # create item
            $hl->add($hl_name);
            $cw->{elt_path}{$hl_name} = 1;

            $hl->itemCreate( $hl_name, 0, -text => $elt_name );
            $hl->itemCreate( $hl_name, 1, -text => $type );
            $hl->itemCreate(
                $hl_name, 2,
                -itemtype  => 'imagetext',
                -text      => '',
                -showimage => 0,
                -image     => $Config::Model::TkUI::warn_img
            );
        }

        if ( $type eq 'leaf' ) {

            # update displayed value
            my $v = eval { $node->fetch_element_value($elt_name) };
            if ($@) {
                $hl->itemConfigure(
                    $hl_name, 2,
                    -showtext  => 0,
                    -showimage => 1,
                );
            }
            elsif ( defined $v ) {
                substr( $v, 15 ) = '...' if length($v) > 15;
                $hl->itemConfigure(
                    $hl_name, 2,
                    -showtext  => 1,
                    -showimage => 0,
                    -text      => $v
                );
            }
        }
    }

    # destroy leftover widgets (may occur with warp mechanism)
    map { $hl->delete( entry => $_ ); } keys %old_elt;
}

sub cme_object {
    my $cw = shift;
    return $cw->{node};
}

1;
