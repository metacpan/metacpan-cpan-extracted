package TestApp::Model::SomeClass;
use strict;
use warnings;

use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'TestApp::Backend::SomeClass' );

1;
