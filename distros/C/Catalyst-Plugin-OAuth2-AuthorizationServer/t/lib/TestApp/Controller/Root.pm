package TestApp::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub metadata :Path('/.well-known/oauth-authorization-server') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_metadata;
}

sub register :Path('/oauth/register') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_register;
}

sub authorize :Path('/oauth/authorize') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_authorize;
}

sub token :Path('/oauth/token') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_token;
}

sub issue_code_direct :Path('/test/issue-code') :Args(0) {
    my ( $self, $c ) = @_;
    my $out = $c->oauth_issue_code( 'user-x',
        $c->request->query_parameters->{request_id} // 'nope' );
    $c->response->body('OK') if $out;
}

1;
