package TestApp::Controller::ExecutionViaConfig;

use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_roles => ['Shared']
);

sub two  : Local Does('First') {}
sub three  : Local Does('First') Does('Second') {}

1;
