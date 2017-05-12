#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp;
  
use Moose;  

extends 'Catalyst';

use Catalyst::Request::REST::ForBrowsers;

__PACKAGE__->config(
    'default_view' => 'TT'
);

__PACKAGE__->setup();
__PACKAGE__->log->disable('error');


1;