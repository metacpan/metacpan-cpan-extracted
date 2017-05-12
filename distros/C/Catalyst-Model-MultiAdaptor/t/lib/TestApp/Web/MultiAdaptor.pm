package TestApp::Web::Controller::MultiAdaptor;
use strict;
use warnings;

use base 'TestApp::Web::BaseController::MultiAdaptor';

__PACKAGE__->config( model => 'Service::SomeClass' );

1;
