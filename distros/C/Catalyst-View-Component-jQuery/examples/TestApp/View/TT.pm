package TestApp::View::TT;

use Moose;
extends 'Catalyst::View::TT';
with 'Catalyst::View::Component::jQuery';

use TestApp;

__PACKAGE__->config(
    INCLUDE_PATH => [
        TestApp->path_to( 'root', 'src' )
    ],
    TEMPLATE_EXTENSION => '.tt2',
);

1;
