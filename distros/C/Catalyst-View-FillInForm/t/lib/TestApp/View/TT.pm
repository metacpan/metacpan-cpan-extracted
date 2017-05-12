package # Hide from PAUSE
    TestApp::View::TT;

use Moose;
extends 'Catalyst::View::TT';
with 'Catalyst::View::FillInForm';

1;
