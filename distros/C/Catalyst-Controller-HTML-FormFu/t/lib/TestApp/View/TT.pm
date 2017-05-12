package TestApp::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config( INCLUDE_PATH => [ TestApp->path_to('root') ], );

1;
