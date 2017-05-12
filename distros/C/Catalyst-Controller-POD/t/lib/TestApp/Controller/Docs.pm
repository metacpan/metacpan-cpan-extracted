#
# This file is part of Catalyst-Controller-POD
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package TestApp::Controller::Docs;

use strict;
use warnings;
use base 'Catalyst::Controller::POD';


sub test : Local {
    my ( $self, $c ) = @_;

    $c->response->body( "here I am" );
}


1;
