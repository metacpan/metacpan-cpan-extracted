#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::ListViewer 1.377;

use strict;
use warnings;
use Carp;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/;

Construct Tk::Widget 'ConfigModelListViewer';

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
    my $list = $cw->{list} = delete $args->{-item}
        || die "ListViewer: no -item, got ", keys %$args;
    my $path = delete $args->{-path}
        || die "ListViewer: no -path, got ", keys %$args;
    my $cme_font = delete $args->{-font};

    $cw->add_header( View => $list )->pack(@fx);

    my $inst = $list->instance;

    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fbe1);
    my $str       = $list->element_name . ' ' . $list->get_type . ' elements';
    $elt_frame->Label( -text => $str )->pack();

    my $rt = $elt_frame->Scrolled( 'ROText', -height => 10, )->pack(@fbe1);

    my @insert =
          $list->cargo_type eq 'leaf'
        ? $list->fetch_all_values( check => 'no' )
        : $list->fetch_all_indexes;
    foreach my $c (@insert) {
        my $line = defined $c ? $c : '<undef>';
        $rt->insert( 'end', $line . "\n" );
    }

    $cw->add_annotation($list)->pack(@fx);
    $cw->add_warning( $list, 'view' )->pack(@fx);
    $cw->add_summary($list)->pack(@fx);
    $cw->add_description($list)->pack(@fbe1);

    $cw->add_info_button()->pack( -side => 'left', @fxe1 );
    $cw->add_editor_button($path)->pack( -side => 'right', @fxe1 );

    $cw->ConfigSpecs(-font => [['SELF','DESCENDANTS'], 'font','Font', $cme_font ],);

    $cw->SUPER::Populate($args);
}

sub cme_object {
    my $cw         = shift;
    return $cw->{list};
}

1;
