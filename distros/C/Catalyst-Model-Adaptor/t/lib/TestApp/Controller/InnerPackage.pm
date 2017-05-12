package TestApp::Controller::InnerPackage;
use strict;
use warnings;

use base 'TestApp::BaseController::Adaptor';

__PACKAGE__->config( model => 'InnerPackage' );

1;
