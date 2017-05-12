package TestApp::View::Test;

use strict;
use warnings;

use parent 'Catalyst::View';
use JSON;

sub process {
    my ( $self, $c, $response) = @_;

    $c->response->content_type('application/json; charset=utf-8');
    $c->response->body(encode_json($response || $c->stash));
    
    return;
}

1;