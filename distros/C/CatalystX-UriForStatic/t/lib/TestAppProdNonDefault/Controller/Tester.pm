package TestAppProdNonDefault::Controller::Tester;
our $VERSION = '0.01';

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub get_static_uri : Local {
    my ($self, $c) = @_;
    $c->response->body($c->uri_for_static('/static/foo.png'));
}

1;