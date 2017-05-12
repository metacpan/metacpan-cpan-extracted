package TestApp::Controller::Root;

use Moose;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'Catalyst::TraitFor::Controller::PermissionCheck';

__PACKAGE__->config(
    namespace => '',
    permissions => {
        'open'        => [ 'Guest' ],
        'close'       => [ 'Admin' ],
        'submit_POST' => [ 'Guest' ]
    },
    allow_by_default => 0
);

sub index : Path('') {
    my ( $self, $c ) = @_;

    $c->res->body('index');
}

sub setup : Chained('/') PathPart('') CaptureArgs(0) { 
    my ( $self, $c ) = @_;
    if ( $c->req->params->{permissions} ) {

    } else {
        $c->stash->{context}->{permissions} = { 'Guest' => 1 }
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

sub submit : Chained('setup') Args(0) {
    my ($self, $c) = @_;
    my $return = 'submit';
    if($c->req->method eq 'POST') {
        my $data = $c->req->params;
        $return = $data->{'return_value'} || 'default post submission';
    }
    $c->res->body($return);
}

sub permission_denied : Private {
    my ( $self, $c ) = @_;
    $c->res->body('denied');
    $c->detach;
}

1;
