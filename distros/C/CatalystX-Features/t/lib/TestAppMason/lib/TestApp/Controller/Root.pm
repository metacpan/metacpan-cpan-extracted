package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub end : ActionClass('RenderView') {}

1;
