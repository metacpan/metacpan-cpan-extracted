#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::HashViewer 1.372;

use strict;
use warnings;
use Carp;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/;

Construct Tk::Widget 'ConfigModelHashViewer';

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
    my $hash = $cw->{hash} = delete $args->{-item}
        || die "HashViewer: no -item, got ", keys %$args;
    my $path = delete $args->{-path}
        || die "HashViewer: no -path, got ", keys %$args;
    my $cme_font = delete $args->{-font};

    $cw->add_header( View => $hash )->pack(@fx);

    my $inst = $hash->instance;

    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fbe1);
    my $str       = $hash->element_name . ' ' . $hash->get_type . ' elements';
    $elt_frame->Label( -text => $str )->pack();

    my $rt = $elt_frame->Scrolled(
        'ROText',
        -scrollbars => 'oe',
        -height     => 10,
    )->pack(@fbe1);

    foreach my $c ( $hash->fetch_all_indexes ) {
        $rt->insert( 'end', $c . "\n" );
    }

    $cw->add_annotation($hash)->pack(@fx);
    $cw->add_warning( $hash, 'view' )->pack(@fx);
    $cw->add_summary($hash)->pack(@fx);
    $cw->add_description($hash)->pack(@fbe1);

    $cw->add_info_button()->pack( -side => 'left', @fxe1 );
    $cw->add_editor_button($path)->pack( -side => 'right', @fxe1 );

    $cw->ConfigSpecs(-font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],);

    $cw->SUPER::Populate($args);
}

sub cme_object {
    my $cw = shift;
    return $cw->{hash};
}

1;
