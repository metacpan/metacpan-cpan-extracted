package TestApp::Controller::Adaptor;
use strict;
use warnings;

use base 'TestApp::BaseController::Adaptor';

__PACKAGE__->config( model => 'SomeClass' );

1;
