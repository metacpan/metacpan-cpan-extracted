package MyApp::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub root :Chained('/') PathPart('') Args(0) {
  pop->res->body('root');
}

1;
