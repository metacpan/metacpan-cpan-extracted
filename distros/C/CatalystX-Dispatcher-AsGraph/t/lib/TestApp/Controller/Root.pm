package TestApp::Controller::Root;
use parent Catalyst::Controller;

__PACKAGE__->config->{namespace} = '';

sub root : Chained('/') PathPart() CaptureArgs(0) { }

sub index : Chained('root') PathPart('') Args(0) { }

sub view : Chained('root') PathPart('view') Args(1) { }

sub view_user : Chained('root') PathPart('view/user') Args(1) { }

sub edit : Chained('root') PathPart('edit') Args(1) { }

1;
