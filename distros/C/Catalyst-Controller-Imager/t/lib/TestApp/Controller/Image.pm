package TestApp::Controller::Image;
use Moose;
BEGIN { extends 'Catalyst::Controller::Imager'; }

sub want_original :Action :Args(0) {
    # do nothing - no conversion is wanted...
}

1;
