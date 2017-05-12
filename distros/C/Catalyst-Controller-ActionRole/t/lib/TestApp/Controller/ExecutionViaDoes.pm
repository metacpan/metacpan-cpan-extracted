package TestApp::Controller::ExecutionViaDoes;

use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

sub one  : Local Does('First') {}
sub two  : Local Does('First') Does('Second') {}

1;
