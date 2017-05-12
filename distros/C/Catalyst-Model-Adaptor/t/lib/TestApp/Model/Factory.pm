package TestApp::Model::Factory;
use strict;
use warnings;

use base 'Catalyst::Model::Factory';

__PACKAGE__->config( class => 'TestApp::Backend::SomeClass' );

1;
