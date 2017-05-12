package TestApp::Controller::Js;

use Moose;
BEGIN { extends 'Catalyst::Controller::Combine' }

__PACKAGE__->config(
    depend => {
        js2 => 'js1',
    },
);

sub call_uri :Global('/call_uri') {
    my $self = shift;
    my $c = shift;
    $c->res->output('' . $c->uri_for($c->controller('Js')->action_for('default'), 'js1.js'));
}

1;
