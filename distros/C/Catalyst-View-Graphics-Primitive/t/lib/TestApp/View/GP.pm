package TestApp::View::GP;

use strict;
use base 'Catalyst::View::Graphics::Primitive';

__PACKAGE__->config(
    content_type => 'image/png'
);

1;
