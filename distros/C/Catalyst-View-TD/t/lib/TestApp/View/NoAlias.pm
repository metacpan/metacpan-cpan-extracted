package TestApp::View::NoAlias;

use strict;
use base 'Catalyst::View::TD';

__PACKAGE__->config( auto_alias => 0 );

1;
