package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller::HTML::FormFu';

__PACKAGE__->config->{namespace} = '';

sub end : ActionClass('RenderView') {
}

1;
