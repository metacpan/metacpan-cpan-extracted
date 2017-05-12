package FetchApp::Controller::Root;

use Moose;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'Catalyst::TraitFor::Controller::PermissionCheck';

__PACKAGE__->config(
    namespace => '',
    permissions => {
        'open'  => [ 'Guest', 'Admin' ],
        'close' => [ 'Admin' ]
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

sub permission_denied : Private {
    my ( $self, $c ) = @_;
    $c->res->body('denied');
    $c->detach;
}

# Local override
sub fetch_permissions {
    my ( $self, $c) = shift;
    return { 'Admin' => 1 };
}

1;
