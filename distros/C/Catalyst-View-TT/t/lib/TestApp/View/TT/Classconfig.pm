package TestApp::View::TT::Classconfig;

use strict;
use base 'Catalyst::View::TT';

use TestApp::Template::Any;

__PACKAGE__->config(
    CLASS              => 'TestApp::Template::Any',
);

1;
