#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::CmeDialog 1.373;

use strict;
use warnings;
use Carp;
use Log::Log4perl;
use base qw(Tk::DialogBox);

Construct Tk::Widget 'CmeDialog';

sub Populate {
    my($cw, $args) = @_;

    my $msg_arg = delete $args->{-text};
    my $msg = ref $msg_arg eq 'ARRAY' ? join( "\n", @$msg_arg )
        : $msg_arg;

    $cw->SUPER::Populate($args);

    my $tw = $cw->add('Scrolled', 'ROText')->pack;
    $tw->insert('end', $msg );
}

1;
