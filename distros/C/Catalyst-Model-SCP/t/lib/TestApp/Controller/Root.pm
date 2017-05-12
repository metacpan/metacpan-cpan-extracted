package TestApp::Controller::Root;
use base 'Catalyst::Controller';

use strict;
use warnings;

__PACKAGE__->config->{namespace} = '';

sub index : Private {
    my ( $self, $c ) = @_;
    my $scp_client = $c->model('MYSCP');
    $c->res->body('root index');
}

sub end : Private {
    my ( $self, $c ) = @_;
    return if $c->res->body;    # already have a response
}

1;