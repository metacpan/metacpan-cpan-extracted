#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config( {
        CATALYST_VAR => 'Catalyst',
        INCLUDE_PATH => [ MyApp->path_to( '..', '..', 'root', 'src' ) ],
        WRAPPER      => 'wrapper',
        TIMER        => 0,
    } );


1;

