package TestApp::Controller::JsFail;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::Combine' }

use MyMinifier;

__PACKAGE__->config(
    dir => 'static/js',
    depend => {
        js2 => 'js1',
    },
);

1;
