package TestApp::View::TT::AltContentType;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt', 
  content_type => 'text/plain',
);
