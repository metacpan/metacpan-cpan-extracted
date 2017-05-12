package TestApp::Model::PerRequest;
use strict;
use warnings;

use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config( class => 'TestApp::Backend::SomeClass' );

1;
