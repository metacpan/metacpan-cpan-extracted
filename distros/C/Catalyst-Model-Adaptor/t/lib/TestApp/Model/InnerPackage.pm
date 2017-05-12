package TestApp::Model::InnerPackage;
use strict;
use warnings;

use TestApp::Backend::InnerPackage;

use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'TestApp::Backend::InnerPackage::Inner' );

1;
