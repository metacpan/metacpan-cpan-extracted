package OpenApp::Controller::Root;

use Moose;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'Catalyst::TraitFor::Controller::PermissionCheck';

__PACKAGE__->config(
    namespace => '',
    permissions => {
        'close' => [ 'Admin' ]
    },
    allow_by_default => 1
);

sub index : Path('') {
    my ( $self, $c ) = @_;

    $c->res->body('index');
}

sub setup : Chained('/') PathPart('') CaptureArgs(0) { 
    my ( $self, $c ) = @_;
    if ( $c->req->params->{permissions} ) {

    } else {
        $c->stash->{context}->{permissions} = {  }
    }
}

sub open : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body('open');
}

sub close : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body('close');
}

sub permission_denied : Private {
    my ( $self, $c ) = @_;
    $c->res->body('denied');
    $c->detach;
}

1;
