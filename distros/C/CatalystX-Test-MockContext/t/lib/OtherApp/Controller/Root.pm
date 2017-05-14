package OtherApp::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub foo :Chained('/') Args(0) {
  pop->res->body('foo');
}

1;
