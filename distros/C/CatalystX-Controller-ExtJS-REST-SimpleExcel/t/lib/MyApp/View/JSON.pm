#
# This file is part of CatalystX-Controller-ExtJS-REST-SimpleExcel
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

__PACKAGE__->config( expose_stash => 'json', encoding => 'utf-8' );

1;

