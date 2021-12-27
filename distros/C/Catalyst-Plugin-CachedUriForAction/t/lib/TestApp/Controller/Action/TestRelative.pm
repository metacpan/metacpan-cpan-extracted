package TestApp::Controller::Action::TestRelative;

use strict;
use base 'Catalyst::Controller';

__PACKAGE__->config(
  path => 'action/relative'
);

sub relative : Local {
}

1;
